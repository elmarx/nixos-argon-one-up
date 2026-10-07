# Display brightness control through a regular backlight device, usable with brightnessctl.
#
# The panel is connected via HDMI and is controlled with DDC/CI. The ddcci kernel driver
# turns the panel into a `/sys/class/backlight/ddcciN` device.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.argon-one-up.brightness;
  bus = toString cfg.bus;
in
{
  options.services.argon-one-up.brightness = {
    enable =
      lib.mkEnableOption "Argon ONE UP brightness control (backlight device for brightnessctl)"
      // {
        default = true;
      };

    package = lib.mkOption {
      type = lib.types.package;
      default = config.boot.kernelPackages.ddcci-driver;
      defaultText = lib.literalExpression "config.boot.kernelPackages.ddcci-driver";
      description = "Package providing the ddcci kernel modules, built against the host kernel.";
    };

    bus = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 14;
      description = "Number of the I2C bus carrying the DDC/CI lines of the internal display.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.extraModulePackages = [ cfg.package ];
    boot.kernelModules = [
      "ddcci"
      "ddcci-backlight"
    ];

    # lets members of the `video` group change the brightness
    services.udev.packages = [ pkgs.brightnessctl ];

    # The vc4 HDMI I2C adapter is not probed for DDC/CI automatically, so attach the device by hand.
    systemd.services.argon-one-up-brightness = {
      description = "Attach ddcci to the Argon ONE UP display";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-modules-load.service" ];
      unitConfig.ConditionPathExists = "/sys/bus/i2c/devices/i2c-${bus}";
      script = ''
        [ -e /sys/bus/i2c/devices/${bus}-0037 ] || echo ddcci 0x37 > /sys/bus/i2c/devices/i2c-${bus}/new_device
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ReadWritePaths = "/sys/bus/i2c/devices";
        CapabilityBoundingSet = "";
        NoNewPrivileges = true;
        PrivateNetwork = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = "none";
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        SystemCallArchitectures = "native";
      };
    };
  };
}
