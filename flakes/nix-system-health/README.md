# NixOS System
Checks disk, memory, failed systemd services, and reports issues.

## Implementation
To use this flake, simply add the following code to your NixOS configuration file.<br>
```
{
  inputs.nix-system-health.url =
    "github:LiamFCode/NixosFlakes/flakes/nix-system-health";

  outputs = { nixpkgs, nix-system-health, ... }: {
    nixosConfigurations.myhost =
      nixpkgs.lib.nixosSystem {
        modules = [
          nix-system-health.nixosModules.default

          {
            services.nix-system-health = {
              enable = true;
              interval = "daily";
              diskThreshold = 85;
            };
          }
        ];
      };
  };
}
```
Or run it independently through the terminal via
```
nix run github:LiamFCode/NixosFlakes/flakes/nix-system-health

nix run github:LiamFCode/NixosFlakes/flakes/nix-system-health -- --disk-threshold 90
```
The scheduled service writes its output to the systemd journal access at
```
journalctl -u nix-system-health.service
```
