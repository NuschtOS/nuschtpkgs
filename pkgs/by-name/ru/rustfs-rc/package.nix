{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rustfs-rc";
  version = "0.1.18";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "rustfs";
    repo = "cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-g+26a2hrCrexw+wi6sj+Yo0FAcPTtP+MzgK10IDr3bE=";
  };

  cargoHash = "sha256-qezRyz5+NC/4LAbqE2TpWZuy4fyjsXjcA+qP1uxaKHE=";

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
