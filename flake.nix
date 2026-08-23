{
  description = "Declarative Spotify on aarch64 Nix (native Chromium app + Widevine)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      system = "aarch64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      packages = rec {
        nix-spotify-aarch64 = pkgs.callPackage ./pkgs/nix-spotify-aarch64 { };
        default = nix-spotify-aarch64;
      };
    in
    {
      packages.${system} = packages;

      apps.${system}.default = {
        type = "app";
        program = "${packages.nix-spotify-aarch64}/bin/spotify";
      };

      homeModules.nix-spotify-aarch64 =
        { lib, pkgs, ... }:
        {
          imports = [ ./modules/home-manager/nix-spotify-aarch64.nix ];
          programs.nix-spotify-aarch64.package = lib.mkDefault (
            self.packages.${pkgs.stdenv.hostPlatform.system}.nix-spotify-aarch64
          );
        };
      homeModules.default = self.homeModules.nix-spotify-aarch64;

      overlays.default = final: _prev: {
        inherit (self.packages.${final.stdenv.hostPlatform.system} or packages) nix-spotify-aarch64;
      };
    };
}
