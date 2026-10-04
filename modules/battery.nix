# Battery support through the `oneUpPower` kernel driver (power_supply device).
{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.services.argon-one-up.battery;
in
{
  imports = [ ./i2c.nix ];

  options.services.argon-one-up.battery = {
    enable = lib.mkEnableOption "Argon ONE UP battery support (kernel driver)" // {
      default = true;
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = config.boot.kernelPackages.callPackage ../pkgs/oneUpPower.nix { };
      defaultText = lib.literalExpression "config.boot.kernelPackages.callPackage ./pkgs/oneUpPower.nix { }";
      description = ''
        Package providing the oneUpPower kernel module. It must be built
        against the host's kernel, hence the default uses `boot.kernelPackages`.
      '';
    };

    shutdownThreshold = lib.mkOption {
      type = lib.types.ints.between 0 20;
      default = 5;
      description = ''
        Battery percentage below which the driver shuts down the system while
        running on battery power. Set to 0 to disable automatic shutdown.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = options.hardware ? raspberry-pi;
        message = "services.argon-one-up.battery requires the nixos-raspberrypi modules (hardware.raspberry-pi options).";
      }
    ];

    services.argon-one-up.i2c.enable = lib.mkDefault true;

    boot = {
      extraModulePackages = [ cfg.package ];
      kernelModules = [ "oneUpPower" ];
      extraModprobeConfig = ''
        options oneUpPower soc_shutdown=${toString cfg.shutdownThreshold}
      '';
    };

    hardware.deviceTree.overlays = [
      {
        name = "argon-oneup-battery";
        # substring match on the dtb path (not a glob); also keeps overlay_map.dtb
        # (no compatible string, breaks the overlay build) out
        filter = "bcm2712";
        dtsFile = ../overlays/argon-oneup-battery.dts;
      }
    ];
  };
}
