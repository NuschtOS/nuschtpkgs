{
  lib,
  ghidra-extensions,
  python3Packages,
  nixosTests,
}:

let
  # This is just an mcp to rest api adapter. So they should be kept in sync.
  inherit (ghidra-extensions.ghidra-mcp) src version;
in

python3Packages.buildPythonApplication {
  pname = "ghidra-mcp-bridge";
  inherit src version;
  pyproject = true;

  build-system = with python3Packages; [ hatchling ];

  dependencies = with python3Packages; [
    mcp
    starlette
    uvicorn
  ];

  pythonImportsCheck = [ "bridge_mcp_ghidra" ];

  nativeCheckInputs = with python3Packages; [
    pytestCheckHook
    requests
  ];

  # Upstream's addopts pull in coverage reporting and write reports into the
  # source tree.
  pytestFlags = [
    "-o"
    "addopts="
  ];

  enabledTestPaths = [ "tests/unit" ];

  disabledTestPaths = [
    # Cover the repository's own tooling under tools/, which is not part of the
    # wheel.
    "tests/unit/test_setup_cli.py"
    "tests/unit/test_setup_ghidra.py"
    "tests/unit/test_setup_ghidra_process_detection.py"
    "tests/unit/test_setup_requirements.py"
    "tests/unit/test_version_bump.py"
    "tests/unit/test_versioning.py"
    # Assert on the layout of the git checkout and shell out to gradle.
    "tests/unit/test_ci_workflow_triggers.py"
    "tests/unit/test_gradle_tasks.py"
    "tests/unit/test_project_consistency.py"
  ];

  passthru.tests = { inherit (nixosTests) ghidra-mcp; };

  meta = {
    description = "MCP server bridging AI clients to the GhidraMCP Ghidra extension";
    longDescription = ''
      A thin Model Context Protocol to HTTP multiplexer that exposes the
      reverse-engineering tools of the GhidraMCP Ghidra extension to MCP
      clients. It requires a Ghidra instance running the matching
      `ghidra-extensions.ghidra-mcp` extension, which serves the HTTP API this
      bridge talks to.
    '';
    homepage = "https://github.com/bethington/ghidra-mcp";
    changelog = "https://github.com/bethington/ghidra-mcp/releases/tag/v${version}";
    license = lib.licenses.asl20;
    maintainers = [ lib.maintainers.marcel ];
    mainProgram = "bridge-mcp-ghidra";
  };
}
