{
  fetchurl,
  kernel,
  lib,
  stdenv,
}:
stdenv.mkDerivation {
  pname = "oneUpPower";
  version = "1.0.5";

  src = fetchurl {
    url = "https://raw.githubusercontent.com/JeffCurless/argon-oneup/5f1b6bd6caeabcf62632360e073f51f8bdec54fb/battery/oneUpPower.c";
    hash = "sha256-qYwUlE+MqldGMNlDctihbwSjYq6F/jJJkgqVsIEIu2Q=";
  };
  dontUnpack = true;
  nativeBuildInputs = kernel.moduleBuildDependencies;
  hardeningDisable = [ "pic" ];

  buildPhase = ''
    runHook preBuild
    mkdir source
    cp "$src" source/oneUpPower.c
    printf '%s\n' 'obj-m += oneUpPower.o' > source/Makefile
    make -C "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build" M="$PWD/source" modules
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -D source/oneUpPower.ko "$out/lib/modules/${kernel.modDirVersion}/extra/oneUpPower.ko"
    runHook postInstall
  '';

  meta = {
    description = "Argon ONE UP battery power-supply driver";
    homepage = "https://github.com/JeffCurless/argon-oneup";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
  };
}
