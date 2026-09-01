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

# Builds the c3ds frontend (Vue 3 + Vite) into `static.dist/`.
#
# The vite config uses the (npm) `django-vite-plugin`, which during the build
# spawns `python manage.py django_vite_plugin …` to query the Django project's
# settings (STATIC_ROOT, STATIC_URL, INSTALLED_APPS, static file lookup).
# Hence `pythonEnv` must provide all of c3ds' python dependencies, and `src`
# must be the *unpatched* layout where `manage.py` still sits next to
# `package.json` (the pyproject patch moves it into the `c3ds` package).
#
# The output is a single directory: the vite bundles plus
# `.vite/manifest.json`, which the (python) `django_vite_plugin` reads at
# runtime. It is copied into the python package at build time.
stdenv.mkDerivation (finalAttrs: {
  pname = "c3ds-frontend";
  version = "0-unstable-2025-12-29";

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
    # @sentry/cli's postinstall would otherwise download a binary; the sentry
    # plugin is a no-op without SENTRY_AUTH_TOKEN.
    SENTRY_SKIP_DOWNLOAD = "1";
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
