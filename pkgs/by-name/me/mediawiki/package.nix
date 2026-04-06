{
  lib,
  stdenvNoCC,
  fetchurl,
  nixosTests,
}:

stdenvNoCC.mkDerivation rec {
  pname = "mediawiki";
  version = "1.44.5";

  src = fetchurl {
    url = "https://releases.wikimedia.org/mediawiki/${lib.versions.majorMinor version}/mediawiki-${version}.tar.gz";
    hash = "sha256-PidNTU3WS+W6hsgfjaKsR+SZxTfQ+xftlsLQ98XaBGQ=";
  };

  patches = [
    # NixOS runs the update script on every start as we might need to run some migrations.
    # Normally this clears all active sessions, for usability we do not do that.
    ./keep-session-object-cache.diff
  ];

  postPatch = ''
    substituteInPlace includes/installer/CliInstaller.php \
      --replace-fail '$vars = Installer::getExistingLocalSettings();' '$vars = null;'
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/mediawiki
    cp -r * $out/share/mediawiki
    echo "<?php
      return require(getenv('MEDIAWIKI_CONFIG'));
    ?>" > $out/share/mediawiki/LocalSettings.php

    runHook postInstall
  '';

  passthru.tests = {
    inherit (nixosTests.mediawiki) mysql postgresql;
  };

  meta = {
    description = "Collaborative editing software that runs Wikipedia";
    license = lib.licenses.gpl2Plus;
    homepage = "https://www.mediawiki.org/";
    platforms = lib.platforms.all;
    teams = [ lib.teams.c3d2 ];
  };
}
