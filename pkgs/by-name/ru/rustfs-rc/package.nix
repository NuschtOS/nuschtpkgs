{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rustfs-rc";
  version = "0.1.20";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "rustfs";
    repo = "cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-arANPm11/CYc9FrT1/jw5Virl+cOiKpwI2gh/zelSnk=";
  };

  cargoHash = "sha256-fjx+W0y5nhbXYntmIlRBfxDqdHTYFmwyG+AEx1o9/j4=";

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "S3-compatible command-line client written in Rust";
    homepage = "https://github.com/rustfs/cli";
    changelog = "https://github.com/rustfs/cli/releases/tag/${finalAttrs.src.tag}";
    license = with lib.licenses; [
      asl20
      mit
    ];
    maintainers = with lib.maintainers; [ marcel ];
    mainProgram = "rc";
  };
})
