{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "sdocx2pdf";
  version = "0.2.2";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "squ1dd13";
    repo = "sdocx2pdf";
    tag = "v${finalAttrs.version}";
    hash = "sha256-rMw6HaHFgF8NSBq3IK8FnudhPRM7C+xBIbIhUe51Lu4=";
  };

  cargoHash = "sha256-k3L2E+k+kxkm5wQ8pBu2RZCCmQqvTEuYNAb/IrxUAr8=";

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Tool for converting Samsung Notes documents to vector PDFs";
    homepage = "https://github.com/squ1dd13/sdocx2pdf";
    changelog = "https://github.com/squ1dd13/sdocx2pdf/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ marcel ];
    mainProgram = "sdocx2pdf";
  };
})
