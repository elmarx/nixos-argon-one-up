# Argon ONE UP NixOS modules

This flake exports opt-in NixOS modules for [Argon ONE UP](https://argon40.com/en-de/products/argon-one-up-cm5-laptop-core-system) hardware. Each feature is independently importable; there is no aggregate module, so hosts can select only the support they need.

The battery and fan modules use options from [`nixos-raspberrypi`](https://github.com/nvmd/nixos-raspberrypi). Import its Raspberry Pi 5 base module in the host configuration before enabling these features; enabling them without it fails with an assertion.

## Importing the modules

Add the flake as an input and import individual outputs into a NixOS configuration:

```nix
{
  inputs.argon-one-up.url = "github:elmarx/nixos-argon-one-up";

  outputs = { self, nixpkgs, argon-one-up, ... }: {
    nixosConfigurations.kenny = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        argon-one-up.nixosModules.battery
        argon-one-up.nixosModules.brightness
        argon-one-up.nixosModules.fan
        argon-one-up.nixosModules.lid
      ];
    };
  };
}
```

In a flake-parts host inventory, import them where the host's NixOS modules are listed, for example:

```nix
modules = [
  inputs.argon-one-up.nixosModules.battery
  inputs.argon-one-up.nixosModules.brightness
  inputs.argon-one-up.nixosModules.fan
  inputs.argon-one-up.nixosModules.lid
];
```

## Modules

| Output | Purpose |
| --- | --- |
| `nixosModules.battery` | Battery support for the CW2217 fuel gauge via the `oneUpPower` kernel driver (a `power_supply` device); enables I2C. |
| `nixosModules.brightness` | Display brightness control: a backlight device (via the `ddcci` kernel driver), so `brightnessctl` works. |
| `nixosModules.fan` | Configures the four-point Argon fan curve through Raspberry Pi firmware parameters. |
| `nixosModules.lid` | Exposes the lid sensor (GPIO 27) as a standard `SW_LID` input switch via a device-tree overlay, so logind and desktops can react to it; defaults logind's lid action to `lock`. |

Each feature is enabled as soon as its module is imported; set the module's `enable` option to `false` to turn it off.

### Battery

The module enables I2C by setting the `i2c_arm` firmware parameter; set `services.argon-one-up.i2c.enable = false` if it is already set elsewhere.

`nixosModules.battery` uses the `oneUpPower` kernel driver, which provides a `power_supply` device and the low-battery shutdown. Options:

- `services.argon-one-up.battery.enable` — Enables the driver and overlay (default: true)
- `services.argon-one-up.battery.package` — Driver package; defaults to a build against `boot.kernelPackages` (also exposed as `packages.<system>.oneUpPower`, built against the nixpkgs kernel)
- `services.argon-one-up.battery.shutdownThreshold` — Low-charge shutdown threshold (0–20%, default 5; 0 disables automatic shutdown)

```nix
services.argon-one-up.battery.shutdownThreshold = 5;
```

The kernel driver source is fetched by a pinned raw-file URL; its source file declares SPDX `GPL-2.0-only`. The repository does not copy the upstream project or its installer scripts.

### Brightness

`nixosModules.brightness` builds the [ddcci-driver](https://gitlab.com/ddcci-driver-linux/ddcci-driver-linux) kernel modules against `boot.kernelPackages` and attaches them to the display's DDC/CI lines. This creates a regular `/sys/class/backlight/ddcci<N>` device, so `brightnessctl` works; its udev rules let members of the `video` group change the brightness. Options:

- `services.argon-one-up.brightness.enable` — Enables brightness control (default: true)
- `services.argon-one-up.brightness.package` — ddcci module package (default: `boot.kernelPackages.ddcci-driver`)
- `services.argon-one-up.brightness.bus` — I2C bus of the display (default: 14)

### Fan

`nixosModules.fan` sets the Raspberry Pi firmware fan parameters (`fan_temp0..3` and `fan_temp0..3_speed`).

Temperatures are in millidegrees Celsius, speeds are PWM values from 0 to 255. Options:

- `services.argon-one-up.fan.enable` — Applies the fan curve (default: true)
- `services.argon-one-up.fan.curve` — Exactly four points with strictly ascending temperatures

Without this module (or with `fan.enable = false`) the Raspberry Pi 5 firmware defaults apply, as documented in the [Raspberry Pi documentation](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#raspberry-pi-5-fans).

For comparison [JeffCurless/argon-oneup](https://github.com/JeffCurless/argon-oneup/blob/5f1b6bd6caeabcf62632360e073f51f8bdec54fb/config/fansettings_config.txt) uses 45/50/55/60 °C at PWM 125/175/225/250.

| Module default: temperature | fan speed | RPi firmware: temperature | fan speed |
| --- | --- | --- | --- |
| 50 °C | 125 (49%) | 50 °C | 30% |
| 55 °C | 175 (69%) | 60 °C | 50% |
| 60 °C | 225 (88%) | 67.5 °C | 70% |
| 65 °C | 255 (100%) | 75 °C | 100% |

### Lid

`nixosModules.lid` maps the lid sensor (GPIO 27) to a standard `SW_LID` input switch via a device-tree overlay, so logind, UPower and desktops see the lid state. It also sets `services.logind.settings.Login.HandleLidSwitch` and `HandleLidSwitchDocked` to `lock` with `mkDefault`: logind's default (`suspend`) leaves the Raspberry Pi 5, which cannot suspend, with a black screen, and the built-in display can make logind consider the machine docked, which uses `HandleLidSwitchDocked` (default `ignore`). Override them as usual; the module warns if one of them (or `HandleLidSwitchExternalPower`) is set to a suspend action. Option: `services.argon-one-up.lid.enable` (default: true).

logind only sends a lock request: a session needs a listener for it (e.g. `swayidle -w lock 'swaylock -f'` in Sway). Plasma and GNOME use their own lid setting. The overlay's input device is named `lid_switch`; verify events with `evtest`.
