{
  config,
  lib,
  ...
}:

let
  inherit (lib)
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.programs.spotify;
in
{
  options.programs.spotify = {
    enable = mkEnableOption "Spotify (native Chromium app + Widevine via nix-spotify)";

    package = mkOption {
      type = types.nullOr types.package;
      default = null;
      defaultText = literalExpression "nix-spotify.packages.\${pkgs.stdenv.hostPlatform.system}.spotify";
      example = literalExpression "nix-spotify.packages.\${pkgs.stdenv.hostPlatform.system}.spotify";
      description = ''
        spotify package to install. When you import
        `nix-spotify.homeModules.spotify` from the flake, this defaults
        to that flake's `spotify` — you usually do not need to set it.
      '';
    };

    location = mkOption {
      type = types.str;
      default = "${config.xdg.dataHome}/nix-spotify";
      defaultText = literalExpression "\${config.xdg.dataHome}/nix-spotify";
      description = "Mutable Chromium profile directory for the Spotify app window.";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--force-device-scale-factor=1.25" ];
      description = "Extra arguments passed to Chromium before `--app`.";
    };
  };

  config = mkIf cfg.enable (
    let
      finalPackage =
        if cfg.package == null then
          null
        else
          cfg.package.override {
            location = cfg.location;
            extraArgs = cfg.extraArgs;
          };
    in
    {
      home.packages = lib.optional (finalPackage != null) finalPackage;

      assertions = [
        {
          assertion = cfg.package != null;
          message = ''
            programs.spotify.package is unset. Import nix-spotify.homeModules.spotify
            from the flake (which sets a default), or set package explicitly to
            nix-spotify.packages.''${pkgs.stdenv.hostPlatform.system}.spotify.
          '';
        }
      ];
    }
  );
}
