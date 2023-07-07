{
  lib,
  fetchFromGitHub,
  python3,
}:

let
  python = python3.override {
    packageOverrides = self: super: {
      pyparsing = super.pyparsing.overridePythonAttrs rec {
        version = "2.4.7";
        src = fetchFromGitHub {
          owner = "pyparsing";
          repo = "pyparsing";
          rev = "pyparsing_${version}";
          sha256 = "14pfy80q2flgzjcx8jkracvnxxnr59kjzp3kdm5nh232gk1v6g6h";
        };
        nativeBuildInputs = [
          super.setuptools
        ];
      };
    };
  };
in
python.pkgs.buildPythonApplication rec {
  pname = "gixy";
  version = "0.1.24";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "dvershinin";
    repo = "gixy";
    rev = "v${version}";
    hash = "sha256-YDpOqqBCNHV33j/8VuysVKJ/EcDb48nDJIxPcCDAc7o=";
  };

  postPatch = ''
    sed -ie '/argparse/d' setup.py
  '';

  propagatedBuildInputs = with python.pkgs; [
    cached-property
    configargparse
    pyparsing
    jinja2
    nose3
    setuptools
    six
  ];

  meta = with lib; {
    description = "Nginx configuration static analyzer";
    mainProgram = "gixy";
    longDescription = ''
      Gixy is a tool to analyze Nginx configuration.
      The main goal of Gixy is to prevent security misconfiguration and automate flaw detection.
    '';
    homepage = "https://github.com/dvershinin/gixy";
    license = licenses.mpl20;
    maintainers = [ maintainers.willibutz ];
    platforms = platforms.unix;
  };
}
