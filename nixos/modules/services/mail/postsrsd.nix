{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.services.postsrsd;
  runtimeDirectoryName = "postsrsd";
  runtimeDirectory = "/run/${runtimeDirectoryName}";
  # <<< TODO: follow RFC 42, need a libconfuse format first >>>
  configFile = pkgs.writeText "postsrsd.conf" ''
    secrets-file = "''${CREDENTIALS_DIRECTORY}/secrets-file"
    domains = { ${lib.concatStringsSep ", " (map (x: ''"${x}"'') cfg.domains)} }
    separator = "${cfg.separator}"
    socketmap = "unix:${runtimeDirectory}/socket"

    # Disable postsrsd's jailing in favor of confinement with systemd.
    unprivileged-user = ""
    chroot-dir = ""
  '';

in
{

  ###### interface

  options = {

    services.postsrsd = {

      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to enable the postsrsd SRS server for Postfix.";
      };

      secretsFile = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/postsrsd/postsrsd.secret";
        description = "Secret keys used for signing and verification";
      };

      domains = lib.mkOption {
        type = with lib.types; listOf str;
        description = "Local domain names that not need to be rewritten.";
      };

      separator = lib.mkOption {
        type = lib.types.enum [
          "-"
          "="
          "+"
        ];
        default = "=";
        description = "First separator character in generated addresses";
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "postsrsd";
        description = "User for the daemon";
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = "postsrsd";
        description = "Group for the daemon";
      };

    };

  };

  ###### implementation

  config = lib.mkIf cfg.enable {

    services.postsrsd.domains = lib.mkDefault [ config.networking.hostName ];

    users.users = lib.optionalAttrs (cfg.user == "postsrsd") {
      postsrsd = {
        group = cfg.group;
        uid = config.ids.uids.postsrsd;
      };
    };

    users.groups = lib.optionalAttrs (cfg.group == "postsrsd") {
      postsrsd.gid = config.ids.gids.postsrsd;
    };

    systemd.services.postsrsd-generate-secrets = {
      path = [ pkgs.coreutils ];
      script = ''
        if [ -e "${cfg.secretsFile}" ]; then
          echo "Secrets file exists. Nothing to do!"
        else
          echo "WARNING: secrets file not found, autogenerating!"
          DIR="$(dirname "${cfg.secretsFile}")"
          install -m 750 -o ${cfg.user} -g ${cfg.group} -d "$DIR"
          install -m 600 -o ${cfg.user} -g ${cfg.group} <(dd if=/dev/random bs=18 count=1 | base64) "${cfg.secretsFile}"
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
      };
    };

    systemd.services.postsrsd = {
      description = "PostSRSd SRS rewriting server";
      after = [
        "network.target"
        "postsrsd-generate-secrets.service"
      ];
      before = [ "postfix.service" ];
      wantedBy = [ "multi-user.target" ];
      requires = [ "postsrsd-generate-secrets.service" ];
      confinement.enable = true;

      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.postsrsd} -C ${configFile}";
        User = cfg.user;
        Group = cfg.group;
        PermissionsStartOnly = true;
        RuntimeDirectory = runtimeDirectoryName;
        LoadCredential = "secrets-file:${cfg.secretsFile}";
      };
    };

  };
}
