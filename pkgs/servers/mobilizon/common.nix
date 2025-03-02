{
  applyPatches,
  fetchFromGitLab,
  fetchpatch,
}:
rec {

  pname = "mobilizon";
  version = "5.1.2";

  src = applyPatches {
    src = fetchFromGitLab {
      domain = "framagit.org";
      owner = "framasoft";
      repo = pname;
      rev = version;
      sha256 = "sha256-5xHLk5/ogtRN3mfJPP1/gIVlALerT9KEUHjLA2Ou3aM=";
    };

    patches = [
      ./allow-ldap-login-with-username.diff
      (fetchpatch {
        url = "https://codeberg.org/rheinneckar.social/mobilizon/commit/269dcdbef41b87a9eb826c8856f0c05132a22148.patch";
        hash = "sha256-a4BQ7DIxWeWoDdUBkmabbUiBO81Ct4taRpW7bpFB4Mw=";
      })
    ];
  };
}
