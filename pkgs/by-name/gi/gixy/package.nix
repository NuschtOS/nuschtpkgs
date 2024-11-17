{
  lib,
  fetchFromGitHub,
  python3,
  nginx,
}:

let
  python = python3.override {
    self = python;
    packageOverrides = self: super: {
      pyparsing = super.pyparsing.overridePythonAttrs rec {
        version = "2.4.7";
        src = fetchFromGitHub {
          owner = "pyparsing";
          repo = "pyparsing";
          rev = "pyparsing_${version}";
          sha256 = "14pfy80q2flgzjcx8jkracvnxxnr59kjzp3kdm5nh232gk1v6g6h";
        };
        nativeBuildInputs = [ super.setuptools ];
      };
    };
  };
in
python.pkgs.buildPythonApplication rec {
  pname = "gixy";
  version = "0.1.24-unstable-2024-08-17";
  pyproject = true;

  # fetching from GitHub because the PyPi source is missing the tests
  src = fetchFromGitHub {
    owner = "dvershinin";
    repo = "gixy";
    rev = "67cecfe8c5f261927c7ea06989b1e6b856e68a24";
    hash = "sha256-yeVZbZmyCtvq/YzcleUVirq/82VRPSr8OTPWieTdhgs=";
  };

  build-system = [ python.pkgs.setuptools ];

  dependencies = with python.pkgs; [
    cached-property
    configargparse
    pyparsing
    jinja2
    six
  ];

  nativeCheckInputs = [ python.pkgs.pytestCheckHook ];

  pythonRemoveDeps = [ "argparse" ];

  passthru = {
    inherit (nginx.passthru) tests;
  };

  meta = {
    description = "Nginx configuration static analyzer";
    mainProgram = "gixy";
    longDescription = ''
      Gixy is a tool to analyze Nginx configuration.
      The main goal of Gixy is to prevent security misconfiguration and automate flaw detection.
    '';
    homepage = "https://github.com/dvershinin/gixy";
    sourceProvenance = [ lib.sourceTypes.fromSource ];
    license = lib.licenses.mpl20;
    maintainers = [ lib.maintainers.willibutz ];
    platforms = lib.platforms.unix;
  };
}
