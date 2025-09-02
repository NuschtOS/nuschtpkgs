{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  mkdocs,
  pandas,
  tabulate,
  pyyaml,
  pytestCheckHook,
  openpyxl,
  mkdocs-macros-plugin,
}:

buildPythonPackage rec {
  pname = "mkdocs-table-reader-plugin";
  version = "3.1.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "timvink";
    repo = "mkdocs-table-reader-plugin";
    rev = "v${version}";
    hash = "sha256-XyMz0CeLQderzzz/Z3H6rja619wPzx42X3jz30wt6a8=";
  };

  build-system = [
    setuptools
  ];

  dependencies = [
    mkdocs
    pandas
    tabulate
    pyyaml
  ];

  nativeCheckInputs = [
    pytestCheckHook
    openpyxl
    mkdocs-macros-plugin
  ];

  pythonImportsCheck = [
    "mkdocs_table_reader_plugin"
  ];

  disabledTests = [
    "test_compatibility_markdownextradata"
    "test_macros_jinja2_syntax"
    "test_wrong_path"
  ];

  meta = {
    description = "MkDocs plugin that enables a markdown tag like {{ read_csv('table.csv') }} to directly insert various table formats into a page";
    homepage = "https://github.com/timvink/mkdocs-table-reader-plugin";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ marcel ];
  };
}
