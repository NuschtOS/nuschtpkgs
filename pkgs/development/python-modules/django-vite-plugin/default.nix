{
  buildPythonPackage,
  fetchFromGitHub,
  hatchling,
}:

buildPythonPackage rec {
  pname = "django-vite-plugin";
  version = "4.1.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "protibimbok";
    repo = "django-vite-plugin";
    tag = "v${version}";
    hash = "sha256-Xy8xqTajx+Q7HW3dXwKaLUaZY87lV8xkYY0JdrxhSdc=";
  };

  sourceRoot = "${src.name}/django";

  build-system = [ hatchling ];

  pythonImportsCheck = [ "django_vite_plugin" ];
}
