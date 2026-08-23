{
  lib,
  chromium,
  coreutils,
  makeDesktopItem,
  runCommand,
  symlinkJoin,
  writeShellApplication,
  pname ? "spotify",
  location ? "$HOME/.local/share/nix-spotify",
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
    name = pname;
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
    name = pname;
    exec = "${script}/bin/${pname} %U";
    icon = "nix-spotify";
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

  iconShare = runCommand "nix-spotify-icon" { } ''
    install -Dm644 ${../../assets/nix-spotify.svg} \
      "$out/share/icons/hicolor/scalable/apps/nix-spotify.svg"
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
    description = "Spotify desktop app (Chromium + Widevine web player)";
    homepage = "https://github.com/gaavin/nix-spotify";
    license = lib.licenses.unfree;
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
    ];
    mainProgram = pname;
  };
}
