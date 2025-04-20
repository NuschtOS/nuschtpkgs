{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.services.prometheus.exporters.pcm;
in
{
  # requires more permission than "pcm-exporter" user
  user = "root";
  # application can only listen on ipv6 addresses, "0.0.0.0" is a v4 address
  listenAddress = "::";
  port = 9738;

  serviceOpts = {
    serviceConfig = {
      ExecStart = ''
        ${lib.getExe' pkgs.pcm "pcm-sensor-server"} \
          -l ${cfg.listenAddress} \
          -p ${builtins.toString cfg.port} \
          ${lib.concatStringsSep " \\\n  " cfg.extraFlags}
      '';
      LimitNOFILE = "1000000";
      AmbientCapabilities = [
        "CAP_SYS_ADMIN"
        "CAP_SYS_RAWIO"
      ];
      CapabilityBoundingSet = [
        "CAP_SYS_ADMIN"
        "CAP_SYS_RAWIO"
      ];
      DevicePolicy = "closed";
      DeviceAllow = lib.mkForce [
        "char-cpu/msr rw"
        "char-mem r"
      ];
      PrivateDevices = false;
      ProtectKernelTunables = lib.mkForce false;
      RestartSec = "3s";
    };
  };
}
