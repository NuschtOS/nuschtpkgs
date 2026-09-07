{
  lib,
  fetchzip,
  kernel,
  kernelModuleMakeFlags,
  stdenv,
  util-linux,
  udevCheckHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "aic8800";
  version = "250930";

  src = fetchzip {
    url = "https://static.tp-link.com/upload/driver/2025/202510/20251014/Archer_TX1U_Nano(EU)_V1_Linux_250930_6.4.3.0_Beta.zip";
    hash = "sha256-d00ytxx8tKP3nlP6dZjEZ39kTr/Fqt38quaBpJtPIAc=";
  };

  sourceRoot = "${finalAttrs.src.name}/drivers/aic8800/";

  patches = [
    ./6.18-compatibility.diff
    ./better-logging.diff
  ];

  postPatch = ''
    substituteInPlace Makefile \
      --replace-fail '/sbin/depmod' '#/sbin/depmod'

    substituteInPlace ../../tools/aic.rules \
      --replace-fail '/usr/bin/eject' '${lib.getExe' util-linux "eject"}'

    substituteInPlace aic8800_fdrv/rwnx_pci.c \
      --replace-fail "//MODULE_DEVICE_TABLE" "MODULE_DEVICE_TABLE"

    substituteInPlace aic8800_fdrv/rwnx_tx.c \
      --replace-fail "trace_printk" "printk"

    substituteInPlace aic_load_fw/aicbluetooth.c \
      --replace-fail "lib/firmware" "run/current-system/firmware"
  '';

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = [
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "MODDESTDIR=${placeholder "out"}/lib/modules/${kernel.modDirVersion}/kernel/drivers/net/wireless/aic8800"
  ]
  ++ kernelModuleMakeFlags;

  compressFirmware = false; # not supported by code

  postInstall = ''
    install -Dm444 ../../tools/aic.rules $out/lib/udev/rules.d/aic.rules

    mkdir -p $out/lib/firmware
    cp -rf ../../fw/aic8800DC $out/lib/firmware
  '';

  nativeInstallCheckInputs = [ udevCheckHook ];
  doInstallCheck = true;

  meta = {
    downloadPage = "https://www.tp-link.com/de/support/download/archer-tx1u-nano/";
    license = lib.licenses.gpl2;
    maintainers = [ ];
  };
})
