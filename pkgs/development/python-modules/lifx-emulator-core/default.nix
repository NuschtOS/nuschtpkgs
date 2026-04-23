{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  hatchling,
  pydantic,
  pytest-asyncio,
  pytestCheckHook,
  pyyaml,
  writableTmpDirAsHomeHook,
}:

buildPythonPackage rec {
  pname = "lifx-emulator-core";
  version = "3.6.3";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Djelibeybi";
    repo = "lifx-emulator";
    tag = "core-v${version}";
    hash = "sha256-bZ+u/OKFDYV0kQLeVQPDyLKC9KCTJydbl0xnuOsrh+0=";
  };

  sourceRoot = "${src.name}/packages/lifx-emulator-core";

  build-system = [ hatchling ];

  dependencies = [
    pydantic
    pyyaml
  ];

  nativeCheckInputs = [
    pytest-asyncio
    pytestCheckHook
    writableTmpDirAsHomeHook
  ];

  pythonImportsCheck = [ "lifx_emulator" ];

  meta = {
    description = "Core Python library for emulating LIFX devices using the LAN protocol";
    homepage = "https://github.com/Djelibeybi/lifx-emulator/tree/main/packages/lifx-emulator-core";
    license = lib.licenses.upl;
    maintainers = with lib.maintainers; [ SuperSandro2000 ];
  };
}
