{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.sway.bar = {
    enable = lib.mkOption {
      description = "Whether to enable Swaybar.";
      default = false;
      type = lib.types.bool;
    };
  };

  config =
    let
      inherit (config.modules.sway) bar colors;
    in
    lib.mkIf (bar.enable && config.modules.sway.enable) {
      wayland.windowManager.sway.config.bars = [
        {
          command = "${pkgs.sway}/bin/swaybar";

          position = "top";

          statusCommand = "${pkgs.i3status}/bin/i3status";
          mode = "dock";
          trayOutput = "none";
          workspaceButtons = true;
          extraConfig = "separator_symbol \"  \"";

          fonts = {
            names = [
              config.modules.sway.fonts.monospace
            ];
            style = "Regular";
            size = 12.0;
          };

          colors = {
            activeWorkspace = {
              background = colors.background;
              border = colors.foreground;
              text = colors.foreground;
            };
            background = colors.background;
            focusedWorkspace = {
              background = colors.foreground;
              border = colors.foreground;
              text = colors.background;
            };
            inactiveWorkspace = {
              background = colors.background;
              border = colors.background;
              text = colors.foreground;
            };
            separator = colors.background;
            statusline = colors.foreground;
            urgentWorkspace = {
              background = colors.background;
              border = colors.red;
              text = colors.foreground;
            };
          };
        }
      ];

      programs.i3status = {
        enable = true;
        package = pkgs.i3status;

        enableDefault = false;
        general = {
          output_format = "i3bar";
          colors = true;
          color_good = colors.green;
          color_degraded = colors.red;
          color_bad = colors.darkRed;
        };
        modules = {
          "wireless _first_" = {
            enable = true;
            position = 0;
            settings = {
              format_up = "📡 %essid";
              format_down = "📡 None";
            };
          };
          "battery all" = {
            enable = true;
            position = 1;
            settings = {
              format = "🔋 %percentage %status";
              format_down = "🔋 None";
              format_percentage = "%.01f%s";
              status_chr = "⚡";
              status_bat = "";
              status_unk = "";
              status_full = "✅";
              status_idle = "";
              low_threshold = 15;
              threshold_type = "percentage";
              last_full_capacity = false;
              path = "/sys/class/power_supply/BAT%d/uevent";
            };
          };
          "cpu_temperature 0" = {
            enable = true;
            position = 2;
            settings = {
              format = "🌡️ %degrees°C";
              max_threshold = 75;
            };
          };
          "memory" = {
            enable = true;
            position = 3;
            settings = {
              format = "🧠 %percentage_used";
              threshold_degraded = "10%";
              threshold_critical = "5%";
              unit = "auto";
              decimals = 1;
            };
          };
          "time" = {
            enable = true;
            position = 4;
            settings = {
              format = "%Y-%m-%d %H:%M:%S %Z ";
            };
          };
        };
      };
    };
}
