{ config, lib, ... }:
let
  cfg = config.services.argon-one-up.lid;
  daemonCfg = config.services.argon-one-up.battery-daemon or null;
in
{
  options.services.argon-one-up.lid = {
    enable = lib.mkEnableOption "Argon ONE UP lid switch" // {
      default = true;
    };

    action = lib.mkOption {
      type = lib.types.enum [
        "ignore"
        "lock"
        "poweroff"
      ];
      default = "lock";
      description = ''
        What logind does when the lid is closed. Suspend is deliberately not
        offered: the Raspberry Pi 5 does not support system suspend, and
        attempting it leaves a black screen.
      '';
    };
  };

  # The lid sensor is wired to GPIO 27 and not exposed by the kernel, so the
  # overlay maps it to a standard SW_LID input switch that logind and desktop
  # environments understand.
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(daemonCfg != null && daemonCfg.enable);
        message = "The Argon ONE UP battery daemon reads the lid on GPIO 27 itself, which conflicts with services.argon-one-up.lid; use the kernel battery module (nixosModules.battery) or disable the lid module.";
      }
    ];

    hardware.deviceTree.overlays = [
      {
        name = "argon-oneup-lid";
        dtsFile = ../overlays/argon-oneup-lid.dts;
      }
    ];

    services.logind.settings.Login.HandleLidSwitch = cfg.action;
  };
}
