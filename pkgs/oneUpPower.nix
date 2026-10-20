{
  fetchurl,
  kernel,
  kernelModuleMakeFlags,
  lib,
  stdenv,
}:
stdenv.mkDerivation {
  pname = "oneUpPower";
  version = "1.0.5";

  __structuredAttrs = true;
  strictDeps = true;
  enableParallelBuilding = true;

  src = fetchurl {
    url = "https://raw.githubusercontent.com/JeffCurless/argon-oneup/5f1b6bd6caeabcf62632360e073f51f8bdec54fb/battery/oneUpPower.c";
    hash = "sha256-qYwUlE+MqldGMNlDctihbwSjYq6F/jJJkgqVsIEIu2Q=";
  };
  dontUnpack = true;
  nativeBuildInputs = kernel.moduleBuildDependencies;
  hardeningDisable = [ "pic" ];

  postPatch = ''
    mkdir source
    cp "$src" source/oneUpPower.c
    printf '%s\n' 'obj-m += oneUpPower.o' > source/Makefile
  '';

  makeFlags = kernelModuleMakeFlags ++ [
    "KERNELRELEASE=${kernel.modDirVersion}"
    "-C"
    "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "M=$(NIX_BUILD_TOP)/source"
  ];

  buildFlags = [ "modules" ];

  # modules_install (instead of copying the .ko by hand) runs the kernel's
  # signing rule, which emits the `.ko.cer` that `aggregateModules` requires.
  installFlags = [
    "INSTALL_MOD_PATH=${placeholder "out"}"
    "INSTALL_MOD_DIR=extra"
    "DEPMOD=true"
  ];
  installTargets = [ "modules_install" ];

  meta = {
    description = "Argon ONE UP battery power-supply driver";
    homepage = "https://github.com/JeffCurless/argon-oneup";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
  };
}
