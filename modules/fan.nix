{
  config,
  lib,
  options,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;
  cfg = config.services.argon-one-up.fan;
  hasRaspberryPi = options.hardware ? raspberry-pi;
  defaultCurve = [
    {
      temperature = 45000;
      speed = 125;
    }
    {
      temperature = 50000;
      speed = 175;
    }
    {
      temperature = 55000;
      speed = 225;
    }
    {
      temperature = 60000;
      speed = 250;
    }
  ];
  parameters = lib.concatMap (point: [
    {
      name = "fan_temp${toString point.index}";
      value = {
        enable = true;
        value = toString point.temperature;
      };
    }
    {
      name = "fan_temp${toString point.index}_speed";
      value = {
        enable = true;
        value = toString point.speed;
      };
    }
  ]) (lib.imap0 (index: point: point // { inherit index; }) cfg.curve);
  temperatures = map (point: point.temperature) cfg.curve;
in
{
  options.services.argon-one-up.fan = {
    enable = mkEnableOption "Argon ONE UP fan curve" // {
      default = true;
    };

    curve = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            temperature = mkOption {
              type = types.ints.between 1 100000;
              description = "Fan activation temperature in millidegrees Celsius (e.g. 45000 for 45 °C).";
            };
            speed = mkOption {
              type = types.ints.between 0 255;
              description = "Fan PWM value from 0 (off) to 255 (full speed).";
            };
          };
        }
      );
      default = defaultCurve;
      description = "Exactly four ascending fan temperature and speed points.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = hasRaspberryPi;
          message = "services.argon-one-up.fan requires the nixos-raspberrypi modules (hardware.raspberry-pi options).";
        }
        {
          assertion = builtins.length cfg.curve == 4;
          message = "The Argon ONE UP fan curve must have exactly four points.";
        }
        {
          assertion =
            temperatures == builtins.sort builtins.lessThan temperatures
            && builtins.length (lib.unique temperatures) == builtins.length temperatures;
          message = "Argon ONE UP fan curve temperatures must be strictly ascending.";
        }
      ];
    }
    # optionalAttrs: an undefined option fails even under mkIf false
    (lib.optionalAttrs hasRaspberryPi {
      hardware.raspberry-pi.config.all.base-dt-params = builtins.listToAttrs parameters;
    })
  ]);
}
