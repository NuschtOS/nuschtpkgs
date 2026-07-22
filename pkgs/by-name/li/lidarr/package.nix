{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  fetchpatch,
  buildDotnetModule,
  dotnetCorePackages,
  sqlite,
  fetchYarnDeps,
  yarn,
  fixup-yarn-lock,
  nodejs,
  nixosTests,
  # update script
  writers,
  python3Packages,
  nix,
  prefetch-yarn-deps,
  applyPatches,
}:
let
  version = "3.1.0.4875";
  # The dotnet8 compatibility patches also change `yarn.lock`, so we must pass
  # the already patched lockfile to `fetchYarnDeps`.
  src = applyPatches {
    src = fetchFromGitHub {
      owner = "Lidarr";
      repo = "Lidarr";
      tag = "v${version}";
      hash = "sha256-RCJlToQw96U8seZaD/QCPL1Pn42yw5iXFWGJCHSHwQw=";
    };
    postPatch = ''
      mv src/NuGet.config NuGet.Config
    '';
    patches = [
      (fetchpatch {
        name = "rqbit";
        url = "https://github.com/Sonarr/Sonarr/commit/37cb978f182dc3f04a10b45ba682473b1119f16a.patch";
        hash = "sha256-c0NkZ/XeqxL+Ld6dLexVqKxt77SPuOBqKTgUa8wYWQw=";
      })
      (fetchpatch {
        name = "rqbit-fix-out-path";
        url = "https://github.com/Sonarr/Sonarr/commit/7e627f69470b1a1d20560e31968cf281e711cc2e.patch";
        hash = "sha256-7s0p32dR9MtKMchByPhvOtQrUVO9AmUmtP3sRrq50+I=";
      })
      (fetchpatch {
        name = "rqbit-categories-path";
        url = "https://github.com/Sonarr/Sonarr/commit/ee3f74d49ce5f2b17a14f56eb2247637b42c813a.patch";
        hash = "sha256-KjGn76j1AzuTi3gDxvqopFFZwCtzp9etZLaspq6QIUw=";
      })
      (fetchpatch {
        name = "rqbit-categories-path";
        url = "https://github.com/Lidarr/Lidarr/commit/754882271b27a0dd61375e19505ceac1eb40a121.patch";
        hash = "sha256-2zbg3A4DBfjZ3KeVCqfrEwiBKJpgrD4vMxtEZbBsPdw=";
      })
    ];
  };
  rid = dotnetCorePackages.systemToDotnetRid stdenvNoCC.hostPlatform.system;
in
buildDotnetModule {
  pname = "lidarr";
  inherit version src;

  strictDeps = true;
  nativeBuildInputs = [
    nodejs
    yarn
    prefetch-yarn-deps
    fixup-yarn-lock
  ];

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = "${src}/yarn.lock";
    hash = "sha256-Jq2O7gvB+PKcz6uDBMg7ox6/Bu+pikXH6JGuLfKG5fI=";
  };

  postConfigure = ''
    yarn config --offline set yarn-offline-mirror "$yarnOfflineCache"
    fixup-yarn-lock yarn.lock
    yarn install --offline --frozen-lockfile --ignore-platform --ignore-scripts --no-progress --non-interactive
    patchShebangs --build node_modules
  '';
  postBuild = ''
    yarn --offline run build --env production
  '';
  postInstall = ''
    cp -a -- _output/UI "$out/lib/lidarr/UI"
  '';

  nugetDeps = ./deps.json;

  runtimeDeps = [ sqlite ];

  dotnet-sdk = dotnetCorePackages.sdk_8_0;
  dotnet-runtime = dotnetCorePackages.aspnetcore_8_0;

  doCheck = true;

  __darwinAllowLocalNetworking = true; # for tests

  __structuredAttrs = true; # for Copyright property that contains spaces

  executables = [ "Lidarr" ];

  projectFile = [
    "src/NzbDrone.Console/Lidarr.Console.csproj"
    "src/NzbDrone.Mono/Lidarr.Mono.csproj"
  ];

  testProjectFile = [
    "src/NzbDrone.Api.Test/Lidarr.Api.Test.csproj"
    "src/NzbDrone.Common.Test/Lidarr.Common.Test.csproj"
    "src/NzbDrone.Core.Test/Lidarr.Core.Test.csproj"
    "src/NzbDrone.Host.Test/Lidarr.Host.Test.csproj"
    "src/NzbDrone.Libraries.Test/Lidarr.Libraries.Test.csproj"
    "src/NzbDrone.Mono.Test/Lidarr.Mono.Test.csproj"
    "src/NzbDrone.Test.Common/Lidarr.Test.Common.csproj"
  ];

  dotnetFlags = [
    "--property:TargetFramework=net8.0"
    "--property:EnableAnalyzers=false"
    "--property:SentryUploadSymbols=false" # Fix Sentry upload failed warnings
    # Override defaults in src/Directory.Build.props that use current time.
    "--property:Copyright=Copyright 2014-2025 lidarr.audio (GNU General Public v3)"
    "--property:AssemblyVersion=${version}"
    "--property:AssemblyConfiguration=master"
    "--property:RuntimeIdentifier=${rid}"
  ];

  # Skip manual, integration, automation and platform-dependent tests.
  testFilters = [
    "TestCategory!=ManualTest"
    "TestCategory!=IntegrationTest"
    "TestCategory!=AutomationTest"

    # makes real HTTP requests
    "FullyQualifiedName!~NzbDrone.Core.Test.UpdateTests.UpdatePackageProviderFixture"
    "FullyQualifiedName!~NzbDrone.Core.Test.ImportListTests.SpotifyMappingFixture"
    "FullyQualifiedName!~NzbDrone.Core.Test.MetadataSource.SkyHook.SkyHookProxyFixture"
    "FullyQualifiedName!~NzbDrone.Core.Test.MetadataSource.SkyHook.SkyHookProxySearchFixture"
  ]
  ++ lib.optionals stdenvNoCC.buildPlatform.isDarwin [
    # fails on macOS
    "FullyQualifiedName!~NzbDrone.Core.Test.Http.HttpProxySettingsProviderFixture"
  ];

  disabledTests = [
    # setgid tests
    "NzbDrone.Mono.Test.DiskProviderTests.DiskProviderFixture.should_preserve_setgid_on_set_folder_permissions"
    "NzbDrone.Mono.Test.DiskProviderTests.DiskProviderFixture.should_clear_setgid_on_set_folder_permissions"

    # we do not set application data directory during tests (i.e. XDG data directory)
    "NzbDrone.Mono.Test.DiskProviderTests.FreeSpaceFixture.should_return_free_disk_space"
    "NzbDrone.Common.Test.ServiceFactoryFixture.event_handlers_should_be_unique"

    # attempts to read /etc/*release and fails since it does not exist
    "NzbDrone.Mono.Test.EnvironmentInfo.ReleaseFileVersionAdapterFixture.should_get_version_info"

    # fails to start test dummy because it cannot locate .NET runtime for some reason
    "NzbDrone.Common.Test.ProcessProviderFixture.should_be_able_to_start_process"
    "NzbDrone.Common.Test.ProcessProviderFixture.exists_should_find_running_process"
    "NzbDrone.Common.Test.ProcessProviderFixture.kill_all_should_kill_all_process_with_name"
  ];

  passthru = {
    tests = {
      inherit (nixosTests) lidarr;
    };

    updateScript = writers.writePython3 "lidarr-updater" {
      libraries = with python3Packages; [ requests ];
      flakeIgnore = [ "E501" ];
      makeWrapperArgs = [
        "--prefix"
        "PATH"
        ":"
        (lib.makeBinPath [
          nix
          prefetch-yarn-deps
        ])
      ];
    } ./update.py;
  };

  meta = {
    description = "Usenet/BitTorrent music downloader";
    homepage = "https://lidarr.audio";
    changelog = "https://github.com/Lidarr/Lidarr/releases/tag/v${version}";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [
      ramonacat
      karaolidis
    ];
    mainProgram = "Lidarr";
    # platforms inherited from dotnet-sdk.
  };
}
