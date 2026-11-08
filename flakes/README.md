# Nix Cleanup Assistant
A lightweight disk usage analyzer and cleanup assistant for NixOS.

## Implementation
add the flake input
```
inputs.nix-cleanup-assistant.url =
    "github:LiamFCode/NixosFlakes/flakes/nix-cleanup-assistant";
```
add to modules
```
nix-cleanup-assistant.nixosModules.default
```
and then enable
```
programs.nix-cleanup-assistant.enable = true;
```

## Safety
This utility only inspects system state.
It does not automatically delete any of the following:
- Nix generations
- Nix store paths
- Journal entries
- Container images
- User files

Review suggested cleanup operations before executing them.
