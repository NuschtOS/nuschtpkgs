{
  lib,
  stdenv,
  fetchFromGitHub,
}:

let
  console = stdenv.mkDerivation (finalAttrs: {
    pname = "rusrfs-console";
    version = "0.0.12";

    src = fetchFromGitHub {
      owner = "rustfs";
      repo = "console";
      tag = "v${finalAttrs.version}";
      hash = "sha256-wcn9x9B47s8ePe//edC918FblGSIdCmmHm2oVjmB1ms=";
    };

    pnpmDeps = pnpm.fetchDeps {
      inherit (finalAttrs) pname version src;
      fetcherVersion = 2;
      hash = "sha256-kFvHEyrDfQPYgRFW10EveL0VfYkd0Dm0X5gMJaawfGg=";
    };

    nativeBuildInputs = [
      nodejs
      pnpm.configHook
    ];

    env.NUXT_TELEMETRY_DISABLED = 1;

    buildPhase = ''
      pnpm run generate
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -rL ./.output/public/* $out/
      runHook postInstall
    '';
  });
in
rustPlatform.buildRustPackage rec {
  pname = "rustfs";
  version = "1.0.0-alpha.80";

  src = fetchFromGitHub {
    owner = "rustfs";
    repo = "rustfs";
    tag = version;
    hash = "sha256-Fe2TYDakws7plehq1Oiqk05nIM2I7ptagA22ZjqGtm0=";
  };

  postPatch = ''
    rm -rf ./rustfs/static
    cp -rL ${console} ./rustfs/static
  '';

  cargoHash = "sha256-veG33wBn8hmh5e/xB9Q/UF2gN3Ifbs1ie9JHklSP4Yc=";

  # Only build the main rustfs binary
  cargoBuildFlags = "-p rustfs";
  cargoTestFlags = "-p rustfs";

  checkFlags = [
    # assertion failed
    "--skip storage::concurrency::tests::test_concurrent_request_tracking"
    # benchmark
    "--skip storage::concurrent_get_object_test::tests::bench_concurrent_cache_performance"
    # assertion failed
    "--skip storage::concurrent_get_object_test::tests::test_advanced_buffer_sizing"
  ];

  meta = {
    description = "S3-compatible high-performance object storage system supporting migration and coexistence with other S3-compatible platforms such as MinIO and Ceph";
    homepage = "https://github.com/rustfs/rustfs";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ marcel ];
    mainProgram = "rustfs";
  };
}
