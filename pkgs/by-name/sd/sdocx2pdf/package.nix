{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "sdocx2pdf";
  version = "0.4.0";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "squ1dd13";
    repo = "sdocx2pdf";
    tag = "v${finalAttrs.version}";
    hash = "sha256-gBTqHyZCj8YKvhpUKfJsw+XvWOw5A/veV9aRFooLUvA=";
  };

  cargoHash = "sha256-zZG7pkNvtlUIr9BvxKB5kqYmuw4BKMYf4OBxofV5a7s=";

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
