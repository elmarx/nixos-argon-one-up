# Argon ONE UP NixOS modules

This flake exports opt-in NixOS modules for Argon ONE UP hardware. Each feature is independently importable; there is no aggregate module, so hosts can select only the support they need.

The battery module uses options from [`nixos-raspberrypi`](https://github.com/nvmd/nixos-raspberrypi). Import its Raspberry Pi 5 base module in the host configuration before enabling these features; enabling them without it fails with an assertion.

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
];
```

## Modules

| Output | Purpose |
| --- | --- |
| `nixosModules.battery` | Battery support for the CW2217 fuel gauge via the `oneUpPower` kernel driver (a `power_supply` device); enables I2C. |
| `nixosModules.battery-daemon` | Battery support via a userspace daemon exposing a UPower-compatible D-Bus device; enables I2C. Alternative to `battery`. |
| `nixosModules.brightness` | Display brightness control: a backlight device (via the `ddcci` kernel driver), so `brightnessctl` works. |

Each feature is enabled as soon as its module is imported; set the module's `enable` option to `false` to turn it off.

### Battery

Two mutually exclusive modules access the same fuel gauge; import only one. Both enable I2C by setting the `i2c_arm` firmware parameter; set `services.argon-one-up.i2c.enable = false` if it is already set elsewhere.

`nixosModules.battery` uses the `oneUpPower` kernel driver, which provides a `power_supply` device and the low-battery shutdown. Options:

- `services.argon-one-up.battery.enable` — Enables the driver and overlay (default: true)
- `services.argon-one-up.battery.package` — Driver package; defaults to a build against `boot.kernelPackages` (also exposed as `packages.<system>.oneUpPower`, built against the nixpkgs kernel)
- `services.argon-one-up.battery.shutdownThreshold` — Low-charge shutdown threshold (0–20%, default 5; 0 disables automatic shutdown)

```nix
services.argon-one-up.battery.shutdownThreshold = 5;
```

`nixosModules.battery-daemon` uses [argon-one-up-daemon](https://github.com/0x6e3078/argon-one-up-daemon) (GPL-3.0) instead. It reads the fuel gauge over I2C and exposes a UPower-compatible D-Bus device, which desktops such as KDE Plasma and GNOME display. It owns `org.freedesktop.UPower`, so `services.upower` must be disabled (asserted). It does not shut the system down on low battery itself; leave that to the desktop's power management. Options:

- `services.argon-one-up.battery-daemon.enable` — Enables the daemon (default: true)
- `services.argon-one-up.battery-daemon.package` — Daemon package (also exposed as `packages.<system>.argon-one-up-daemon`)

The kernel driver source is fetched by a pinned raw-file URL; its source file declares SPDX `GPL-2.0-only`. The repository does not copy the upstream project or its installer scripts.

### Brightness

`nixosModules.brightness` builds the [ddcci-driver](https://gitlab.com/ddcci-driver-linux/ddcci-driver-linux) kernel modules against `boot.kernelPackages` and attaches them to the display's DDC/CI lines. This creates a regular `/sys/class/backlight/ddcci<N>` device, so `brightnessctl` works; its udev rules let members of the `video` group change the brightness. Options:

- `services.argon-one-up.brightness.enable` — Enables brightness control (default: true)
- `services.argon-one-up.brightness.package` — ddcci module package (default: `boot.kernelPackages.ddcci-driver`)
- `services.argon-one-up.brightness.bus` — I2C bus of the display (default: 14)
