{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.ripe-atlas-probe;

  user = "ripe-atlas";
  group = "ripe-atlas";

  sysconfDir = "/etc/ripe-atlas";
  spoolDir = "/var/spool/ripe-atlas";

  renderValue = v: if lib.isBool v then (if v then "yes" else "no") else toString v;
  configTxt = pkgs.writeText "ripe-atlas-config.txt" (
    lib.concatStrings (lib.mapAttrsToList (name: value: "${name}=${renderValue value}\n") cfg.settings)
  );

  # The spool tree the probe expects to exist, mirroring the run.conf tmpfiles
  # shipped by upstream. These hold persistent state, so they live under
  # /var/spool rather than a systemd RuntimeDirectory.
  spoolSubdirs = [
    "data"
    "data/new"
    "data/oneoff"
    "data/out"
    "data/out/ooq"
    "data/out/ooq10"
    "crons"
    "crons/main"
  ]
  ++ map (n: "crons/${toString n}") (lib.range 2 20);
in
{
  options.services.ripe-atlas-probe = {
    enable = lib.mkEnableOption "the RIPE Atlas software probe, a distributed Internet measurement device";

    package = lib.mkPackageOption pkgs "ripe-atlas-software-probe" { };

    mode = lib.mkOption {
      type = lib.types.enum [
        "prod"
        "test"
        "dev"
      ];
      default = "prod";
      description = ''
        Which RIPE Atlas registration servers the probe talks to. Regular
        probes use `prod`; the others target RIPE's testing infrastructure.
      '';
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.oneOf [
          lib.types.str
          lib.types.int
          lib.types.bool
        ]
      );
      default = { };
      example = {
        TELNETD_PORT = 2023;
        HTTP_POST_PORT = 8080;
        RXTXRPT = true;
      };
      description = ''
        Options written to {file}`${sysconfDir}/config.txt`. Booleans are
        rendered as `yes`/`no`. See the RIPE Atlas software probe documentation
        for the available keys.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${user} = {
      isSystemUser = true;
      inherit group;
      home = spoolDir;
      description = "RIPE Atlas probe";
    };
    users.groups.${group} = { };

    systemd.tmpfiles.rules = [
      "d ${spoolDir} 2775 ${user} ${group} -"
    ]
    ++ map (d: "d ${spoolDir}/${d} 2775 ${user} ${group} -") spoolSubdirs;

    systemd.services.ripe-atlas-probe = {
      description = "RIPE Atlas probe";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network-online.target"
        "syslog.target"
      ];
      wants = [ "network-online.target" ];

      path = [
        cfg.package
        pkgs.openssh
        pkgs.iproute2
        pkgs.nettools
        pkgs.procps
        pkgs.coreutils
        pkgs.gnused
        pkgs.gnugrep
      ];

      # The probe reads its registration mode and runtime options from mutable
      # files under ${sysconfDir}. Seed them from the module configuration on
      # every start, leaving the generated probe key and controller state
      # untouched.
      preStart = ''
        install -m 0644 ${pkgs.writeText "ripe-atlas-mode" cfg.mode} ${sysconfDir}/mode
        install -m 0644 ${configTxt} ${sysconfDir}/config.txt
      '';

      serviceConfig = {
        ExecStart = lib.getExe cfg.package;
        Restart = "always";
        RestartSec = 5;
        TimeoutStopSec = 60;

        User = user;
        Group = group;
        WorkingDirectory = spoolDir;
        Environment = [ "HOME=${spoolDir}" ];

        ConfigurationDirectory = "ripe-atlas";
        ConfigurationDirectoryMode = "0750";
        RuntimeDirectory = [
          "ripe-atlas"
          "ripe-atlas/pids"
          "ripe-atlas/status"
        ];
        RuntimeDirectoryPreserve = true;

        # Raw sockets are needed for the ping/traceroute measurements. With no
        # privilege separation in the generic build the measurement daemons run
        # as this service's user, so the capability is granted ambiently.
        AmbientCapabilities = [ "CAP_NET_RAW" ];
        CapabilityBoundingSet = [ "CAP_NET_RAW" ];

        # Hardening
        NoNewPrivileges = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        # /etc/ripe-atlas is already writable via ConfigurationDirectory; the
        # spool tree lives outside any systemd-managed directory, so grant it
        # explicitly.
        ReadWritePaths = [ spoolDir ];
        PrivateTmp = true;
        DevicePolicy = "closed";
        KeyringMode = "private";
        RemoveIPC = true;
        RestrictNamespaces = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        ProtectControlGroups = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
      };
    };
  };

  meta.maintainers = with lib.maintainers; [ marcel ];
}
