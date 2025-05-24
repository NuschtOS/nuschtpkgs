{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  fetchpatch,
  jq,
}:

buildNpmPackage rec {
  pname = "matrix-alertmanager";
  version = "0.8.0";

  src = fetchFromGitHub {
    owner = "jaywink";
    repo = "matrix-alertmanager";
    rev = "v${version}";
    hash = "sha256-GwASazYgZTYrMn696VL+JKEjECoCKxr2VWj2zae8U/E=";
  };

  patches = [
    ./shorter-retry.diff
    # Fix DoS when a request is made without auth header
    # https://github.com/jaywink/matrix-alertmanager/pull/48
    (fetchpatch {
      url = "https://github.com/jaywink/matrix-alertmanager/pull/48.patch";
      hash = "sha256-7dy8nIF3xZY/ByFJaR/r3BlkGMg1unwKp1Nf0w9RmRA=";
    })
    ./combine-grouped-alerts.diff
  ];

  postPatch = ''
    ${lib.getExe jq} '. += {"bin": "src/app.js"}' package.json > package.json.tmp
    mv package.json.tmp package.json
  '';

  npmDepsHash = "sha256-LCbImn0EGbTtB30IjLU+tjP38BQdk5Wozsl3EgOrcs8=";

  dontNpmBuild = true;

  meta = with lib; {
    changelog = "https://github.com/jaywink/matrix-alertmanager/blob/${src.rev}/CHANGELOG.md";
    description = "Bot to receive Alertmanager webhook events and forward them to chosen rooms";
    mainProgram = "matrix-alertmanager";
    homepage = "https://github.com/jaywink/matrix-alertmanager";
    license = licenses.mit;
    maintainers = with maintainers; [ erethon ];
  };
}
