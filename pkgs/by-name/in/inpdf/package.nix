{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "inpdf";
  version = "0-unstable-2026-06-27";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "jonhoo";
    repo = "inpdf";
    rev = "9e68f64692c34334f7631afa94783363b5862968";
    hash = "sha256-Il+RuVVQ3mWmHN0C7pi1r8f/o0AHJIkDGD+G0smeD6g=";
  };

  cargoHash = "sha256-jfdMd7GVu65VEFuLmxKFIFKM1agXUmkh/o4EgPKpp/s=";

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "";
    homepage = "https://github.com/jonhoo/inpdf";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "inpdf";
  };
})
