{
  description = "Declarative quick actions for Linux";

  inputs.nixpkgs.url =
    "github:NixOS/nixpkgs/nixos-unstable";

  inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;

      packageFor = pkgs:
        pkgs.writeShellApplication {
          name = "quick-actions";

          runtimeInputs = with pkgs; [
            coreutils
            gnused
            gnugrep
          ];

          text = builtins.readFile ./scripts/quick-actions;
        };
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = packageFor pkgs;
          quick-actions = packageFor pkgs;
        });

      nixosModules.default = import ./modules/nixos.nix;

      homeManagerModules.default =
        import ./modules/home-manager.nix;
    };
}
