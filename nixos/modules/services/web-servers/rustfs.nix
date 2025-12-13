{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.rustfs;
in
{
  meta.maintainers = with lib.maintainers; [
    marcel
  ];

  options.services.rustfs = {
    enable = lib.mkEnableOption "RustFS Object Storage Server";

    package = lib.mkPackageOption pkgs "rustfs" { };

    user = lib.mkOption {
      type = lib.types.str;
      default = "rustfs";
      description = "The user RustFS should run as.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "rustfs";
      description = "The group RustFS should run as.";
    };

    settings = lib.mkOption {
      default = { };
      description = ''
        Options for RustFS configuration. Refer to
        <TODO> for
        details on supported values.
      '';
      example = lib.literalExpression ''
        {
          RUSTFS_CONSOLE_ENABLE = "true";
          RUSTFS_VOLUMES = "/mnt/rustfs";
        }
      '';
      type = lib.types.submodule {
        freeformType = lib.types.attrsOf (
          lib.types.oneOf [
            lib.types.str
            lib.types.int
          ]
        );
        options = {
          RUSTFS_VOLUMES = lib.mkOption {
            type = lib.types.path;
            default = "/var/lib/rustfs";
            description = "The directory where RustFS stores it's data.";
          };
        };
      };
    };

    environmentFile = lib.mkOption {
      type = lib.types.str;
      description = "File to environment file containing secrets like RUSTFS_ACCESS_KEY or RUSTFS_SECRET_KEY.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd = {
      tmpfiles.rules = [
        "d '${cfg.settings.RUSTFS_VOLUMES}' - ${cfg.user} ${cfg.group} - -"
      ];

      # https://docs.rustfs.com/installation/linux/single-node-single-disk.html#_6-configure-system-service
      services.rustfs = {
        description = "RustFS Object Storage Server";
        documentation = [ "https://rustfs.com/docs/" ];

        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        wantedBy = [ "multi-user.target" ];

        environment = cfg.settings;

        serviceConfig = {
          Type = "notify";
          NotifyAccess = "main";
          User = cfg.user;
          Group = cfg.group;

          # TODO: verify that access and secret key is provided -> avoid usage of default credentials
          EnvironmentFile = cfg.environmentFile;
          ExecStart = lib.getExe cfg.package;

          LimitNOFILE = 1048576;
          LimitNPROC = 32768;
          TasksMax = "infinity";

          Restart = "always";
          RestartSec = "10s";

          OOMScoreAdjust = "-1000";
          SendSIGKILL = false;

          TimeoutStartSec = "30s";
          TimeoutStopSec = "30s";

          NoNewPrivileges = true;

          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectClock = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictSUIDSGID = true;
          RestrictRealtime = true;
        };
      };
    };

    users = {
      users.${cfg.user} = {
        isSystemUser = true;
        inherit (cfg) group;
      };
      groups.${cfg.group} = { };
    };
  };
}
