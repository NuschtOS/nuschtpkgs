{
  knot-resolver_6,
  writeText,
  python3Packages,
  luajitPackages,
}:

python3Packages.buildPythonPackage {
  pname = "knot-resolver-manager";
  inherit (knot-resolver_6) version src;

  patches = [
    # Rewrap the two supervisor's binaries, so that they obtain access to python modules
    # defined in the manager.  Those are then used as extensions of supervisord.
    # Manager needs this fixed bin/supervisord on its $PATH.
    (writeText "rewrap-supervisor.patch" ''
      --- a/setup.py
      +++ b/setup.py
      @@ -30,2 +30,4 @@
       {'console_scripts': ['knot-resolver = knot_resolver.manager.main:main',
      +                     'supervisord = supervisor.supervisord:main',
      +                     'supervisorctl = supervisor.supervisorctl:main',
                            'kresctl = knot_resolver.client.main:main']}
    '')
  ];

  # Propagate meson config from the C part to the python part.
  postPatch = ''
    cp ${knot-resolver_6.config_py}/knot_resolver/constants.py ./python/knot_resolver/constants.py
  '';

  propagatedBuildInputs = with python3Packages; [
    aiohttp
    jinja2
    pyyaml
    prometheus-client
    supervisor
    watchdog

    # properly do this
    luajitPackages.lua
    luajitPackages.http
    luajitPackages.psl
  ];

  preCheck = ''
    mkdir -p /tmp/pytest-kresd-portdir/
    export PATH=${knot-resolver_6}/bin:$PATH
  '';

  checkInputs = with python3Packages; [
    pytestCheckHook
    pytest-asyncio
    pyparsing
    toml

    # undocumented
    augeas
    dnspython
    lief
    pyroute2
  ];

  disabledTestPaths = [
    # very slow
    "tests/pytests/test_conn_mgmt.py"
    "tests/pytests/test_prefix.py"
    # require tlsproxy test binary
    "tests/pytests/test_random_close.py"
    "tests/pytests/test_rehandshake.py"
    # times out
    "tests/pytests/test_tls.py"
  ];

  preFixup = ''
    # properly do this
    makeWrapperArgs+=(
      --set LUA_PATH "$LUA_PATH"
      --set LUA_CPATH "$LUA_CPATH"
    )
  '';

  meta = knot-resolver_6.meta // {
    mainProgram = "knot-resolver";
  };
}
