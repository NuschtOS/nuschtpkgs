{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "sdocx2pdf";
  version = "0.3.0";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "squ1dd13";
    repo = "sdocx2pdf";
    tag = "v${finalAttrs.version}";
    hash = "sha256-sDYl2dhnayoyLbqx/SzMXvZ7m1bFZo8ufoQ7Lwpqf0Y=";
  };

  cargoHash = "sha256-rwhC6AITvrhIyqk2b1ew1Pc/0pn4c+LlFuMcCpwqipc=";

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
