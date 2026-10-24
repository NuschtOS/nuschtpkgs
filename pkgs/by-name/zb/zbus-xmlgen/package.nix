{
  lib,
  rustPlatform,
  fetchFromGitHub,
  makeBinaryWrapper,
  rustfmt,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "zbus_xmlgen";
  version = "6.0.0";

  src = fetchFromGitHub {
    owner = "z-galaxy";
    repo = "zbus";
    tag = "zbus_xmlgen-${finalAttrs.version}";
    hash = "sha256-R0rq+uSelXJxNGKe8wk6juJd/QcKq7zkVSm8sz2Anho=";
  };

  cargoHash = "sha256-MRsy/zeNwCeNVeIdb8rE+zO2nUQwzeWngUFPtmrBLZk=";

  nativeBuildInputs = [ makeBinaryWrapper ];

  cargoBuildFlags = [ "-p zbus_xmlgen" ];

  doCheck = false;

  postInstall = ''
    wrapProgram $out/bin/zbus-xmlgen \
        --prefix PATH : ${lib.makeBinPath [ rustfmt ]}
  '';

  meta = {
    homepage = "https://crates.io/crates/zbus_xmlgen";
    description = "D-Bus XML interface Rust code generator";
    mainProgram = "zbus-xmlgen";
    maintainers = with lib.maintainers; [ qyliss ];
    license = lib.licenses.mit;
  };
})
