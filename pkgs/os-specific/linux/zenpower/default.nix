{
  lib,
  stdenv,
  kernel,
  kernelModuleMakeFlags,
  fetchFromGitHub,
  nix-update-script,
}:

stdenv.mkDerivation {
  pname = "zenpower";
  version = "0-unstable-2026-10-11";

  src = fetchFromGitHub {
    owner = "thor2002ro";
    repo = "zenpower";
    rev = "b39014784c664dd3fc33ee8c425b135f935e62c0";
    hash = "sha256-CNbtnXddx2Iv17u1xRz9TdKQw6sCF1fpquWrsYdWSr0=";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = kernelModuleMakeFlags ++ [
    "KERNEL_BUILD=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "INSTALL_MOD_PATH=${placeholder "out"}"
    "INSTALL_MOD_DIR=kernel/drivers/hwmon/zenpower"
    "INSTALL_MOD_STRIP=1"
    "DEPMOD=true"
  ];

  installTargets = [ "modules_install" ];

  installFlags = [
    "-C"
    "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "M=$(PWD)"
  ];

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch" ];
  };

  meta = {
    description = "Linux kernel driver for reading temperature, voltage(SVI2), current(SVI2) and power(SVI2) for AMD Zen family CPUs";
    homepage = "https://github.com/thor2002ro/zenpower";
    license = lib.licenses.gpl2Plus;
    maintainers = with lib.maintainers; [
      alexbakker
      artturin
    ];
    platforms = [ "x86_64-linux" ];
  };
}
