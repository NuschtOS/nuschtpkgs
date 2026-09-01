{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.c3ds;

  # A python environment bundling c3ds (and all of its dependencies) together
  # with daphne, so that daphne's console script can `import c3ds.asgi`.
  # (The plain daphne package alone would not see the app's dependencies.)
  pythonEnv = cfg.package.pythonPackages.python.buildEnv.override {
    extraLibs = with cfg.package.pythonPackages; [
      (toPythonModule cfg.package)
      daphne
    ];
  };

  databaseUrl =
    if cfg.settings.database.url != null then
      cfg.settings.database.url
    else
      # local PostgreSQL over the Unix socket, peer authentication.
      # The socket directory goes in `?host=` (a path cannot appear in the URL
      # authority); django-environ puts it in OPTIONS, which Django's postgres
      # backend honours via setdefault.
      "postgres://${cfg.settings.database.user}@/${cfg.settings.database.name}?host=${cfg.settings.database.host}";

  settingsOverrideDir = pkgs.runCommand "c3ds-django-settings-local" { } ''
    mkdir -p $out
    cat > $out/django_settings_local.py <<'EOF'
    from c3ds.settings.production import *  # noqa: F401,F403
    SOCIAL_AUTH_OIDC_GROUPS_CLAIM = ${builtins.toJSON cfg.settings.sso.groupsClaim}
    SOCIAL_AUTH_OIDC_ALLOW_GROUPS = ${builtins.toJSON cfg.settings.sso.allowGroups}
    ${cfg.settings.extraConfig}
    EOF
  '';

  commonEnvironment = {
    C3DS_DATA_DIR = cfg.settings.filesystem.data;
    C3DS_STATIC_ROOT = cfg.package.static;
    C3DS_DATABASE = databaseUrl;
    C3DS_ALLOWED_HOSTS = lib.concatStringsSep "," cfg.settings.allowedHosts;
    C3DS_REDIS = "unix://${config.services.redis.servers.c3ds.unixSocket}?db=0";
    DJANGO_SETTINGS_MODULE = "django_settings_local";
    PYTHONPATH = "${settingsOverrideDir}";
  }
  // lib.optionalAttrs (cfg.settings.dayZero != null) {
    C3DS_DAY_ZERO = cfg.settings.dayZero;
  }
  // lib.optionalAttrs (cfg.settings.admins != [ ]) {
    C3DS_ADMINS = lib.concatStringsSep "," cfg.settings.admins;
  }
  // lib.optionalAttrs (cfg.settings.delayedReloadThreshold != null) {
    C3DS_DELAYED_RELOAD_THRESHOLD = "${lib.toString cfg.settings.delayedReloadThreshold}";
  };

  # Run this as root (e.g. via sudo): it reads the environment files and then
  # drops to cfg.user with runuser. Service units that already run as cfg.user
  # should invoke the `c3ds` entry point directly instead.
  c3dsManageWrapper = pkgs.writeShellApplication {
    name = "c3ds-manage";
    runtimeInputs = with pkgs; [
      util-linux
    ];
    text = ''
      cd ${cfg.settings.filesystem.data}
      set -a
      ${lib.concatMapStringsSep "\n" (file: ''
        . ${lib.escapeShellArg file}
      '') cfg.environmentFiles}
      set +a
      ${lib.concatMapAttrsStringSep "\n" (n: v: "export ${n}=${lib.escapeShellArg v}") commonEnvironment}
      exec runuser ${
        lib.cli.toCommandLineShellGNU { } {
          inherit (cfg) user;
          preserve-environment = true;
        }
      } -- ${lib.getExe' pythonEnv "c3ds"} "$@"
    '';
    excludeShellChecks = [
      # Not following: environment files are provided by the user
      "SC1091"
    ];
  };
in

{
  meta.maintainers = with lib.maintainers; [ marcel ];

  options.services.c3ds = {
    enable = lib.mkEnableOption "c3ds, a digital signage application for c3 events";

    package = lib.mkPackageOption pkgs "c3ds" { };

    user = lib.mkOption {
      type = lib.types.str;
      default = "c3ds";
      description = "User under which c3ds should run.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "c3ds";
      description = "Group under which c3ds should run.";
    };

    manage = lib.mkOption {
      type = lib.types.package;
      description = "The `c3ds-manage` wrapper that sources environment files and runs c3ds as the configured user.";
      apply = v: v;
    };

    environmentFiles = lib.mkOption {
      description = ''
        Environment files that allow passing secret configuration values.

        Each line must follow the `C3DS_SECTION_KEY=value` pattern, e.g.
        `SOCIAL_AUTH_OIDC_KEY=…`, `C3DS_EMAIL_PASSWORD=…` or
        `DJANGO_SECRET_KEY=…`.
      '';
      type = lib.types.listOf lib.types.path;
      default = [ ];
      example = [ "/run/agenix/c3ds" ];
    };

    daphne.extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "--websocket_timeout=-1" # displays keep their websocket open indefinitely
      ];
      example = [ "--verbosity=2" ];
      description = ''
        Extra arguments to pass to daphne, the ASGI server.

        See `daphne --help` for all options.
      '';
      apply = lib.escapeShellArgs;
    };

    nginx = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        example = false;
        description = ''
          Whether to set up an nginx virtual host serving the static files
          and proxying HTTP and websockets to daphne.
        '';
      };

      domain = lib.mkOption {
        type = lib.types.str;
        example = "signage.example.com";
        description = ''
          The domain name under which to set up the virtual host.
        '';
      };
    };

    database.createLocally = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = ''
        Whether to automatically create the database and user on the local
        PostgreSQL instance.
      '';
    };

    settings = lib.mkOption {
      type = lib.types.submodule {
        options = {
          filesystem = {
            data = lib.mkOption {
              type = lib.types.path;
              default = "/var/lib/c3ds";
              description = ''
                Base directory for the state: SQLite database (if used),
                the generated `.secret` file and the media files.

                Keep this directory across upgrades: `.secret` is the
                session/secret key source.
              '';
            };
          };

          allowedHosts = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              cfg.nginx.domain
              "localhost"
            ];
            defaultText = lib.literalExpression "[ config.services.c3ds.nginx.domain \"localhost\" ]";
            example = [
              "signage.example.com"
              "192.168.1.100"
            ];
            description = ''
              Hosts to allow (the `C3DS_ALLOWED_HOSTS` environment
              variable, comma-separated).
            '';
          };

          database = {
            url = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "postgres://user:password@db.example.com:5432/c3ds";
              description = ''
                Explicit database URL (`C3DS_DATABASE`).

                When `null` (the default), the URL is derived from the
                other `database.*` options (PostgreSQL over the local Unix
                socket with peer authentication, or SQLite in the data
                directory).
              '';
            };

            host = lib.mkOption {
              type = lib.types.path;
              default = "/run/postgresql";
              description = ''
                PostgreSQL host or Unix socket directory.
              '';
            };
            # NOTE: only PostgreSQL is supported by this module; SQLite is
            # the application's zero-config fallback, but unsuitable for a
            # deployed service.

            name = lib.mkOption {
              type = lib.types.str;
              default = "c3ds";
              description = ''
                Name of the database.
              '';
            };

            user = lib.mkOption {
              type = lib.types.str;
              default = "c3ds";
              description = ''
                Name of the database user.

                For the local Unix socket, peer authentication requires
                this to match `services.c3ds.user`.
              '';
            };
          };

          dayZero = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "2026-12-28T00:00:00";
            description = ''
              Event day zero as ISO datetime (`C3DS_DAY_ZERO`).
            '';
          };

          admins = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            example = [ "admin@example.com" ];
            description = ''
              Administrator emails (`C3DS_ADMINS`, comma-separated), used
              for error mail.
            '';
          };

          delayedReloadThreshold = lib.mkOption {
            type = lib.types.nullOr lib.types.ints.positive;
            default = null;
            example = 10;
            description = ''
              Number of displays from which on a reload is broadcast as
              *delayed* (`C3DS_DELAYED_RELOAD_THRESHOLD`, application
              default 10). A delayed reload makes each display wait a
              random moment (up to 20 seconds) before reloading, so that a
              large installation does not reconnect all at once.

              This is a display count, not a duration.
            '';
          };

          sso = {
            allowGroups = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              example = [ "c3ds-admins" ];
              description = ''
                OIDC groups whose members may sign in
                (`SOCIAL_AUTH_OIDC_ALLOW_GROUPS`).

                ::: {.warning}
                While this is empty the group check is skipped and *every*
                account that can authenticate at the identity provider is
                allowed in — and the login pipeline grants Django superuser
                to every account it creates. Set this whenever the identity
                provider is reachable by more than the operators.
                :::
              '';
            };

            groupsClaim = lib.mkOption {
              type = lib.types.str;
              default = "groups";
              example = "roles";
              description = ''
                Claim in the userinfo response or id_token carrying the
                group list (`SOCIAL_AUTH_OIDC_GROUPS_CLAIM`).
              '';
            };
          };

          extraConfig = lib.mkOption {
            type = lib.types.lines;
            default = "";
            example = ''
              SOCIAL_AUTH_OIDC_OIDC_ENDPOINT = "https://sso.example.com/realms/c3d2"
              EMAIL_SUBJECT_PREFIX = "[c3ds prod] "
            '';
            description = ''
              Additional Python code to inject into the Django settings
              module, after importing ``c3ds.settings.production``.

              Use this to override any Django setting (e.g. authentication
              backends, email configuration, third-party app settings) that
              is not covered by a dedicated option.
            '';
          };
        };
      };
      default = { };
      description = ''
        c3ds configuration as a Nix attribute set, passed to the service as
        `C3DS_*` environment variables.

        Further environment variables (SSO credentials, email settings, …)
        can be provided via `services.c3ds.environmentFiles`.

        Arbitrary Django settings can be overridden by injecting Python
        code via `settings.extraConfig` (executed after importing the
        production settings).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ c3dsManageWrapper ];

    services.c3ds.manage = c3dsManageWrapper;

    services = {
      nginx = lib.mkIf cfg.nginx.enable {
        enable = true;
        upstreams.c3ds.servers."unix:/run/c3ds/c3ds.sock" = { };
        virtualHosts.${cfg.nginx.domain} = {
          locations = {
            "/" = {
              recommendedProxySettings = lib.mkDefault true;
              proxyPass = "http://c3ds";
            };
            "^~ /ws/" = {
              recommendedProxySettings = lib.mkDefault true;
              proxyPass = "http://c3ds";
              proxyWebsockets = true;
              extraConfig = ''
                # long-lived display websockets
                proxy_read_timeout 3600s;
              '';
            };
            "/static/" = {
              alias = "${cfg.package.static}/";
              extraConfig = ''
                access_log off;
                more_set_headers Cache-Control "public";
                expires 365d;
              '';
            };
            "/media/" = {
              alias = "${cfg.settings.filesystem.data}/media/";
              extraConfig = ''
                access_log off;
              '';
            };
          };
        };
      };

      postgresql = lib.mkIf cfg.database.createLocally {
        enable = true;
        ensureUsers = [
          {
            name = cfg.settings.database.user;
            ensureDBOwnership = true;
          }
        ];
        ensureDatabases = [ cfg.settings.database.name ];
      };

      redis.servers.c3ds.enable = true;
    };

    systemd.services =
      let
        commonUnitConfig = {
          environment = commonEnvironment;
          serviceConfig = {
            User = cfg.user;
            Group = cfg.group;
            EnvironmentFile = cfg.environmentFiles;
            StateDirectory = "c3ds";
            StateDirectoryMode = "0750";
            RuntimeDirectory = "c3ds";
            WorkingDirectory = cfg.settings.filesystem.data;
            SupplementaryGroups = [
              "redis-c3ds"
            ];
            # group-writable, so that nginx can connect to the unix socket
            UMask = "0007";
            AmbientCapabilities = "";
            CapabilityBoundingSet = [ "" ];
            DevicePolicy = "closed";
            LockPersonality = true;
            MemoryDenyWriteExecute = true;
            NoNewPrivileges = true;
            PrivateDevices = true;
            PrivateTmp = true;
            ProcSubset = "pid";
            ProtectControlGroups = true;
            ProtectHome = true;
            ProtectHostname = true;
            ProtectKernelLogs = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;
            ProtectProc = "invisible";
            ProtectSystem = "strict";
            RemoveIPC = true;
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
              # the application chowns its generated .secret file
              "@chown"
            ];
          };
        };
      in
      {
        c3ds = lib.recursiveUpdate commonUnitConfig {
          description = "c3ds digital signage (ASGI via daphne)";
          after = [
            "network.target"
            "redis-c3ds.service"
            "postgresql.target"
          ];
          wantedBy = [ "multi-user.target" ];
          # migrate is idempotent and a no-op once everything is applied, so run
          # it unconditionally instead of gating on a stored version: a version
          # string that is not bumped would silently skip new migrations.
          # Called directly rather than through c3ds-manage, which needs root
          # (it sources the environment files and drops privileges via runuser);
          # systemd has already applied `environment` and `EnvironmentFile` here.
          preStart = "${lib.getExe' pythonEnv "c3ds"} migrate";
          serviceConfig = {
            ExecStart = ''
              ${lib.getExe' pythonEnv "daphne"} \
                -u /run/c3ds/c3ds.sock \
                ${cfg.daphne.extraArgs} \
                c3ds.asgi:application
            '';
            Restart = "on-failure";
          };
        };

        nginx.serviceConfig.SupplementaryGroups = lib.mkIf cfg.nginx.enable [ cfg.group ];
      };

    users = {
      groups.${cfg.group} = { };
      users.${cfg.user} = {
        extraGroups = [
          config.services.redis.servers.c3ds.group
        ];
        isSystemUser = true;
        inherit (cfg) group;
      };
    };
  };
}
