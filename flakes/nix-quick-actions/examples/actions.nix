{
  programs.quick-actions = {
    enable = true;

    actions = {
      update-system = {
        description = "Update and rebuild NixOS";
        category = "System";
        command = ''
          sudo nixos-rebuild switch --flake /etc/nixos
        '';
      };

      garbage-collect = {
        description = "Remove old Nix generations";
        category = "Maintenance";
        confirm = true;
        command = ''
          sudo nix-collect-garbage -d
        '';
      };

      optimize-store = {
        description = "Optimize the Nix store";
        category = "Maintenance";
        confirm = true;
        command = ''
          nix-store --optimise
        '';
      };

      restart-network = {
        description = "Restart NetworkManager";
        category = "Networking";
        confirm = true;
        command = ''
          sudo systemctl restart NetworkManager
        '';
      };

      open-nixos-config = {
        description = "Open NixOS configuration";
        category = "Development";
        command = ''
          exec "$EDITOR" ~/nixos-config/flake.nix
        '';
      };

      reload-audio = {
        description = "Restart PipeWire audio";
        category = "Desktop";
        command = ''
          systemctl --user restart pipewire pipewire-pulse wireplumber
        '';
      };

      lock-screen = {
        description = "Lock the desktop";
        category = "Desktop";
        command = ''
          loginctl lock-session
        '';
      };
    };
  };
}
