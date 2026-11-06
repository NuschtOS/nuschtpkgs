{
  lib,
  stdenv,
  fetchFromGitHub,
  makeBinaryWrapper,
  nodejs,
  python3,
  sqlite,
  nixosTests,
  yarn-berry_4,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "hedgedoc";
  version = "1.12.0";

  src = fetchFromGitHub {
    owner = "hedgedoc";
    repo = "hedgedoc";
    tag = finalAttrs.version;
    hash = "sha256-QYWDgQuSsMf8xElSK0MpthOMAB6EJXcxfOWcHrR4ODU=";
  };

  patches = [
    # Remove after upstream updates to Yarn 4.14
    # https://github.com/hedgedoc/hedgedoc/blob/develop/package.json#L28
    ./yarn-4.14-support.patch
  ];

  # Generate this file with:
  # nix run nixpkgs#yarn-berry_4.yarn-berry-fetcher missing-hashes yarn.lock
  missingHashes = ./missing-hashes.json;

  offlineCache = yarn-berry_4.fetchYarnBerryDeps {
    inherit (finalAttrs) src missingHashes patches;
    hash = "sha256-2qwTV9GRKnVIhK6dsSfis+JOTfjcdwW0RVdrJZa/uJc=";
  };

  nativeBuildInputs = [
    makeBinaryWrapper
    (python3.withPackages (ps: with ps; [ setuptools ])) # required to build sqlite3 bindings
    yarn-berry_4
    yarn-berry_4.yarnBerryConfigHook
  ];

  buildInputs = [
    nodejs # for shebangs
    sqlite
  ];

  # link the sqlite3 node module against system sqlite instead of the bundled copy
  env.npm_config_sqlite = lib.getDev sqlite;

  buildPhase = ''
    runHook preBuild

    yarn run build

    # Delete scripts that are not useful for NixOS
    rm bin/{heroku,setup}

    runHook postBuild
  '';

  # Prune non-prod deps before install to save space
  preInstall = ''
    yarn workspaces focus -A --production
  '';

  installPhase = ''
    runHook preInstall

    # intermediate build artifacts of the sqlite3 node module, they reference sqlite.dev
    rm -r node_modules/sqlite3/build/{*Makefile,*.gypi,*.mk,Release/obj.target,Release/.deps}

    mkdir -p $out/share/hedgedoc
    cp -r {app.js,bin,lib,locales,node_modules,package.json,public} $out/share/hedgedoc

    makeWrapper ${nodejs}/bin/node $out/bin/hedgedoc \
      --add-flags $out/share/hedgedoc/app.js \
      --set NODE_ENV production
    for bin in $out/share/hedgedoc/bin/*; do
      makeWrapper $bin $out/bin/$(basename $bin) --set NODE_ENV production
    done

    runHook postInstall
  '';

  disallowedReferences = [ sqlite.dev ];

  passthru = {
    tests = { inherit (nixosTests) hedgedoc; };
  };

  meta = {
    description = "Realtime collaborative markdown notes on all platforms";
    license = lib.licenses.agpl3Only;
    homepage = "https://hedgedoc.org";
    changelog = "https://github.com/hedgedoc/hedgedoc/releases/tag/${finalAttrs.src.tag}";
    mainProgram = "hedgedoc";
    maintainers = with lib.maintainers; [ SuperSandro2000 ];
    platforms = lib.platforms.linux;
  };
})
