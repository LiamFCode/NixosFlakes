
{ config, lib, pkgs, ... }:

let
  cfg = config.services.nix-system-health;

  package = pkgs.callPackage
    ({ writeShellApplication, coreutils, gnugrep, procps, systemd }:
      writeShellApplication {
        name = "nix-system-health";

        runtimeInputs = [
          coreutils
          gnugrep
          procps
          systemd
          gawk
          gnused
        ];

        text = builtins.readFile ../scripts/nix-system-health.sh;
      })
    {};
in
{
  options.services.nix-system-health = {
    enable = lib.mkEnableOption
      "NixOS system health monitoring";

    interval = lib.mkOption {
      type = lib.types.str;
      default = "daily";
      description = "Systemd calendar interval.";
    };

    diskThreshold = lib.mkOption {
      type = lib.types.ints.between 1 100;
      default = 85;
      description = "Disk usage warning threshold.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.nix-system-health = {
      description = "NixOS system health check";

      serviceConfig = {
        Type = "oneshot";
        ExecStart =
          "${package}/bin/nix-system-health --disk-threshold ${toString cfg.diskThreshold}";
      };
    };

    systemd.timers.nix-system-health = {
      description = "Periodic NixOS health checks";

      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = cfg.interval;
        Persistent = true;
        Unit = "nix-system-health.service";
      };
    };

    environment.systemPackages = [ package ];
  };
}
