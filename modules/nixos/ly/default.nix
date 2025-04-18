{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.ly = {
    enable = lib.mkOption {
      description = "Whether to enable Ly display manager.";
      default = false;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf config.modules.ly.enable {
    services.displayManager = {
      ly = {
        enable = true;
        package = pkgs.ly;
      };
    };
  };
}
