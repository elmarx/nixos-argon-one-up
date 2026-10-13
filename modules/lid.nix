{ config, lib, ... }:
let
  cfg = config.services.argon-one-up.lid;
  suspendActions = [
    "suspend"
    "hibernate"
    "hybrid-sleep"
    "suspend-then-hibernate"
  ];
in
{
  options.services.argon-one-up.lid = {
    enable = lib.mkEnableOption "Argon ONE UP lid switch" // {
      default = true;
    };
  };

  # The lid sensor is wired to GPIO 27 and not exposed by the kernel, so the
  # overlay maps it to a standard SW_LID input switch that logind and desktop
  # environments understand.
  config = lib.mkIf cfg.enable {
    hardware.deviceTree.overlays = [
      {
        name = "argon-oneup-lid";
        # substring match on the dtb path (not a glob); also keeps overlay_map.dtb
        # (no compatible string, breaks the overlay build) out
        filter = "bcm2712";
        dtsFile = ../overlays/argon-oneup-lid.dts;
      }
    ];

    # logind defaults to suspend, which the Raspberry Pi 5 does not support.
    # The built-in display is connected via HDMI, so logind always considers the
    # machine docked and uses HandleLidSwitchDocked (default: ignore) instead.
    services.logind.settings.Login = {
      HandleLidSwitch = lib.mkDefault "lock";
      HandleLidSwitchDocked = lib.mkDefault "lock";
    };

    warnings =
      let
        login = config.services.logind.settings.Login;
      in
      lib.concatMap
        (
          key:
          let
            action = login.${key} or null;
          in
          lib.optional (action != null && builtins.elem action suspendActions) ''
            services.logind.settings.Login.${key} is "${action}", which makes logind suspend when the lid is closed. The Raspberry Pi 5 cannot suspend and a suspend attempt leaves a black screen; use "lock" or "ignore" instead.
          ''
        )
        [
          "HandleLidSwitch"
          "HandleLidSwitchDocked"
          "HandleLidSwitchExternalPower"
        ];
  };
}
