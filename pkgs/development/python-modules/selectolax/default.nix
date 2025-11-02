{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  cython,
  setuptools,
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "selectolax";
  version = "0.4.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "rushter";
    repo = "selectolax";
    rev = "v${version}";
    fetchSubmodules = true;
    hash = "sha256-+ZV9OqhaWGX46FFTPVs1Dok+QNkX0m4zBikYZkVpw3A=";
  };

  build-system = [
    cython
    setuptools
  ];

  nativeCheckInputs = [
    pytestCheckHook
  ];

  preCheck = ''
    # shadows name and breaks imports in tests
    rm -rf selectolax
  '';

  pythonImportsCheck = [
    "selectolax"
  ];

  meta = {
    description = "Python binding to Modest and Lexbor engines. Fast HTML5 parser with CSS selectors for Python";
    homepage = "https://github.com/rushter/selectolax";
    changelog = "https://github.com/rushter/selectolax/blob/${src.rev}/CHANGES.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ marcel ];
  };
}
