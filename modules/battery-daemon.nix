# Battery support through a userspace daemon exposing a UPower-compatible D-Bus device.
{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  cfg = config.services.argon-one-up.battery-daemon;
in
{
  imports = [ ./i2c.nix ];

  options.services.argon-one-up.battery-daemon = {
    enable = lib.mkEnableOption "Argon ONE UP battery daemon (UPower-compatible D-Bus device)" // {
      default = true;
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../pkgs/argon-one-up-daemon { };
      defaultText = lib.literalExpression "pkgs.callPackage ./pkgs/argon-one-up-daemon { }";
      description = ''
        Package providing argon-one-up-daemon. The daemon owns
        `org.freedesktop.UPower`, so `services.upower` must stay disabled.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = options.hardware ? raspberry-pi;
        message = "services.argon-one-up.battery-daemon requires the nixos-raspberrypi modules (hardware.raspberry-pi options).";
      }
      {
        assertion = !(config.services.argon-one-up.battery.enable or false);
        message = "services.argon-one-up.battery (kernel driver) and battery-daemon access the same fuel gauge; set services.argon-one-up.battery.enable = false or do not import nixosModules.battery.";
      }
      {
        assertion = !config.services.upower.enable;
        message = "The Argon ONE UP daemon provides org.freedesktop.UPower itself; disable services.upower.";
      }
    ];

    services.argon-one-up.i2c.enable = lib.mkDefault true;

    boot.kernelModules = [ "i2c-dev" ];
    services.dbus.packages = [ cfg.package ];

    systemd.services.argon-one-up-daemon = {
      description = "Argon ONE UP battery and power manager";
      wantedBy = [ "multi-user.target" ];
      after = [ "dbus.service" ];
      requires = [ "dbus.service" ];
      serviceConfig = {
        ExecStart = lib.getExe cfg.package;
        Restart = "always";
      };
    };
  };
}
