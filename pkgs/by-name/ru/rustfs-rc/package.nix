{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rustfs-rc";
  version = "0.1.30";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "rustfs";
    repo = "cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-/z97K11fGRNv8XqiT6jOokqTu6RMpbq31xHUexefboM=";
  };

  cargoHash = "sha256-5Jj/FjDd0Dn5IYdYDil0kVGUp8WBVWaCV7+mw4vO/e4=";

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
