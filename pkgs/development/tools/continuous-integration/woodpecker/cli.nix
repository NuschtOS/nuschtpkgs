{ buildGo124Module, callPackage }:
let
  common = callPackage ./common.nix { };
in
buildGo124Module {
  pname = "woodpecker-cli";
  inherit (common)
    version
    src
    ldflags
    postInstall
    vendorHash
    ;

  subPackages = "cmd/cli";

  CGO_ENABLED = 0;

  meta = common.meta // {
    description = "Command line client for the Woodpecker Continuous Integration server";
    mainProgram = "woodpecker-cli";
  };
}
