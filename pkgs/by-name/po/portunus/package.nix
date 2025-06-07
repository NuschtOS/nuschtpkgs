{
  lib,
  buildGoModule,
  fetchFromGitHub,
  fetchpatch,
  libxcrypt,
  nixosTests,
}:

buildGoModule rec {
  pname = "portunus";
  version = "2.1.4";

  src = fetchFromGitHub {
    owner = "majewsky";
    repo = "portunus";
    rev = "v${version}";
    sha256 = "sha256-xZb2+IIZkZd/yGr0+FK7Bi3sZpPMfGz/QmUKn/clrwE=";
  };

  patches = [
    # Fix missing origin header
    (fetchpatch {
      url = "https://github.com/majewsky/portunus/commit/5a71a6311458968b31a38e67642bc9a5176f1099.patch";
      hash = "sha256-xQAMn1k581vbOfAumBa/YtpQhcIrNLRgv0zmxEwOyn0=";
    })
  ];

  buildInputs = [ libxcrypt ];

  vendorHash = null;

  passthru.tests = { inherit (nixosTests) portunus; };

  meta = with lib; {
    description = "Self-contained user/group management and authentication service";
    homepage = "https://github.com/majewsky/portunus";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = with maintainers; [ majewsky ];
    teams = [ teams.c3d2 ];
  };
}
