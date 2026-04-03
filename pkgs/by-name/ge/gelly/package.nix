{
  lib,
  rustPackages_1_94,
  fetchFromGitHub,
  pkg-config,
  wrapGAppsHook4,
  libadwaita,
  openssl,
  dbus,
  libseccomp,
  gst_all_1,
  libglycin,
  glycin-loaders,
}:

let
  inherit (rustPackages_1_94) rustPlatform;
in
rustPlatform.buildRustPackage rec {
  pname = "gelly";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "Fingel";
    repo = "gelly";
    rev = "v${version}";
    hash = "sha256-9KkFTJhTpbWXVMQWmRv88cTUEddmAFCKPSyM6Jy3YZI=";
  };

  cargoHash = "sha256-5R91avA11B/mYdo5UWvrRYjJMK3K5comOXiKCFM8KD4=";

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook4
  ];

  buildInputs = [
    libadwaita
    openssl
    dbus
    libseccomp
  ]
  ++ (with gst_all_1; [
    gst-plugins-bad
    gst-plugins-base
    gst-plugins-good
    gst-plugins-ugly
    gst-plugins-rs
    gst-libav
  ]);

  # https://github.com/NixOS/nixpkgs/blob/b7da1723356bf97098dc5fd2e86d9a4db43cddaa/pkgs/by-name/lo/loupe/package.nix#L67-L81
  preConfigure = ''
    # Dirty approach to add patches after cargoSetupPostUnpackHook
    # We should eventually use a cargo vendor patch hook instead
    pushd ../$(stripHash $cargoDeps)/glycin-3.*
      patch -p3 < ${libglycin.passthru.glycin3PathsPatch}
    popd
  '';

  preFixup = ''
    # Needed for the glycin crate to find loaders.
    # https://gitlab.gnome.org/sophie-h/glycin/-/blob/0.1.beta.2/glycin/src/config.rs#L44
    gappsWrapperArgs+=(
      --prefix XDG_DATA_DIRS : "${glycin-loaders}/share"
    )
  '';

  postInstall = ''
    install -D resources/io.m51.Gelly.desktop $out/share/applications/io.m51.Gelly.desktop
    install -D resources/io.m51.Gelly.metainfo.xml $out/share/metainfo/io.m51.Gelly.metainfo.xml
    install -D resources/io.m51.Gelly.gschema.xml $out/share/glib-2.0/schemas/io.m51.Gelly.gschema.xml
    install -D resources/io.m51.Gelly.svg $out/share/icons/hicolor/scalable/apps/io.m51.Gelly.svg
    install -D resources/io.m51.Gelly-symbolic.svg $out/share/icons/hicolor/symbolic/apps/io.m51.Gelly-symbolic.svg
    glib-compile-schemas $out/share/glib-2.0/schemas
  '';

  meta = {
    description = "Jellyfin client for Linux focused on music";
    homepage = "https://github.com/Fingel/gelly";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ marcel ];
    mainProgram = "gelly";
  };
}
