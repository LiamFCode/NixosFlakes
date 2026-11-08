# Nix Quick Actions
A declarative quick action manager for NixOS and Home Manager.

## Features
- Declarative action definitions
- CLI action execution
- Action descriptions and categories
- Searchable action registry
- Optional confirmation prompts
- Home Manager desktop entries
- NixOS system-wide configuration
- JSON-based action configuration

## CLI usage

```bash
quick-actions list
quick-actions search audio
quick-actions info lock-screen
quick-actions run lock-screen
```

## Home Manager installation

Add the flake:

```nix
inputs.nix-quick-actions.url =
  "github:YOUR_USERNAME/nix-quick-actions";
```

Import the Home Manager module:

```nix
imports = [
  inputs.nix-quick-actions.homeManagerModules.default
];
```

Enable it:

```nix
programs.quick-actions = {
  enable = true;

  actions = {
    example = {
      description = "An example action";
      command = "notify-send 'Hello from quick-actions'";
    };
  };
};
```

## NixOS installation

Import the NixOS module:

```nix
imports = [
  inputs.nix-quick-actions.nixosModules.default
];
```

Configure it:

```nix
programs.quick-actions = {
  enable = true;

  actions.example = {
    description = "Show system uptime";
    command = "uptime";
  };
};
```

## Security

Action commands are trusted shell commands.

Only define actions from configurations you trust.

Confirmation prompts are an additional safeguard,
not a security boundary.
