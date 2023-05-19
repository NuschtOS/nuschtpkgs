{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  makeWrapper,
  curl,
  jq,
  mpv,
}:

stdenv.mkDerivation rec {
  pname = "somafm-cli";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "rockymadden";
    repo = "somafm-cli";
    rev = "v${version}";
    sha256 = "1h5p9qsczgfr450sklh2vkllcpzb7nicbs8ciyvkavh3d7hds0yy";
  };

  patches = [
    # allow using mpv controls
    (fetchpatch {
      url = "https://github.com/rockymadden/somafm-cli/commit/4ef4cbf3b86dfaa0344941a5999f59980420b4da.patch";
      hash = "sha256-xgoxKVq0734LppSM7DM2QQEzGFyo4cpc6IclCGD+GBg=";
    })
    # format list table
    (fetchpatch {
      url = "https://github.com/rockymadden/somafm-cli/pull/19.patch";
      hash = "sha256-Bj/EC+qLuGAo+S1AEkZC8vC+VzrXRtnnoeRloJy0aRY=";
    })
  ];

  postPatch = ''
    substituteInPlace src/somafm \
      --replace '*) mpv --no-config' '*) mpv'
  '';

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    install -m0755 -D src/somafm $out/bin/somafm
    wrapProgram $out/bin/somafm --prefix PATH ":" "${
      lib.makeBinPath [
        curl
        jq
        mpv
      ]
    }";
  '';

  meta = with lib; {
    description = "Listen to SomaFM in your terminal via pure bash";
    homepage = "https://github.com/rockymadden/somafm-cli";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = with maintainers; [ SuperSandro2000 ];
    mainProgram = "somafm";
  };
}
