{ applyPatches, fetchFromGitLab }:
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
    ];
  };
}
