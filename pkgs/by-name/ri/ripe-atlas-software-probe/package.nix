{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  pkg-config,
  perl,
  openssl,
  nixosTests,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ripe-atlas-software-probe";
  version = "5120";

  src = fetchFromGitHub {
    owner = "RIPE-NCC";
    repo = "ripe-atlas-software-probe";
    tag = finalAttrs.version;
    hash = "sha256-rjhLLeUj6US76/joRVBmYeqKsPVE5KzZGdE4eEilEKI=";
  };

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    perl
  ];

  buildInputs = [
    openssl
  ];

  # busybox' host tools are compiled with -Werror, which trips over the
  # format-security warnings injected by the default Nix hardening flags.
  hardeningDisable = [ "format" ];

  # The generic (software probe) runtime scripts hardcode /usr/bin/ssh; drop
  # the absolute path so ssh is resolved from the PATH the NixOS module sets
  # up. Every other external tool the generic scripts use is already invoked
  # by bare name.
  postPatch = ''
    substituteInPlace bin/arch/linux/linux-functions.sh \
      --replace-fail /usr/bin/ssh ssh
  '';

  # The upstream build system bakes absolute paths for mutable state
  # (/etc, /var, /run) into its scripts at configure time, while the
  # immutable program and data live under the Nix store prefix. Point the
  # mutable paths at their real FHS locations; the NixOS module
  # (services.ripe-atlas-probe) creates them at runtime.
  configureFlags = [
    "--sysconfdir=/etc"
    "--localstatedir=/var"
    "--runstatedir=/run"
    # A single user for both the main process and the measurement daemons: the
    # NixOS module runs everything as one user and grants CAP_NET_RAW ambiently,
    # rather than relying on upstream's setuid/setcap privilege separation
    # (which cannot work from the read-only store).
    "--with-user=ripe-atlas"
    "--with-measurement-user=ripe-atlas"
    "--with-group=ripe-atlas"
    "--with-install-mode=probe"
    "--disable-systemd"
    "--disable-chown"
    "--disable-setcap-install"
  ];

  enableParallelBuilding = true;

  # Suppress installation of the runtime state that lives outside the store:
  # the spool/runtime/config directory trees (ATLAS_*_DIRS, which would also be
  # setgid-chmod'd — fatal in the sandbox) and the default "mode" file
  # (atlas_sysconf_DATA, the only payload targeting /etc). With those blanked
  # the stock `make install` writes only to $out, so no DESTDIR staging is
  # needed; the NixOS module owns everything under /etc, /var and /run.
  installFlags = [
    "ATLAS_SPOOL_DIRS="
    "ATLAS_CONF_DIRS="
    "ATLAS_RUN_DIRS="
    "atlas_sysconf_DATA="
  ];

  passthru.tests = {
    inherit (nixosTests) ripe-atlas-probe;
  };

  meta = {
    description = "RIPE Atlas software probe: a distributed Internet measurement device";
    homepage = "https://atlas.ripe.net/";
    changelog = "https://github.com/RIPE-NCC/ripe-atlas-software-probe/blob/${finalAttrs.version}/CHANGES.rst";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ marcel ];
    platforms = lib.platforms.linux;
    mainProgram = "ripe-atlas";
  };
})
