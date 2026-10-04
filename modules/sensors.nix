{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.services.argon-one-up.sensors.enable =
    lib.mkEnableOption "Argon ONE UP lm-sensors labels"
    // {
      default = true;
    };

  config = lib.mkIf config.services.argon-one-up.sensors.enable {
    environment.etc."sensors.d/argon-one-up.conf".text = ''
      chip "cpu_thermal-virtual-*"
          label temp1 "CPU"

      chip "rp1_adc-isa-*"
          label temp1 "RP1"
          label in1 "1.8V Rail"
          label in2 "3.3V Rail"
          label in3 "1.5V Rail A"
          label in4 "1.5V Rail B"

      chip "pwmfan-isa-*"
          label fan1 "CPU Fan"
          ignore pwm1
          ignore pwm1_enable

      chip "nvme-pci-*"
          label temp1 "NVMe"
          ignore temp2
          ignore temp3

      chip "BAT0-virtual-*"
          label in0 "Battery Voltage"
          label temp1 "Battery"

      chip "rpi_volt-isa-*"
          ignore in0
    '';
    environment.systemPackages = [ pkgs.lm_sensors ];
  };
}
