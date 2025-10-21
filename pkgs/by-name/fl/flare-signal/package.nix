{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchFromGitLab,
  runCommand,
  xorg,
  meson,
  ninja,
  pkg-config,
  gst_all_1,
  protobuf,
  libspelling,
  libsecret,
  libadwaita,
  gtksourceview5,
  rustPackages_1_88,
  appstream,
  blueprint-compiler,
  desktop-file-utils,
  wrapGAppsHook4,
}:

let
  inherit (rustPackages_1_88)
    cargo
    rustPlatform
    rustc
    ;
  presage = fetchFromGitHub {
    owner = "whisperfish";
    repo = "presage";
    # match with commit from Cargo.toml
    rev = "ed011688fc8d9c0ee07c3d44743c138c1fa4dfda";
    hash = "sha256-NTSxSOAmA9HOH52GPwl6pL0MQly+NTfJDk7k7TUP9II=";
  };
in

stdenv.mkDerivation (finalAttrs: {
  pname = "flare";
  # NOTE: also update presage commit
  version = "0.17.2";

  src = fetchFromGitLab {
    domain = "gitlab.com";
    owner = "schmiddi-on-mobile";
    repo = "flare";
    tag = finalAttrs.version;
    hash = "sha256-Nezg+fNC29blGhyetJqs9l6/IL08b7tHn+D3pzKj26I=";
  };

  cargoDeps =
    let
      cargoDeps = rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname version src;
        hash = "sha256-Y6jY588axEcqv0WN6Fcm8Kd5yd2JXvKwMd8h1L6J9TE=";
      };
    in
    runCommand "${finalAttrs.pname}-${finalAttrs.version}-vendor-patched" { inherit cargoDeps; } # bash
      ''
        mkdir $out
        find $cargoDeps -maxdepth 1 -exec sh -c "ln -s {} $out/\$(basename {})" \;
        rm $out/presage-store-sqlite-*
        cp -r $cargoDeps/presage-store-sqlite-* $out
        chmod +w $out/presage-store-sqlite-*
        cp -r ${presage}/.sqlx $out/presage-store-sqlite-*
      '';

  nativeBuildInputs = [
    appstream # for appstream-util
    blueprint-compiler
    desktop-file-utils # for update-desktop-database
    meson
    ninja
    pkg-config
    wrapGAppsHook4
    rustPlatform.cargoSetupHook
    cargo
    rustc
  ];

  buildInputs = [
    gtksourceview5
    libadwaita
    libsecret
    libspelling
    protobuf

    # To reproduce audio messages
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
  ];

  meta = {
    changelog = "https://gitlab.com/schmiddi-on-mobile/flare/-/blob/${finalAttrs.src.tag}/CHANGELOG.md";
    description = "Unofficial Signal GTK client";
    mainProgram = "flare";
    homepage = "https://gitlab.com/schmiddi-on-mobile/flare";
    license = lib.licenses.agpl3Plus;
    maintainers = with lib.maintainers; [ dotlambda ];
    platforms = lib.platforms.linux;
  };
})
