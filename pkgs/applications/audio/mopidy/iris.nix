{
  lib,
  python3Packages,
  fetchPypi,
  mopidy,
}:

python3Packages.buildPythonApplication rec {
  pname = "mopidy-iris";
  version = "3.70.0";

  src = fetchPypi {
    pname = "mopidy_iris";
    inherit version;
    hash = "sha256-md/1blTTtjiAAb/jiLE2EfiSlIUwEga8U7OiuKa466k=";
  };

  propagatedBuildInputs = [
    mopidy
  ]
  ++ (with python3Packages; [
    configobj
    requests
    tornado
  ]);

  # no tests implemented
  doCheck = false;

  meta = with lib; {
    homepage = "https://github.com/jaedb/Iris";
    description = "Fully-functional Mopidy web client encompassing Spotify and many other backends";
    license = licenses.asl20;
    maintainers = [ maintainers.rvolosatovs ];
  };
}
