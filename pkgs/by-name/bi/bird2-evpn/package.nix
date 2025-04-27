{ lib
, stdenv
, fetchFromGitLab
, flex
, bison
, readline
, libssh
, autoreconfHook
, nixosTests
,
}:

stdenv.mkDerivation rec {
  pname = "bird-evpn";
  version = "0-unstable-2024-01-31";

  src = fetchFromGitLab {
    domain = "gitlab.nic.cz";
    owner = "labs";
    repo = "bird";
    rev = "c5c9bd811b05df3675a3c549987ebc12d789d08d";
    hash = "sha256-qPyPDi0MCCL9SRAczbK7Mh9iDr0ldlk0VROwnUrF3ww=";
  };

  nativeBuildInputs = [
    flex
    bison
  ];
  buildInputs = [
    readline
    libssh
    autoreconfHook
  ];

  patches = [
    ./dont-create-sysconfdir-2.patch
  ];

  CPP = "${stdenv.cc.targetPrefix}cpp -E";

  configureFlags = [
    "--localstatedir=/var"
    "--runstatedir=/run/bird"
  ];

  passthru.tests = nixosTests.bird;

  meta = with lib; {
    changelog = "https://gitlab.nic.cz/labs/bird/-/blob/v${version}/NEWS";
    description = "BIRD Internet Routing Daemon";
    homepage = "https://bird.network.cz";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ herbetom ];
    platforms = platforms.linux;
  };
}
