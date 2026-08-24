{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, oniguruma
, openssl
, sqlite
, nix-update-script
,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "jcode";
  version = "0.79.1";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "1jehuang";
    repo = "jcode";
    tag = "v${finalAttrs.version}";
    hash = "sha256-k5I/ZBcQyngeVb5PbEk6FzGBLpdFcCl9qF4Oc4Hhh8Q=";
  };

  cargoHash = "sha256-xRtN/L+v2jcPaYjB0bv82mUolE5IIDcilWlTwC/V49o=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    # regex lib
    oniguruma
    openssl
    sqlite
  ];

  env = {
    LIBSQLITE3_SYS_USE_PKG_CONFIG = true;
    RUSTONIG_SYSTEM_LIBONIG = true;
    OPENSSL_NO_VENDOR = true;
  };

  cargoBuildFlags = [
    "-p"
    "jcode"
  ];
  cargoTestFlags = [
    "-p"
    "jcode"
  ];

  # some tests use global state
  dontUseCargoParallelTests = true;

  # Tests that do not set JCODE_HOME themselves fall back to dirs::home_dir(),
  # which is the unwritable /homeless-shelter in the sandbox.
  preCheck = ''
    export JCODE_HOME="$TMPDIR/jcode-home"
    mkdir -p "$JCODE_HOME"
  '';

  # Upstream CI only compiles the root crate's test binaries
  # (`cargo test --lib --bins --no-run`) and never runs them, so these
  # assertions have drifted away from the implementation.
  checkFlags = [
    # Expects the provider to be named "Jcode Hosted Models"; it returns
    # "Jcode Subscription".
    "--skip=cli::provider_init::tests::test_init_provider_jcode_delegates_runtime_profile_to_wrapper"
    # The orcarouter login provider is in the catalog but missing from the CLI
    # ProviderChoice enum, which hand-enumerates every compatible provider.
    # `orcarouter` appears nowhere in src/, so every test that walks the catalog
    # and demands a ProviderChoice for each entry fails.
    "--skip=cli::provider_init::tests::auth_integration_registry_matches_cli_choice_runtime_wiring"
    "--skip=cli::provider_init::tests::login_provider_choice_table_round_trips_catalog_providers"
    "--skip=provider_matrix_explicit_compatible_choice_overrides_stale_active_profile_state_space"
    # Asserts the follow-up message contains "completion confidence", which the
    # message builder no longer emits.
    "--skip=cli::commands::tests::run_auto_poke_followup_targets_below_threshold_todos"
    # Logs in with Cerebras and then asserts AuthStatus::has_any_available(),
    # which only ORs a hardcoded field per built-in provider. AuthStatus has no
    # field for Cerebras or any other openai-compatible profile provider, so
    # this can never hold.
    "--skip=cli::commands::report_info::tests::cli_auth_status_doctor_and_login_lifecycle_uses_fresh_sandbox"
  ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "The most RAM efficient harness";
    homepage = "https://github.com/1jehuang/jcode";
    changelog = "https://github.com/1jehuang/jcode/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "jcode";
  };
})
