<div align="center">

# nix-spotify

**Spotify on NixOS** — including `aarch64-linux`. Native Chromium app window plus Widevine. Not FEX, Box64, or muvm.

[![NixOS](https://img.shields.io/badge/NixOS-unstable-informational?logo=NixOS)](https://nixos.org)
[![Flake](https://img.shields.io/badge/Flake-enabled-success)](https://nixos.wiki/wiki/Flakes)

</div>

> [!WARNING]
> **This project was primarily written by an LLM (AI). Review the code yourself before running it. Use at your own risk.**

Spotify does not ship an ARM64 Linux desktop client. nixpkgs `spotify` is `x86_64-linux` (and Darwin) only. This flake wraps the official web player in Chromium with [Widevine](https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/wi/widevine-cdm/aarch64-linux.nix) (Asahi 16K page fixup included upstream) so playback works on Apple Silicon NixOS without emulating x86.

## Quick Start

```bash
nix run github:gaavin/nix-spotify
```

Requires `aarch64-linux` or `x86_64-linux`, flakes, and unfree packages (Widevine + Spotify).

## Install with Home Manager

### 1. Add to flake inputs

```nix
{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-spotify.url = "github:gaavin/nix-spotify";
    nix-spotify.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, nix-spotify, ... }:
    {
      nixosConfigurations.YOUR_CONFIGURATION = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit nix-spotify; };
              users.YOUR_USERNAME = import ./home.nix;
              sharedModules = [
                nix-spotify.homeModules.spotify
              ];
            };
          }
        ];
      };
    };
}
```

### 2. Enable in `home.nix`

```nix
{
  programs.spotify.enable = true;
}
```

### 3. Build & launch

```bash
nix flake update nix-spotify
sudo nixos-rebuild switch --flake .#YOUR_CONFIGURATION
spotify
```

Sign in inside the app window. Profile data lives under `~/.local/share/nix-spotify/chromium`.

## Commands

| Command | Purpose |
|---------|---------|
| `spotify` | Launch the app window |

## Paths

```
~/.local/share/nix-spotify/
  chromium/     Chromium user-data (login, cache)
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No sound / "Spotify can't play this" | Widevine must load; this package sets `chromium.override { enableWideVine = true; }`. Rebuild with `allowUnfree`. |
| Window looks like a browser tab | Launch via the `spotify` wrapper (`--app=https://open.spotify.com`), not Chromium itself. |
| Scale is wrong | `programs.spotify.extraArgs = [ "--force-device-scale-factor=1.25" ];` |
| Start fresh | Remove `~/.local/share/nix-spotify/` |

## Advanced

Package only:

```nix
home.packages = [
  inputs.nix-spotify.packages.${pkgs.stdenv.hostPlatform.system}.spotify
];
```

Overrides:

```nix
inputs.nix-spotify.packages.${pkgs.stdenv.hostPlatform.system}.spotify.override {
  location = "$HOME/.local/share/nix-spotify";
  extraArgs = [ "--force-device-scale-factor=1.25" ];
}
```

```bash
nix build github:gaavin/nix-spotify#spotify
```

## Credits

- [NixOS/nixpkgs `widevine-cdm`](https://github.com/NixOS/nixpkgs/tree/nixos-unstable/pkgs/by-name/wi/widevine-cdm) — aarch64 CDM + Asahi `widevine_fixup.py`
- [AsahiLinux/widevine-installer](https://github.com/AsahiLinux/widevine-installer) — 16K page CDM adaptation
- [Spotify Web Player](https://open.spotify.com)
