{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "sdocx2pdf";
  version = "0.2.3";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "squ1dd13";
    repo = "sdocx2pdf";
    tag = "v${finalAttrs.version}";
    hash = "sha256-O22Kdi9kwpTcKGlg4gl/AMfp8au3+4PTIbN0IE7tX0w=";
  };

  cargoHash = "sha256-hnvfiY7DoPC22sqJxfj5Z9lUa8t/BOMuo9MEjKXSqhs=";

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
