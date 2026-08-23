{
  description = "Declarative Spotify on Nix (native Chromium app + Widevine, including aarch64)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs [
        "aarch64-linux"
        "x86_64-linux"
      ];
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          spotify = pkgs.callPackage ./pkgs/spotify { };
        in
        {
          inherit spotify;
          default = spotify;
        }
      );

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.spotify}/bin/spotify";
        };
      });

      homeModules.spotify =
        { lib, pkgs, ... }:
        {
          imports = [ ./modules/home-manager/spotify.nix ];
          programs.spotify.package = lib.mkDefault (
            self.packages.${pkgs.stdenv.hostPlatform.system}.spotify
          );
        };
      homeModules.default = self.homeModules.spotify;

      overlays.default = final: _prev: {
        inherit (self.packages.${final.stdenv.hostPlatform.system}) spotify;
      };
    };
}
