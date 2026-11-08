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

      terminal = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };

      desktopEntry = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };
  };

  actionConfig = builtins.toJSON cfg.actions;

  package = pkgs.writeShellApplication {
    name = "quick-actions";

    runtimeInputs = with pkgs; [
      jq
      coreutils
      gnused
      gnugrep
    ];

    text = ''
      export QUICK_ACTIONS_CONFIG="${config.xdg.configHome}/quick-actions/actions.json"
      ${builtins.readFile ../scripts/quick-actions}
    '';
  };

in
{
  options.programs.quick-actions = {
    enable = lib.mkEnableOption
      "declarative quick actions";

    actions = lib.mkOption {
      type = lib.types.attrsOf actionType;
      default = {};
      description = "Declarative quick actions.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ package ];

    xdg.configFile."quick-actions/actions.json".text =
      actionConfig;

    xdg.desktopEntries =
      lib.mapAttrs'
        (name: action:
          lib.nameValuePair "quick-action-${name}" {
            name = name;
            comment = action.description;
            exec = "${package}/bin/quick-actions run ${lib.escapeShellArg name}";
            terminal = action.terminal;
            categories = [ "Utility" ];
          })
        (lib.filterAttrs
          (_: action: action.desktopEntry)
          cfg.actions);
  };
}
