{
  description = "Lightweight NixOS system health checker";

  inputs.nixpkgs.url =
    "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }: {
    packages.x86_64-linux.default =
      nixpkgs.legacyPackages.x86_64-linux.writeShellApplication {
        name = "nix-system-health";

        runtimeInputs = with nixpkgs.legacyPackages.x86_64-linux; [
          coreutils
          gnugrep
          procps
          systemd
          gawk
          gnused
        ];

        text = builtins.readFile ./scripts/nix-system-health.sh;
      };

    packages.aarch64-linux.default =
      nixpkgs.legacyPackages.aarch64-linux.writeShellApplication {
        name = "nix-system-health";

        runtimeInputs = with nixpkgs.legacyPackages.aarch64-linux; [
          coreutils
          gnugrep
          procps
          systemd
        ];

        text = builtins.readFile ./scripts/nix-system-health.sh;
      };

    nixosModules.default = import ./modules/nixos.nix;
  };
}
