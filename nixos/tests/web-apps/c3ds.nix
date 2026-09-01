{ lib, ... }:

{
  name = "c3ds";
  meta.maintainers = with lib.maintainers; [ marcel ];

  containers = {
    server = { ... }: {
      networking.extraHosts = ''
        127.0.0.1 signage.local
      '';

      services.c3ds = {
        enable = true;
        nginx.domain = "signage.local";
        settings.dayZero = "2026-12-28T00:00:00";
      };
    };
  };

  testScript = ''
    start_all()

    server.wait_for_unit("c3ds.service")

    # The display page renders through the full stack: nginx -> daphne ->
    # Django (PostgreSQL, vite manifest, offline-compressed assets)
    server.wait_until_succeeds("curl -q --fail http://signage.local/d/test/")

    # A websocket handshake on the display channel (nginx /ws/ proxy ->
    # daphne/channels). AllowedHostsOriginValidator requires an Origin header
    # matching ALLOWED_HOSTS, so send one.
    server.wait_until_succeeds('curl -is -H "Origin: http://signage.local" -H "Upgrade: websocket" -H "Connection: Upgrade" -H "Sec-WebSocket-Key: x3JJHMbDL1EzLkh9GBhXDw==" -H "Sec-WebSocket-Version: 13" http://signage.local/ws/display/test/ | head -n1 | grep -q "101 Switching Protocols"')

    # Django admin login page
    server.wait_until_succeeds("curl -qfL http://signage.local/admin/")

    # The vite manifest is served from the build-time-collected static root
    server.wait_until_succeeds("curl -q --fail http://signage.local/static/.vite/manifest.json")

    # The management command wrapper (migrations ran in preStart)
    server.succeed("c3ds-manage showmigrations")

    server.log(server.succeed("systemd-analyze security c3ds.service"))
  '';
}
