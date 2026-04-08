{
  fetchFromGitHub,
  buildPythonPackage,
  setuptools,
  packbits,
  pillow,
  pyusb,
  click,
  attrs,
  lib,
}:

buildPythonPackage {
  pname = "brother-ql";
  version = "0-unstable-2026-03-12";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "matmair";
    repo = "brother_ql-inventree";
    rev = "5364d30e0ad088fa943642a05863814390d52b4f";
    hash = "sha256-wSekzrpiOeyT51Wlf7haLpPhbY6/PWtZljG88ihrMKo=";
  };

  build-system = [
    setuptools
  ];

  dependencies = [
    click
    packbits
    pillow
    pyusb
    attrs
  ];

  meta = {
    description = "Python package for the raster language protocol of the Brother QL series label printers";
    longDescription = ''
      Python package for the raster language protocol of the Brother QL series label printers
      (QL-500, QL-550, QL-570, QL-700, QL-710W, QL-720NW, QL-800, QL-820NWB, QL-1050 and more)
    '';
    homepage = "https://github.com/matmair/brother_ql-inventree";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ marcel ];
    mainProgram = "brother_ql";
  };
}
