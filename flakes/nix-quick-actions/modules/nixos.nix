{ config, lib, pkgs, ... }:

let
  cfg = config.programs.quick-actions;

  actionType = lib.types.submodule {
    options = {
      description = lib.mkOption {
        type = lib.types.str;
        default = "";
      };

      command = lib.mkOption {
        type = lib.types.str;
      };

      category = lib.mkOption {
        type = lib.types.str;
        default = "General";
      };

      confirm = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
  };

  configFile = pkgs.writeText
    "quick-actions.json"
    (builtins.toJSON cfg.actions);

  package = pkgs.writeShellApplication {
    name = "quick-actions";

    runtimeInputs = with pkgs; [
      jq
      coreutils
      gnused
      gnugrep
    ];

    text = ''
      export QUICK_ACTIONS_CONFIG="${configFile}"
      ${builtins.readFile ../scripts/quick-actions}
    '';
  };

in
{
  options.programs.quick-actions = {
    enable = lib.mkEnableOption
      "system-wide quick actions";

    actions = lib.mkOption {
      type = lib.types.attrsOf actionType;
      default = {};
      description = "System-wide quick actions";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ package ];
  };
}
