{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.kresd_6;
  manager = pkgs.knot-resolver-manager;

  # Convert systemd-style address specification to kresd config line(s).
  # On Nix level we don't attempt to precisely validate the address specifications.
  # The optional IPv6 scope spec comes *after* port, perhaps surprisingly.
  mkListen =
    kind: addr:
    let
      al_v4 = builtins.match "([0-9.]+):([0-9]+)($)" addr;
      al_v6 = builtins.match "\\[(.+)]:([0-9]+)(%.*|$)" addr;
      al_portOnly = builtins.match "(^)([0-9]+)" addr;
      al =
        lib.findFirst (a: a != null) (throw "services.kresd.*: incorrect address specification '${addr}'")
          [
            al_v4
            al_v6
            al_portOnly
          ];
      port = lib.elemAt al 1;
      addrSpec =
        if al_portOnly == null then "'${lib.head al}${lib.elemAt al 2}'" else "{'::', '0.0.0.0'}";
    in
    # freebind is set for compatibility with earlier kresd services;
    # it could be configurable, for example.
    ''
      net.listen(${addrSpec}, ${port}, { kind = '${kind}', freebind = true })
    '';

    json-oneline = pkgs.writeTextFile {
      name = "kresd-oneline.json";
      text = builtins.toJSON cfg.settings;
    };
    # - use jq to get a pretty JSON
    # - then validate it, so that most errors get found during OS build (not activation)
    json = pkgs.runCommandLocal "kresd.json" {} ''
      '${pkgs.jq}/bin/jq' < '${json-oneline}' > "$out"
      '${manager}/bin/kresctl' validate --no-strict "$out"
    '';
    #*/

  # lua mode is somewhat broken
  configFile = # if cfg.settings == { }
    # then pkgs.writeText "kresd.lua" (
    #   ""
    #   + lib.concatMapStrings (mkListen "dns") cfg.listenPlain # NOTE: doesn't work for some reason...
    #   + lib.concatMapStrings (mkListen "tls") cfg.listenTLS
    #   + lib.concatMapStrings (mkListen "doh2") cfg.listenDoH
    #   + cfg.extraConfig
    # )
    # else
    pkgs.runCommandLocal "kresd.lua" {} ''
      ${manager}/bin/kresctl convert --no-strict '${json}' "$out"
    '';
in
{
  meta.maintainers = [
    lib.maintainers.vcunat # upstream developer
  ];

  imports = [
    (lib.mkChangedOptionModule [ "services" "kresd_6" "interfaces" ] [ "services" "kresd_6" "listenPlain" ]
      (
        config:
        let
          value = lib.getAttrFromPath [ "services" "kresd_6" "interfaces" ] config;
        in
        map (iface: if lib.elem ":" (lib.stringToCharacters iface) then "[${iface}]:53" else "${iface}:53") # Syntax depends on being IPv6 or IPv4.
          value
      )
    )
    (lib.mkRemovedOptionModule [ "services" "kresd_6" "cacheDir" ] "Please use (bind-)mounting instead.")
  ];

  options.services.kresd_6 = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to enable knot-resolver domain name server.
        DNSSEC validation is turned on by default.
      '';
    };
    package = lib.mkPackageOption pkgs "knot-resolver" {
      example = "knot-resolver.override { extraFeatures = true; }";
    };
    settings = lib.mkOption {
      type = lib.types.submodule { # TODO: avoid regeneration of docs on config changes
        freeformType = (pkgs.formats.yaml {}).type;
      };
      default = { };
      description = ''
        Nix-based (RFC 42) configuration for Knot Resolver 6.x.
        FIXME many issues, e.g.:
         - old listen{Plain,TLS,DoH} config gets silently ignored
        For configuration reference (described as YAML) see
        <https://www.knot-resolver.cz/documentation/latest/config-overview.html>
      '';
    };
    # extraConfig = lib.mkOption {
    #   type = lib.types.lines;
    #   default = "";
    #   description = ''
    #     Extra lines to be added verbatim to the generated configuration file.
    #     See upstream documentation <https://www.knot-resolver.cz/documentation/stable/config-overview.html> for more details.
    #   '';
    # };
    listenPlain = lib.mkOption {
      type = with lib.types; listOf str;
      default = [
        "[::1]:53"
        "127.0.0.1:53"
      ];
      example = [ "53" ];
      description = ''
        What addresses and ports the server should listen on.
        For detailed syntax see ListenStream in {manpage}`systemd.socket(5)`.
      '';
    };
    listenTLS = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      example = [
        "198.51.100.1:853"
        "[2001:db8::1]:853"
        "853"
      ];
      description = ''
        Addresses and ports on which kresd should provide DNS over TLS (see RFC 7858).
        For detailed syntax see ListenStream in {manpage}`systemd.socket(5)`.
      '';
    };
    listenDoH = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      example = [
        "198.51.100.1:443"
        "[2001:db8::1]:443"
        "443"
      ];
      description = ''
        Addresses and ports on which kresd should provide DNS over HTTPS/2 (see RFC 8484).
        For detailed syntax see ListenStream in {manpage}`systemd.socket(5)`.
      '';
    };
    # TODO: option to create tmpfs for cache?  (It's bad for disk on a busy resolver.)
  };

  config = lib.mkIf cfg.enable {
    environment = {
      etc = {
        "knot-resolver/kresd.lua" = {
          mode = "755";
          source = configFile;
          user = "knot-resolver";
        };
        "knot-resolver/kresd.json" = {
          # NOTE: knot-resolver really, really want to have that config file for it writable...
          source = json;
          mode = "755";
          user = "knot-resolver";
        };
      };
      systemPackages = [
        # Wrapping because the by default the config changes the location of the management socket.
        (pkgs.runCommandLocal "knot-resolver-cmds"
          { nativeBuildInputs = [ pkgs.makeWrapper ]; }
          ''
            makeWrapper '${manager}/bin/kresctl' "$out/bin/kresctl" \
              --add-flags --config=/etc/knot-resolver/kresd.json
          '')
      ];
    };

    networking.resolvconf.useLocalResolver = lib.mkDefault true;

    systemd.packages = [ cfg.package ]; # the units are patched inside the package a bit

    #FIXME: ?conditionalize, reuse upstream unit & clean up, etc.
    systemd.services.knot-resolver = {
      wantedBy = [ "multi-user.target" ];
      path = [ (lib.getBin cfg.package) ];
      serviceConfig = {
        ExecStart = [ "" "${manager}/bin/knot-resolver --config=/etc/knot-resolver/kresd.json" ];
        Environment = "KRES_LOGGING_TARGET=syslog";
        # Actually, it's unclear whether reloading will really be useful,
        # but why not fix it anyway.  (We'd need to recognize config-only changes.)
        ExecReload = [ "" "${manager}/bin/kresctl reload --config=/etc/knot-resolver/kresd.json" ];

        Type = "notify";
        TimeoutStartSec = "10s";
        KillSignal = "SIGINT";
        Restart = "always";
        WorkingDirectory = "/run/knot-resolver";
        User = "knot-resolver";
        Group = "knot-resolver";
        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" "CAP_SETPCAP" ];
        AmbientCapabilities   = [ "CAP_NET_BIND_SERVICE" "CAP_SETPCAP" ];
        RuntimeDirectory = "knot-resolver";
        RuntimeDirectoryMode = "0770";
        StateDirectory = "knot-resolver";
        StateDirectoryMode = "0770";
        CacheDirectory = "knot-resolver";
        CacheDirectoryMode = "0770";
      };
      # keep working across rebuilds
      stopIfChanged = false;
    };

    users = {
      groups.knot-resolver = { };
      users.knot-resolver = {
        isSystemUser = true;
        group = "knot-resolver";
        description = "Knot-resolver daemon user";
      };
    };
  };
}
