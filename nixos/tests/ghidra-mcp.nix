{ pkgs, ... }:

let
  port = 8089;

  # Binaries are named by path and opened by the server itself — nothing is
  # uploaded over the API — so the unit needs to see the directory they live in.
  workspace = "/home/re/workspace";

  ghidra = pkgs.ghidra.withExtensions (p: with p; [ ghidra-mcp ]);

  # The extension ships a headless entry point next to the GUI plugin, but
  # Ghidra only exposes launchers for its own classes, so reach for the
  # generic launcher and point it at the tree holding the extension.
  ghidraMcpServer = pkgs.writeShellScript "ghidra-mcp-server" ''
    export NIX_GHIDRAHOME=${ghidra}/lib/ghidra/Ghidra
    exec ${pkgs.ghidra}/lib/ghidra/support/launch.sh \
      fg jre GhidraMCPHeadless "" "" \
      com.xebyte.headless.GhidraMCPHeadlessServer --port ${toString port}
  '';

  # Claude Code and friends speak MCP over stdio, so drive the bridge the same
  # way rather than asserting on the HTTP transports it also offers.
  mcpClient = pkgs.writers.writePython3 "ghidra-mcp-client" { } ''
    import json
    import subprocess

    proc = subprocess.Popen(
        ["bridge-mcp-ghidra", "--transport", "stdio"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        text=True,
        bufsize=1,
    )


    def notify(method, params=None):
        payload = {"jsonrpc": "2.0", "method": method, "params": params or {}}
        proc.stdin.write(json.dumps(payload) + "\n")
        proc.stdin.flush()


    def call(id_, method, params=None):
        payload = {
            "jsonrpc": "2.0",
            "id": id_,
            "method": method,
            "params": params or {},
        }
        proc.stdin.write(json.dumps(payload) + "\n")
        proc.stdin.flush()
        response = json.loads(proc.stdout.readline())
        assert "error" not in response, response
        return response["result"]


    hello = call(1, "initialize", {
        "protocolVersion": "2024-11-05",
        "capabilities": {},
        "clientInfo": {"name": "nixos-test", "version": "0"},
    })
    assert hello["serverInfo"]["name"] == "ghidra-mcp", hello
    notify("notifications/initialized")

    tools = call(2, "tools/list")["tools"]
    names = {tool["name"] for tool in tools}
    for expected in ["list_instances", "connect_instance", "load_tool_group"]:
        assert expected in names, names

    # The bridge auto-connects to the server on 127.0.0.1:8089 and turns its
    # /mcp/schema into MCP tools; only the static handful above is exposed
    # when that fails, so this is what proves the two halves talk.
    assert "decompile_function" in names, sorted(names)
    assert len(names) > 100, len(names)

    listed = call(3, "tools/call", {
        "name": "list_instances",
        "arguments": {},
    })
    payload = json.loads(listed["content"][0]["text"])
    assert "instances" in payload, payload

    proc.terminate()
  '';
in
{
  name = "ghidra-mcp";
  meta.maintainers = with pkgs.lib.maintainers; [ marcel ];

  containers.machine =
    { pkgs, ... }:
    {
      systemd.services.ghidra-mcp = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = ghidraMcpServer;
          DynamicUser = true;
          StateDirectory = "ghidra-mcp";
          Environment = [
            # Ghidra insists on a writable home for its preferences and log.
            "HOME=/var/lib/ghidra-mcp"
            # Confine every path-taking endpoint to the workspace. Left unset,
            # they accept any path the service user can read.
            "GHIDRA_MCP_FILE_ROOT=${workspace}"
          ];

          # ProtectHome would otherwise hide the binaries being analysed.
          BindReadOnlyPaths = [ workspace ];

          CapabilityBoundingSet = "";
          LockPersonality = true;
          NoNewPrivileges = true;
          PrivateDevices = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          # "tmpfs" rather than true: the latter makes /home inaccessible in a
          # way that silently swallows the BindReadOnlyPaths below.
          ProtectHome = "tmpfs";
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectProc = "invisible";
          ProtectSystem = "strict";
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = [
            "@system-service"
            "~@privileged"
            "~@resources"
          ];
        };
      };

      systemd.tmpfiles.rules = [
        "d /home/re 0755 root root -"
        "d ${workspace} 0755 root root -"
        "C ${workspace}/sample.bin 0444 root root - ${pkgs.hello}/bin/hello"
      ];

      environment.systemPackages = with pkgs; [
        curl
        ghidra-mcp-bridge
      ];
    };

  testScript = # python
    ''
      import json
      import shlex

      machine.wait_for_unit("ghidra-mcp.service")
      machine.wait_for_open_port(${toString port})

      base = "http://127.0.0.1:${toString port}"

      # The extension answers on the REST API the bridge is written against.
      status = machine.succeed(f"curl -fsS {base}/check_connection")
      assert "GhidraMCP Headless Server" in status, status

      # /mcp/schema is what the bridge turns into MCP tools once connected.
      schema = json.loads(machine.succeed(f"curl -fsS {base}/mcp/schema"))
      paths = {tool["path"] for tool in schema["tools"]}
      assert "/decompile_function" in paths, sorted(paths)[:20]
      assert len(paths) > 100, len(paths)

      def load_program(path):
          body = json.dumps({"file": path})
          return machine.succeed(
              f"curl -fsS -X POST {base}/load_program "
              f"-H 'Content-Type: application/json' -d {shlex.quote(body)}"
          )

      # The server reads the binary off disk itself, so this only works because
      # the unit binds the workspace in past ProtectHome.
      loaded = load_program("${workspace}/sample.bin")
      assert "error" not in json.loads(loaded), loaded

      # ... and only within GHIDRA_MCP_FILE_ROOT.
      denied = load_program("/etc/passwd")
      assert "Access denied" in denied, denied

      machine.succeed("${mcpClient}")
    '';
}
