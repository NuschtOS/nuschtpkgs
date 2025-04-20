{
  cmake,
  fetchFromGitHub,
  lib,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "pcm";
  version = "unstable-2025-04-21";

  src = fetchFromGitHub {
    owner = "marenz2569";
    repo = "pcm";
    # beanch: marenz.pcm_sensor_server_bind_ip
    rev = "6d2d67dcc11610ffafe4b2a375f6d5558e29ae22";
    hash = "sha256-xX89eaWE8sKRtYnd3vbor0uV4VLgzVGa4M8iOPxyBF4=";
  };

  nativeBuildInputs = [ cmake ];
  enableParallelBuilding = true;

  meta = with lib; {
    description = "Processor counter monitor";
    homepage = "https://www.intel.com/software/pcm";
    license = licenses.bsd3;
    maintainers = with maintainers; [ roosemberth ];
    platforms = [ "x86_64-linux" ];
  };
}
