{
  fetchFromGitHub,
  lib,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "argon-one-up-daemon";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "0x6e3078";
    repo = "argon-one-up-daemon";
    rev = "d99b04fd945ac68a949efa342d563a9d10e98ebf";
    hash = "sha256-3sIwQW8AFvFDvVPO7eD1pZQpBPvUmVJKXD0DOLp/V7Q=";
  };

  # upstream does not ship a Cargo.lock
  postPatch = ''
    cp ${./Cargo.lock} Cargo.lock
  '';
  cargoLock.lockFile = ./Cargo.lock;

  postInstall = ''
    install -D config/org.freedesktop.UPower.BatteryArgon.conf \
      "$out/share/dbus-1/system.d/org.freedesktop.UPower.BatteryArgon.conf"
  '';

  meta = {
    description = "Argon ONE UP battery daemon exposing a UPower-compatible D-Bus device";
    homepage = "https://github.com/0x6e3078/argon-one-up-daemon";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "argon-one-up-daemon";
  };
}
