{
  lib,
  rustPlatform,
  fetchFromGitLab,
  pkg-config,
  openssl,
  rust-jemalloc-sys,
  zstd,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "spade-language-server";
  version = "0.19.0";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitLab {
    owner = "spade-lang";
    repo = "spade";
    tag = "v${finalAttrs.version}";
    hash = "sha256-HSRttrf4Dsl9iatqVr9YH4MoKPwe9XJWJYqNRchFLY0=";
    fetchSubmodules = true;
  };

  cargoHash = "sha256-koMnkwgQtVMvxlslvC5dZAhr3K/66XWyp5UPW7yZtio=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    openssl
    rust-jemalloc-sys
    zstd
  ];

  cargoBuildFlags = [
    "--package"
    "spade-language-server"
  ];

  cargoTestFlags = [
    "--package"
    "spade-language-server"
  ];

  env = {
    ZSTD_SYS_USE_PKG_CONFIG = true;
  };

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Language server for the Spade hardware description language";
    homepage = "https://gitlab.com/spade-lang/spade";
    changelog = "https://gitlab.com/spade-lang/spade/-/blob/v${finalAttrs.version}/CHANGELOG.md";
    # compiler is eupl12, spade-lang stdlib is both asl20 and mit
    license = with lib.licenses; [
      eupl12
      asl20
      mit
    ];
    maintainers = with lib.maintainers; [ marcel ];
    mainProgram = "spade-language-server";
  };
})
