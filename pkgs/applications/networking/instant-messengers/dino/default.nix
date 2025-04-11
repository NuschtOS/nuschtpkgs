{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  vala,
  ninja,
  wrapGAppsHook4,
  pkg-config,
  gettext,
  gobject-introspection,
  glib,
  gdk-pixbuf,
  gtk4,
  glib-networking,
  gupnp-igd,
  gupnp_1_6,
  libadwaita,
  libcanberra,
  libnotify,
  libsoup_3,
  libgee,
  libomemo-c,
  libgcrypt,
  meson,
  sqlite,
  gpgme,
  qrencode,
  icu,
  srtp,
  libnice,
  gnutls,
  gstreamer,
  gst-plugins-base,
  gst-plugins-good,
  gst-plugins-bad,
  gst-vaapi,
  webrtc-audio-processing_1,
}:

let
  # https://github.com/NixOS/nixpkgs/pull/395063
  libnice' =
    (libnice.override {
      gupnp-igd =
        (gupnp-igd.override {
          gupnp = gupnp_1_6;
        }).overrideAttrs
          (_: rec {
            version = "1.6.0";
            src = fetchurl {
              url = "mirror://gnome/sources/gupnp-igd/${lib.versions.majorMinor version}/gupnp-igd-${version}.tar.xz";
              hash = "sha256-QJmXgzmrIhJtSWjyozK20JT8RMeHl4YHgfH8LxF3G3Q=";
            };
          });
    }).overrideAttrs
      (oldAttrs: {
        postPatch =
          oldAttrs.postPatch or ""
          + ''
            substituteInPlace meson.build \
              --replace-fail "gupnp-igd-1.0" "gupnp-igd-1.6"
          '';
      });
in
stdenv.mkDerivation (finalAttrs: {
  pname = "dino";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "dino";
    repo = "dino";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Y3MGKpfhjmqnIvmt4mXnkmpjF/riXPDXyUiSrsceY6o=";
  };

  postPatch = ''
    echo ${finalAttrs.version} > VERSION
  '';

  nativeBuildInputs = [
    vala
    meson
    ninja
    pkg-config
    wrapGAppsHook4
    gettext
    gobject-introspection
  ];

  buildInputs = [
    qrencode
    glib
    glib-networking # required for TLS support
    libadwaita
    libgee
    sqlite
    gdk-pixbuf
    gtk4
    libnotify
    gpgme
    libgcrypt
    libsoup_3
    icu
    libcanberra
    libomemo-c
    srtp
    libnice'
    gnutls
    gstreamer
    gst-plugins-base
    gst-plugins-good # contains rtpbin, required for VP9
    gst-plugins-bad # required for H264, MSDK
    gst-vaapi # required for VAAPI
    webrtc-audio-processing_1
  ];

  mesonFlags = [
    "-Dplugin-notification-sound=enabled"
    "-Dplugin-rtp-h264=enabled"
    "-Dplugin-rtp-msdk=enabled"
    "-Dplugin-rtp-vaapi=enabled"
    "-Dplugin-rtp-vp9=enabled"
  ];

  # Undefined symbols for architecture arm64: "_gpg_strerror"
  NIX_LDFLAGS = lib.optionalString stdenv.hostPlatform.isDarwin "-lgpg-error";

  # Dino looks for plugins with a .so filename extension, even on macOS where
  # .dylib is appropriate, and despite the fact that it builds said plugins with
  # that as their filename extension
  #
  # Therefore, on macOS rename all of the plugins to use correct names that Dino
  # will load
  #
  # See https://github.com/dino/dino/wiki/macOS
  postFixup = lib.optionalString (stdenv.hostPlatform.isDarwin) ''
    cd "$out/lib/dino/plugins/"
    for f in *.dylib; do
      mv "$f" "$(basename "$f" .dylib).so"
    done
  '';

  meta = with lib; {
    description = "Modern Jabber/XMPP Client using GTK/Vala";
    mainProgram = "dino";
    homepage = "https://github.com/dino/dino";
    license = licenses.gpl3Plus;
    platforms = platforms.linux ++ platforms.darwin;
    maintainers = with maintainers; [
      qyliss
      tomfitzhenry
    ];
  };
})
