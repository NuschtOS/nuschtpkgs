{ lib
, rustPlatform
, applyPatches
, fetchFromGitHub
, fetchpatch
, pkg-config
, dbus
, nix-update-script
,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "dbus-codegen-rust";
  version = "0-unstable-2026-09-09";
  __structuredAttrs = true;

  src = applyPatches {
    src = fetchFromGitHub {
      owner = "diwic";
      repo = "dbus-rs";
      rev = "43416cad2dee5067330faf7ffe3b1908e95b0fd4";
      hash = "sha256-hQ2pJ8ZuWLwp+HGBMzZzsVfNy/a0G9iS6VRi5KhKcWY=";
    };

    patches = [
      (fetchpatch {
        url = "https://github.com/diwic/dbus-rs/commit/dff765e68868fbdb0ed192f8c84fbc3ea4cfed00.patch";
        hash = "sha256-SfVNU7ljGfXuhqfiMsvgXassPAlxWhjuBqDCDU+uvm4=";
      })
    ];
  };

  cargoHash = "sha256-UueEAyXNh037eeBXZQhUIXm67rjuKjXOziKXE6s2JGg=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    dbus
  ];

  cargoBuildFlags = [
    "--bin"
    "dbus-codegen-rust"
  ];

  doCheck = false;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Generates Rust code from xml introspection data";
    homepage = "https://github.com/diwic/dbus-rs";
    license = with lib.licenses; [
      asl20
      mit
    ];
    maintainers = with lib.maintainers; [ marcel ];
    mainProgram = "dbus-codegen-rust";
  };
})
