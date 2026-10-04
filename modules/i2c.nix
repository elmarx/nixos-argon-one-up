# Shared by the battery modules; not exported by the flake on its own.
{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.services.argon-one-up.i2c;
in
{
  options.services.argon-one-up.i2c.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Whether to set the `i2c_arm` firmware parameter (via nixos-raspberrypi).
      Enabled automatically by the battery modules; set it to `false` if
      `i2c_arm` is already set elsewhere.
    '';
  };

  # optionalAttrs: an undefined option fails even under mkIf false
  config = lib.mkIf cfg.enable (
    lib.optionalAttrs (options.hardware ? raspberry-pi) {
      hardware.raspberry-pi.config.all.base-dt-params.i2c_arm = {
        enable = true;
        value = "on";
      };
    }
  );
}
