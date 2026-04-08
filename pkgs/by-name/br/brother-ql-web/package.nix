{
  lib,
  python312,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
}:

let
  python = python312;
  pythonPath = python.pkgs.makePythonPath (
    with python.pkgs;
    [
      flask
      brother-ql-inventree
      fonttools
      pdf2image
      python-barcode
      qrcode
      dominate
      iniconfig
      pluggy
      pygments
      visitor
    ]
  );
in
stdenv.mkDerivation {
  pname = "brother-ql-web";
  version = "0-unstable-2026-04-08";

  src = fetchFromGitHub {
    owner = "MarcelCoding";
    repo = "brother_ql_web";
    rev = "3d028fc7ae8d861a4439a06a8f8107d6f5c734a4";
    hash = "sha256-7u5dfaagoiKLo3xSTadOImq5MsHDx1vG40pez9p3OUQ=";
  };

  postPatch = ''
    substituteInPlace app/__init__.py \
      --replace-fail "args = parser.parse_args()" "args, _ = parser.parse_known_args()"
  '';

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    mkdir $out
    cp -r * $out

    makeWrapper ${lib.getExe python.pkgs.gunicorn} $out/bin/brother-ql-web \
      --chdir $out \
      --set PYTHONPATH "${pythonPath}" \
      --add-flags "-m 007 wsgi:app"
  '';

  meta = {
    description = "Python-based web service to print labels on Brother QL label printers";
    homepage = "https://github.com/DL6ER/brother_ql_web";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ marcel ];
  };
}
