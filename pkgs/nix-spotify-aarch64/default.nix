{
  lib,
  chromium,
  coreutils,
  makeDesktopItem,
  runCommand,
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

      exec ${escapeShellArg (getExe chromiumWV)} \
        --user-data-dir="$DATA_DIR" \
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
    icon = "nix-spotify-aarch64";
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

  iconShare = runCommand "nix-spotify-aarch64-icon" { } ''
    install -Dm644 ${../../assets/nix-spotify-aarch64.svg} \
      "$out/share/icons/hicolor/scalable/apps/nix-spotify-aarch64.svg"
  '';
in
symlinkJoin {
  name = pname;
  paths = [
    script
    desktopItem
    iconShare
  ];
  passthru = {
    inherit chromiumWV;
  };
  meta = {
    description = "Spotify desktop app for aarch64 (Chromium + Widevine web player)";
    homepage = "https://github.com/gaavin/nix-spotify-aarch64";
    license = lib.licenses.unfree;
    platforms = [ "aarch64-linux" ];
    mainProgram = "spotify";
  };
}
