{
  lib,
  chromium,
  coreutils,
  fetchurl,
  makeDesktopItem,
  python3,
  squashfs-tools,
  stdenvNoCC,
  symlinkJoin,
  writeShellApplication,
  pname ? "nix-spotify-aarch64",
  location ? "$HOME/.local/share/nix-spotify-aarch64",
  extraArgs ? [ ],
}:

let
  inherit (lib)
    escapeShellArg
    escapeShellArgs
    getExe
    ;

  chromiumWV = chromium.override {
    enableWideVine = true;
  };

  # Official client icons from the same snap nixpkgs uses. Only the PNG
  # icons are kept; the x86_64 binary is discarded.
  icons = stdenvNoCC.mkDerivation {
    name = "spotify-client-icons";
    src = fetchurl {
      name = "spotify-1.2.92.147.g5b8f9367-97.snap";
      url = "https://api.snapcraft.io/api/v1/snaps/download/pOBIoZ2LrCB3rDohMxoYGnbN14EHOgD7_97.snap";
      hash = "sha512-Gk0/WjfgJZIG+2w4teaznAk/7evOXUsuCikDvOhmhAQ5ksQV99VeiYnE+OJf7hHnrPaHoueERvIkk7Psed/kwA==";
    };
    nativeBuildInputs = [ squashfs-tools ];
    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      unsquashfs -q "$src" '/usr/share/spotify/icons'
      for i in 16 22 24 32 48 64 128 256 512; do
        install -Dm644 squashfs-root/usr/share/spotify/icons/spotify-linux-$i.png \
          "$out/share/icons/hicolor/''${i}x''${i}/apps/spotify-client.png"
        ln -s spotify-client.png "$out/share/icons/hicolor/''${i}x''${i}/apps/spotify.png"
      done
      runHook postInstall
    '';
    meta = {
      description = "Official Spotify desktop icons";
      license = lib.licenses.unfree;
      platforms = [ "aarch64-linux" ];
    };
  };

  script = writeShellApplication {
    name = "spotify";
    runtimeInputs = [
      coreutils
      chromiumWV
      python3
    ];
    text = ''
      set -euo pipefail

      LOCATION="''${LOCATION:-${location}}"
      LOCATION="''${LOCATION/#\~/$HOME}"
      DATA_DIR="$LOCATION/chromium"
      DEFAULT_DIR="$DATA_DIR/Default"
      MIGRATE_MARKER="$LOCATION/.os-crypt-basic-v2"

      mkdir -p "$DEFAULT_DIR"

      # Plasma / Chromium app windows on Wayland.
      export NIXOS_OZONE_WL="''${NIXOS_OZONE_WL:-1}"

      # Chromium 120+ prefers the FreeDesktop Secret Portal for cookie
      # encryption even with --password-store=basic. On Plasma that keys
      # cookies via KWallet; the key often fails to round-trip across
      # relaunches, so Spotify asks for login again. Disable the portal
      # features and keep encryption in-profile with the basic store.
      #
      # Also force "continue where you left off" so Spotify's session
      # cookies (sp_dc / sp_key) survive a clean window close.
      python3 - "$DATA_DIR" "$DEFAULT_DIR" "$MIGRATE_MARKER" <<'PY'
      import json
      import sys
      from pathlib import Path

      data_dir = Path(sys.argv[1])
      default_dir = Path(sys.argv[2])
      marker = Path(sys.argv[3])

      def load_json(path: Path) -> dict:
          if not path.is_file():
              return {}
          try:
              return json.loads(path.read_text())
          except (json.JSONDecodeError, OSError):
              return {}

      def write_json(path: Path, payload: dict) -> None:
          path.parent.mkdir(parents=True, exist_ok=True)
          path.write_text(json.dumps(payload, separators=(",", ":")))

      # One-shot: drop cookies encrypted under the Secret Portal backend.
      if not marker.is_file():
          for name in (
              "Cookies",
              "Cookies-journal",
              "Login Data",
              "Login Data-journal",
              "Login Data For Account",
              "Login Data For Account-journal",
          ):
              try:
                  (default_dir / name).unlink(missing_ok=True)
              except OSError:
                  pass
          network = default_dir / "Network"
          for name in ("Cookies", "Cookies-journal"):
              try:
                  (network / name).unlink(missing_ok=True)
              except OSError:
                  pass
          local_state_path = data_dir / "Local State"
          local_state = load_json(local_state_path)
          if "os_crypt" in local_state:
              local_state.pop("os_crypt", None)
              write_json(local_state_path, local_state)
          marker.parent.mkdir(parents=True, exist_ok=True)
          marker.write_text("basic+no-dbus-secret-portal\n")

      prefs_path = default_dir / "Preferences"
      prefs = load_json(prefs_path)
      prefs.setdefault("session", {})["restore_on_startup"] = 1
      prefs.setdefault("profile", {})["exit_type"] = "Normal"
      write_json(prefs_path, prefs)
      PY

      extra_args=( ${escapeShellArgs extraArgs} )

      exec ${escapeShellArg (getExe chromiumWV)} \
        --user-data-dir="$DATA_DIR" \
        --password-store=basic \
        --class=spotify \
        --name=Spotify \
        --no-first-run \
        --no-default-browser-check \
        --disable-sync \
        --disable-features=TranslateUI,DbusSecretPortal,SecretPortalKeyProviderUseForEncryption \
        --hide-crash-restore-bubble \
        "''${extra_args[@]}" \
        --app=https://open.spotify.com \
        "$@"
    '';
  };

  desktopItem = makeDesktopItem {
    name = "spotify";
    exec = "${script}/bin/spotify %U";
    icon = "spotify-client";
    comment = "Play music from Spotify";
    desktopName = "Spotify";
    genericName = "Music Player";
    categories = [
      "Audio"
      "Music"
      "Player"
      "AudioVideo"
    ];
    mimeTypes = [ "x-scheme-handler/spotify" ];
    startupNotify = true;
    # Chromium --app=https://open.spotify.com
    startupWMClass = "chrome-open.spotify.com__-Default";
    keywords = [
      "music"
      "spotify"
      "streaming"
    ];
  };
in
symlinkJoin {
  name = pname;
  paths = [
    script
    desktopItem
    icons
  ];
  passthru = {
    inherit chromiumWV icons;
  };
  meta = {
    description = "Spotify desktop app for aarch64 (Chromium + Widevine web player)";
    homepage = "https://github.com/gaavin/nix-spotify-aarch64";
    license = lib.licenses.unfree;
    platforms = [ "aarch64-linux" ];
    mainProgram = "spotify";
  };
}
