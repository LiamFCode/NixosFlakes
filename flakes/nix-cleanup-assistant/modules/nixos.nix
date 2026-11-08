
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.nix-cleanup-assistant;

  package = pkgs.writeShellApplication {
    name = "nix-cleanup";

    runtimeInputs = with pkgs; [
      coreutils
      gnugrep
      gawk
      gnused
      nix
      systemd
    ];

    text = builtins.readFile ../scripts/nix-cleanup;
  };
in
{
  options.programs.nix-cleanup-assistant = {
    enable = lib.mkEnableOption
      "Nix cleanup assistant";

    package = lib.mkOption {
      type = lib.types.package;
      default = package;
      description = "The nix-cleanup package to install";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];
  };
}
