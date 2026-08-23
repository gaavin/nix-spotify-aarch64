{
  lib,
  chromium,
  coreutils,
  fetchurl,
  makeDesktopItem,
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
    ];
    text = ''
      set -euo pipefail

      LOCATION="''${LOCATION:-${location}}"
      LOCATION="''${LOCATION/#\~/$HOME}"
      DATA_DIR="$LOCATION/chromium"

      mkdir -p "$DATA_DIR"

      # Plasma / Chromium app windows on Wayland.
      export NIXOS_OZONE_WL="''${NIXOS_OZONE_WL:-1}"

      extra_args=( ${escapeShellArgs extraArgs} )

      # Keep cookie encryption in this profile; KWallet autodetect drops login on restart.
      exec ${escapeShellArg (getExe chromiumWV)} \
        --user-data-dir="$DATA_DIR" \
        --password-store=basic \
        --class=spotify \
        --name=Spotify \
        --no-first-run \
        --no-default-browser-check \
        --disable-sync \
        --disable-features=TranslateUI \
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
