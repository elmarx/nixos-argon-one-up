{
  description = "NixOS modules for the Argon ONE UP";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {

          # Built against the nixpkgs kernel for CI/inspection; the NixOS module
          # builds against the host's own kernel instead.
          packages.oneUpPower = pkgs.linuxPackages.callPackage ./pkgs/oneUpPower.nix { };
          packages.argon-one-up-daemon = pkgs.callPackage ./pkgs/argon-one-up-daemon { };

          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.nil
              pkgs.nixd
              pkgs.nixfmt
            ];
          };
        };
      flake = {
        nixosModules = {
          battery = ./modules/battery.nix;
          battery-daemon = ./modules/battery-daemon.nix;
        };
      };
    };
}
