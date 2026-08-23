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

  cfg = config.programs.nix-spotify-aarch64;
in
{
  options.programs.nix-spotify-aarch64 = {
    enable = mkEnableOption "Spotify on aarch64 (native Chromium app + Widevine via nix-spotify-aarch64)";

    package = mkOption {
      type = types.nullOr types.package;
      default = null;
      defaultText = literalExpression "nix-spotify-aarch64.packages.\${pkgs.stdenv.hostPlatform.system}.nix-spotify-aarch64";
      example = literalExpression "nix-spotify-aarch64.packages.\${pkgs.stdenv.hostPlatform.system}.nix-spotify-aarch64";
      description = ''
        nix-spotify-aarch64 package to install. When you import
        `nix-spotify-aarch64.homeModules.nix-spotify-aarch64` from the flake,
        this defaults to that flake's `nix-spotify-aarch64` — you usually
        do not need to set it.
      '';
    };

    location = mkOption {
      type = types.str;
      default = "${config.xdg.dataHome}/nix-spotify-aarch64";
      defaultText = literalExpression "\${config.xdg.dataHome}/nix-spotify-aarch64";
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
            programs.nix-spotify-aarch64.package is unset. Import
            nix-spotify-aarch64.homeModules.nix-spotify-aarch64 from the flake
            (which sets a default), or set package explicitly to
            nix-spotify-aarch64.packages.''${pkgs.stdenv.hostPlatform.system}.nix-spotify-aarch64.
          '';
        }
      ];
    }
  );
}
