{
  description = "A safe disk usage analyzer and cleanup assistant for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;

      packageFor = pkgs:
        pkgs.writeShellApplication {
          name = "nix-cleanup";

          runtimeInputs = with pkgs; [
            coreutils
            gnugrep
            gawk
            gnused
            nix
            systemd
          ];

          text = builtins.readFile ./scripts/nix-cleanup;
        };
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = packageFor pkgs;
          nix-cleanup = packageFor pkgs;
        });

      nixosModules.default = import ./modules/nixos.nix;
    };
}
