{
  python3Packages,
  lib,
  fetchFromGitHub,
  nixosTests,
}:

let
  src = fetchFromGitHub {
    #owner = "scientress";
    owner = "MarcelCoding";
    repo = "c3ds";
    rev = "17f426f9e4e4668fc735b81520b0c5a71d7abd09";
    hash = "sha256-BgrdurowihaEwgGVL0pSc5LO0Qc4jU37lfHIElJs29Y=";
  } + "/src/";

  # Runtime dependencies; shared between the python package and the
  # build-time python environment of the frontend derivation.
  deps =
    with python3Packages;
    [
      celery
      channels-redis
      channels
      csscompressor
      daphne
      django-compressor
      django-environ
      django-filter
      django-libsass
      django-ninja
      django-prometheus
      django-vite-plugin
      django
      hiredis
      pillow
      prometheus-client
      psycopg
      qrcode
      redis
      requests
      social-auth-app-django
    ]
    ++ psycopg.optional-dependencies.c;

  frontend = python3Packages.callPackage ./frontend.nix {
    inherit src;
    pythonEnv = python3Packages.python.buildEnv.override { extraLibs = deps; };
  };

  in
   python3Packages.buildPythonApplication (finalAttrs: {
    pname = "c3ds";
    version = "0-unstable-2025-12-29";

      inherit src;

    pyproject = true;

    build-system = with python3Packages; [ hatchling ];

    dependencies = deps;

    postPatch = ''
      # vite bundles + .vite/manifest.json, built by the frontend derivation
      cp -r ${frontend}/static.dist c3ds/static.dist
    '';

    # Production settings demand a secret key when importing; the build-time
    # collectstatic only needs it to exist.
    env.DJANGO_SECRET_KEY = "c3ds-nix-build";

    postInstall = ''
      # Collect the app static files into static.dist (which already contains
      # the vite output).
      $out/bin/c3ds collectstatic --noinput
      # Generate the compressor's offline assets and manifest
      # (COMPRESS_OFFLINE); django-compressor does not do this during
      # collectstatic, and the {% compress %} tags need it at runtime.
      $out/bin/c3ds compress
    '';

    passthru = {
      pythonPackages = python3Packages;
      inherit
        frontend
        deps
        ;
      # Fully collected static file root (vite output + app static + offline
      # compression + staticfiles.json)
      static = "${finalAttrs.finalPackage.outPath}/${python3Packages.python.sitePackages}/c3ds/static.dist";
      tests = {
        inherit (nixosTests) c3ds;
      };
    };

    meta = with lib; {
      description = "Digital signage application for c3 events";
      homepage = "https://github.com/scientress/c3ds";
      license = licenses.agpl3Only;
      maintainers = with maintainers; [ marcel ];
      mainProgram = "c3ds";
      platforms = platforms.linux;
    };
  })
