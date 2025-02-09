{ stdenv
, lib
, fetchFromGitHub
, fetchYarnDeps
, nodejs
, fixup-yarn-lock
, yarn
, prefetch-yarn-deps
, writeText
, jq
, conf ? { }
}:

let
  pinData = lib.importJSON ./pin.json;
  noPhoningHome = {
    disable_guests = true; # disable automatic guest account registration at matrix.org
  };
  configOverrides = writeText "element-config-overrides.json" (builtins.toJSON (noPhoningHome // conf));

in
stdenv.mkDerivation rec {
  pname = "schildichat-web";
  inherit (pinData) version;

  src = fetchFromGitHub {
    owner = "SchildiChat";
    repo = "schildichat-desktop";
    inherit (pinData) rev;
    sha256 = pinData.srcHash;
    fetchSubmodules = true;
  };

  webOfflineCache = fetchYarnDeps {
    name = "yarn-web-offline-cache";
    yarnLock = src + "/element-web/yarn.lock";
    sha256 = pinData.webYarnHash;
  };
  compoundWebOfflineCache = fetchYarnDeps {
    name = "compound-web-offline-cache";
    yarnLock = src + "/compound-web/yarn.lock";
    sha256 = pinData.compoundWebYarnHash;
  };

  postPatch = ''
    cp res/css/sc-cpd-overrides.css element-web/res/css/sc-cpd-overrides.css
  '';

  nativeBuildInputs = [ yarn prefetch-yarn-deps jq nodejs fixup-yarn-lock ];

  configurePhase = ''
    runHook preConfigure

    export HOME=$PWD/tmp
    # with the update of openssl3, some key ciphers are not supported anymore
    # this flag will allow those codecs again as a workaround
    # see https://medium.com/the-node-js-collection/node-js-17-is-here-8dba1e14e382#5f07
    # and https://github.com/vector-im/element-web/issues/21043
    export NODE_OPTIONS=--openssl-legacy-provider
    mkdir -p $HOME

    pushd element-web
    fixup-yarn-lock yarn.lock
    yarn config --offline set yarn-offline-mirror $webOfflineCache
    yarn install --offline --frozen-lockfile --ignore-platform --ignore-scripts --no-progress --non-interactive
    patchShebangs node_modules
    rm -rf node_modules/@vector-im/compound-web/
    ln -s $PWD/../compound-web node_modules/@vector-im/
    popd

    pushd compound-web
    fixup-yarn-lock yarn.lock
    yarn config --offline set yarn-offline-mirror $compoundWebOfflineCache
    yarn install --offline --frozen-lockfile --ignore-platform --ignore-scripts --no-progress --non-interactive
    patchShebangs node_modules
    popd

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    pushd compound-web
    yarn build
    popd

    pushd element-web
    export VERSION=${version}
    yarn --offline build:res
    yarn --offline build:module_system
    yarn --offline build:bundle
    popd

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mv element-web/webapp $out
    jq -s '.[0] * .[1]' "configs/sc/config.json" "${configOverrides}" > "$out/config.json"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Matrix client / Element Web fork";
    homepage = "https://schildi.chat/";
    changelog = "https://github.com/SchildiChat/schildichat-desktop/releases";
    maintainers = teams.matrix.members ++ (with maintainers; [ kloenk yuka ]);
    license = licenses.asl20;
    platforms = platforms.all;
  };
}
