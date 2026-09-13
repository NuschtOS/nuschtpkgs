{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  poetry-core,
  pydantic,
  pytestCheckHook,
  pyyaml,
}:

buildPythonPackage (finalAttrs: {
  pname = "hier-config";
  version = "3.7.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "netdevops";
    repo = "hier_config";
    tag = "v${finalAttrs.version}";
    hash = "sha256-PIQv3l6wookA+VtJHz6XFiMkk/lO76igZ+pWDuRHzEg=";
  };

  patches = [
    ./0001-ios-use-delta-vlan-syntax-for-trunk-port-settings.patch
  ];

  build-system = [ poetry-core ];

  dependencies = [ pydantic ];

  nativeCheckInputs = [
    pytestCheckHook
    pyyaml
  ];

  pythonImportsCheck = [ "hier_config" ];

  meta = {
    description = "Module to handle hierarchical configurations";
    homepage = "https://github.com/netdevops/hier_config";
    changelog = "https://github.com/netdevops/hier_config/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ fab ];
  };
})
