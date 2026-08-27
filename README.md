<div align="center">

# nix-spotify-aarch64

**Spotify on aarch64 NixOS** — native Chromium app window plus Widevine. Not FEX, Box64, or muvm.

[![NixOS](https://img.shields.io/badge/NixOS-unstable-informational?logo=NixOS)](https://nixos.org)
[![Flake](https://img.shields.io/badge/Flake-enabled-success)](https://nixos.wiki/wiki/Flakes)

</div>

Spotify does not ship an ARM64 Linux desktop client. nixpkgs `spotify` is `x86_64-linux` (and Darwin) only. This flake wraps the official web player in Chromium with [Widevine](https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/wi/widevine-cdm/aarch64-linux.nix) (Asahi 16K page fixup included upstream) so playback works on Apple Silicon NixOS without emulating x86.

Use nixpkgs `spotify` on `x86_64-linux`. This flake is `aarch64-linux` only.

## Quick Start

```bash
nix run github:gaavin/nix-spotify-aarch64
```

Requires `aarch64-linux`, flakes, and unfree packages (Widevine + Spotify).

## Install with Home Manager

### 1. Add to flake inputs

```nix
{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-spotify-aarch64.url = "github:gaavin/nix-spotify-aarch64";
    nix-spotify-aarch64.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, nix-spotify-aarch64, ... }:
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
              extraSpecialArgs = { inherit nix-spotify-aarch64; };
              users.YOUR_USERNAME = import ./home.nix;
              sharedModules = [
                nix-spotify-aarch64.homeModules.nix-spotify-aarch64
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
  programs.nix-spotify-aarch64.enable = true;
}
```

### 3. Build & launch

```bash
nix flake update nix-spotify-aarch64
sudo nixos-rebuild switch --flake .#YOUR_CONFIGURATION
spotify
```

Sign in inside the app window. Profile data lives under `~/.local/share/nix-spotify-aarch64/chromium`.

## Commands

| Command | Purpose |
|---------|---------|
| `spotify` | Launch the app window |

## Paths

```
~/.local/share/nix-spotify-aarch64/
  chromium/     Chromium user-data (login, cache)
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No sound / "Spotify can't play this" | Widevine must load; this package sets `chromium.override { enableWideVine = true; }`. Rebuild with `allowUnfree`. |
| Window looks like a browser tab | Launch via the `spotify` wrapper (`--app=https://open.spotify.com`), not Chromium itself. |
| Signed out on every launch | Chromium's Secret Portal (KWallet) was encrypting cookies despite `--password-store=basic`. The wrapper now disables `DbusSecretPortal` / `SecretPortalKeyProviderUseForEncryption` and seeds session restore. Sign in **once** after updating (old portal-encrypted cookies are wiped). To start clean, remove `~/.local/share/nix-spotify-aarch64/`. |
| Scale is wrong | `programs.nix-spotify-aarch64.extraArgs = [ "--force-device-scale-factor=1.25" ];` |
| Start fresh | Remove `~/.local/share/nix-spotify-aarch64/` |

## Advanced

Package only:

```nix
home.packages = [
  inputs.nix-spotify-aarch64.packages.${pkgs.stdenv.hostPlatform.system}.nix-spotify-aarch64
];
```

Overrides:

```nix
inputs.nix-spotify-aarch64.packages.${pkgs.stdenv.hostPlatform.system}.nix-spotify-aarch64.override {
  location = "$HOME/.local/share/nix-spotify-aarch64";
  extraArgs = [ "--force-device-scale-factor=1.25" ];
}
```

```bash
nix build github:gaavin/nix-spotify-aarch64
```

## Credits

- [NixOS/nixpkgs `widevine-cdm`](https://github.com/NixOS/nixpkgs/tree/nixos-unstable/pkgs/by-name/wi/widevine-cdm) — aarch64 CDM + Asahi `widevine_fixup.py`
- [AsahiLinux/widevine-installer](https://github.com/AsahiLinux/widevine-installer) — 16K page CDM adaptation
- [Spotify Web Player](https://open.spotify.com)
