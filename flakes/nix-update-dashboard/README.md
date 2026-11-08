# Nix Update Dashboard
A lightweight Nix flake input update checker.

## Usage
Check for updates:

```bash
nix-update check
```

Check another flake:

```bash
nix-update --flake ~/nixos-config check
```

List inputs:

```bash
nix-update list
```

Show outdated inputs:

```bash
nix-update outdated
```

Generate JSON:

```bash
nix-update json
```

Send desktop notification:

```bash
nix-update notify
```

Update the lockfile explicitly:

```bash
nix-update update
```

## Implementation

```nix
{
  inputs.nix-update-notifier.url =
    "github:LiamFCode/NixosFlakes/flakes/nix-update-dashboard";

  # In your NixOS module list:
  imports = [
    inputs.nix-update-notifier.nixosModules.default
  ];

  programs.nix-update-notifier = {
    enable = true;
    flakePath = "/etc/nixos";

    timer = {
      enable = true;
      interval = "daily";
    };
  };
}
```

## Safety
The check, list, outdated, and JSON commands
do not modify flake.lock

The update command explicitly modifies the lockfile.

## Limitations

- Direct root inputs only
- GitHub, GitLab and URL-based Git inputs
- Requires network access to check upstream revisions
- Some input types cannot be checked automatically
