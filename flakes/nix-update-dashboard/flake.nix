{
  description = "A flake input update checker and notification utility";

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
          name = "nix-update";

          runtimeInputs = with pkgs; [
            nix
            jq
            coreutils
            gnused
            gnugrep
            libnotify
          ];

          text = builtins.readFile ./scripts/nix-update;
        };
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = packageFor pkgs;
          nix-update = packageFor pkgs;
        });

      nixosModules.default = import ./modules/nixos.nix;
    };
}
