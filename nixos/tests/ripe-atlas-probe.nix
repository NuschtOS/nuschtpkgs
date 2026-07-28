{ lib, ... }:
{
  name = "ripe-atlas-probe";

  meta.maintainers = with lib.maintainers; [ marcel ];

  nodes.machine = {
    services.ripe-atlas-probe = {
      enable = true;
      mode = "prod";
      settings = {
        TELNETD_PORT = 2023;
        RXTXRPT = true;
      };
    };
  };

  # The probe cannot actually register with RIPE's infrastructure from within
  # the sandboxed test network, but it should come up, generate its probe key
  # and stay running while it retries registration.
  testScript = ''
    machine.wait_for_unit("ripe-atlas-probe.service")

    with subtest("probe key is generated"):
        machine.wait_for_file("/etc/ripe-atlas/probe_key.pub")
        machine.succeed("test -f /etc/ripe-atlas/probe_key")

    with subtest("configuration is seeded from the module"):
        machine.succeed("grep -qx prod /etc/ripe-atlas/mode")
        machine.succeed("grep -qx 'TELNETD_PORT=2023' /etc/ripe-atlas/config.txt")
        machine.succeed("grep -qx 'RXTXRPT=yes' /etc/ripe-atlas/config.txt")

    with subtest("the local telnet control channel comes up"):
        machine.wait_for_open_port(2023, addr="127.0.0.1")

    with subtest("service keeps running while retrying registration"):
        machine.succeed("systemctl is-active ripe-atlas-probe.service")
  '';
}
