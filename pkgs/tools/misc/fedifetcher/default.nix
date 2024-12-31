{
  lib,
  fetchFromGitHub,
  python3,
  stdenv,
}:

python3.pkgs.buildPythonApplication rec {
  pname = "fedifetcher";
  version = "7.1.7";
  format = "other";

  src = fetchFromGitHub {
    owner = "nanos";
    repo = "FediFetcher";
    rev = "refs/tags/v${version}";
    hash = "sha256-1QLVhqyH0wb8om2pFJfmgJcYp9DTuT5KZpLy5InlRr8=";
  };

  propagatedBuildInputs = with python3.pkgs; [
    defusedxml
    python-dateutil
    requests
    xxhash
  ];

  installPhase = ''
    runHook preInstall

    install -vD find_posts.py $out/bin/fedifetcher

    runHook postInstall
  '';

  checkPhase = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    runHook preCheck

    $out/bin/fedifetcher --help>/dev/null

    runHook postCheck
  '';

  meta = with lib; {
    description = "A tool for Mastodon that automatically fetches missing replies and posts from other fediverse instances";
    longDescription = ''
      FediFetcher is a tool for Mastodon that automatically fetches missing
      replies and posts from other fediverse instances, and adds them to your
      own Mastodon instance.
    '';
    homepage = "https://blog.thms.uk/fedifetcher";
    changelog = "https://github.com/nanos/FediFetcher/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = teams.c3d2.members;
    mainProgram = "fedifetcher";
  };
}
