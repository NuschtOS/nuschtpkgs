{
  python3Packages,
  lib,
  fetchFromGitHub,
  nixosTests,
}:

let
  src = fetchFromGitHub {
    # Temporarily pinned to a fork; homepage below stays on the upstream project.
    #owner = "scientress";
    owner = "MarcelCoding";
    repo = "c3ds";
    rev = "a55b2c54a873a9ef95c6f183bf614724be59b266";
    hash = "sha256-1xy507mhhRG4KkgecccnfI9mJKEBoWvR+hm76NNI+7c=";
  } + "/src/";

  # Runtime dependencies; shared between the python package and the
  # build-time python environment of the frontend derivation.
  deps =
    with python3Packages;
    [
      channels-redis
      channels
      csscompressor
      daphne
      django-compressor
      django-environ
      django-libsass
      django-vite-plugin
      django
      hiredis
      psycopg
      redis
      requests
      social-auth-app-django
    ]
    # pyproject asks for psycopg[binary]; `c` is the equivalent that builds from source.
    ++ psycopg.optional-dependencies.c;

  frontend = python3Packages.callPackage ./frontend.nix {
    inherit src;
    pythonEnv = python3Packages.python.buildEnv.override { extraLibs = deps; };
  };

  in
   python3Packages.buildPythonApplication (finalAttrs: {
    pname = "c3ds";
    version = "0-unstable-2026-09-04";

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
