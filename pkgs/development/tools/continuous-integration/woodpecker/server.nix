{ buildGo124Module, callPackage }:
let
  common = callPackage ./common.nix { };
in
buildGo124Module {
  pname = "woodpecker-server";
  inherit (common)
    version
    src
    ldflags
    postInstall
    vendorHash
    ;

  subPackages = "cmd/server";

  CGO_ENABLED = 1;

  passthru = {
    updateScript = ./update.sh;
  };

  meta = common.meta // {
    description = "Woodpecker Continuous Integration server";
    mainProgram = "woodpecker-server";
  };
}
