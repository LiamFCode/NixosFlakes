{ config, lib, pkgs, ... }:

let
  cfg = config.programs.nix-update-notifier;

  package = pkgs.writeShellApplication {
    name = "nix-update";

    runtimeInputs = with pkgs; [
      nix
      jq
      coreutils
      gnused
      gnugrep
      libnotify
    ];

    text = builtins.readFile ../scripts/nix-update;
  };
in
{
  options.programs.nix-update-notifier = {
    enable = lib.mkEnableOption
      "Nix flake update notifier";

    package = lib.mkOption {
      type = lib.types.package;
      default = package;
      description = "The nix-update package";
    };

    flakePath = lib.mkOption {
      type = lib.types.path;
      default = "/etc/nixos";
      description = "Flake directory to monitor";
    };

    timer = {
      enable = lib.mkEnableOption
        "periodic flake update checks";

      interval = lib.mkOption {
        type = lib.types.str;
        default = "daily";
        description = "Systemd calendar interval";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];

    systemd.services.nix-update-notifier =
      lib.mkIf cfg.timer.enable {
        description = "Check Nix flake inputs for updates";

        serviceConfig = {
          Type = "oneshot";
          WorkingDirectory = toString cfg.flakePath;
          ExecStart = "${cfg.package}/bin/nix-update check";
        };
      };

    systemd.timers.nix-update-notifier =
      lib.mkIf cfg.timer.enable {
        description = "Periodic Nix flake update checks";

        wantedBy = [ "timers.target" ];

        timerConfig = {
          OnCalendar = cfg.timer.interval;
          Persistent = true;
          Unit = "nix-update-notifier.service";
        };
      };
  };
}
