{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.argon-one-up.display;
in
{
  options.services.argon-one-up.display = {
    enable = lib.mkEnableOption "Argon ONE UP display brightness control (DDC/CI)" // {
      default = true;
    };
  };

  # The panel is attached via HDMI and has no backlight device; brightness is
  # set with DDC/CI over the HDMI connector's I2C bus (found with `ddcutil detect`).
  config = lib.mkIf cfg.enable {
    hardware.i2c.enable = true;
    environment.systemPackages = [ pkgs.ddcutil ];
  };
}
