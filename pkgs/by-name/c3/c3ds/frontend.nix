{ stdenv
, lib
, nodejs
, pnpm
, fetchPnpmDeps
, pnpmConfigHook
, src
, pythonEnv
,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "c3ds-frontend";
  version = "0-unstable-2026-09-04";

  inherit src;

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname src;
    fetcherVersion = 4;
    hash = "sha256-WatMwyy8VRE9dwI0B4JQ2YPDmfEoYHXJmdIxtTzUCeo=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm
    pnpmConfigHook
    pythonEnv
  ];

  # for patchShebangs of node_modules build scripts
  buildInputs = [ nodejs ];

  env = {
    # The vite plugin imports the production settings, which demand a secret.
    DJANGO_SECRET_KEY = "c3ds-nix-build";
  };

  buildPhase = ''
    runHook preBuild
    pnpm run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r c3ds/static.dist $out/static.dist
    runHook postInstall
  '';

  dontStrip = true;

  meta = with lib; {
    description = "Frontend build (vite bundles and manifest) of c3ds";
    homepage = "https://github.com/scientress/c3ds";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ marcel ];
    platforms = platforms.linux;
  };
})
