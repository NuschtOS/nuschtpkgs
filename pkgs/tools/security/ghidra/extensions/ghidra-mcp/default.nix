{
  lib,
  fetchFromGitHub,
  buildGhidraExtension,
  nix-update-script,
  nixosTests,
}:

buildGhidraExtension (finalAttrs: {
  pname = "ghidra-mcp";

  # this is reused in ghidra-mcp-bridge
  version = "6.0.0-unstable-2026-08-12";

  # this is reused in ghidra-mcp-bridge
  src = fetchFromGitHub {
    owner = "bethington";
    repo = "ghidra-mcp";
    rev = "6f7e7e8988e1efde5dd23372df71fe05c115722e";
    hash = "sha256-ds0y56sDQ7MMghOS69LC1w41VFgz93DQ+fWkGqmuHAg=";
  };

  # The wall clock time is baked into version.properties inside the jar.
  postPatch = ''
    substituteInPlace build.gradle \
      --replace-fail "new Date().format('yyyyMMdd-HHmmss')" "'19700101-000000'"
  '';

  # Upstream's buildExtension task writes the archive to build/distributions
  # instead of the dist/ directory the generic installPhase unpacks from.
  postBuild = ''
    ln -s build/distributions dist
  '';

  passthru = {
    updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };
    tests = { inherit (nixosTests) ghidra-mcp; };
  };

  meta = {
    description = "Ghidra extension exposing program data over HTTP for Model Context Protocol clients";
    homepage = "https://github.com/bethington/ghidra-mcp";
    changelog = "https://github.com/bethington/ghidra-mcp/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    maintainers = [ lib.maintainers.marcel ];
  };
})
