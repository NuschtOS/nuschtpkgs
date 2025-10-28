{
  lib,
  fetchFromGitHub,
  python3,
}:

python3.pkgs.buildPythonApplication rec {
  pname = "ledfx";
  version = "2.1.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "LedFx";
    repo = "LedFx";
    tag = "v2.1.0";
    hash = "sha256-N9EHK0GVohFCjEKsm3g4h+4XWfzZO1tzdd2z5IN1YjI=";
  };

  pythonRelaxDeps = true;

  pythonRemoveDeps = [
    # not packaged
    "rpi-ws281x"
  ];

  build-system = with python3.pkgs; [
    cython
    pdm-backend
  ];

  dependencies = with python3.pkgs; [
    aiohttp
    aiohttp-cors
    aubio
    certifi
    flux-led
    python-dotenv
    icmplib
    mss
    multidict
    numpy
    openrgb-python
    paho-mqtt
    pillow
    psutil
    pybase64
    pyserial
    pystray
    python-mbedtls
    python-osc
    python-rtmidi
    # rpi-ws281x # not packaged
    requests
    sacn
    samplerate
    sentry-sdk
    setuptools
    sounddevice
    stupidartnet
    uvloop
    vnoise
    voluptuous
    zeroconf
  ];

  # Project has no tests
  doCheck = false;

  meta = with lib; {
    description = "Network based LED effect controller with support for advanced real-time audio effects";
    homepage = "https://github.com/LedFx/LedFx";
    changelog = "https://github.com/LedFx/LedFx/blob/${version}/CHANGELOG.rst";
    license = licenses.gpl3Only;
    teams = [ teams.c3d2 ];
    mainProgram = "ledfx";
  };
}
