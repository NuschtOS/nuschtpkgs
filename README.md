# NuschtOS / Nuschtpkgs

This is a [Nixpkgs](https://github.com/NixOS/nixpkgs) fork where we manualy backport PRs that are *relevant to us*.

| Name | Upstream Branch | Description |
|---|---|---|
| nixos-unstable | nixos-unstable | Includes backports required for running NixOS-Modules. |
| nixos-25.05 | nixos-25.05 | Includes backports required for running NixOS-Modules. |
| backports-25.05 | nixos-25.05 | Includes backports that are *relevant to us*. Not intendet for outside use. |

## Contact

For bugs and issues please open an issue in this repository.

If you want to chat about things or have ideas, feel free to join the [Matrix chat](https://matrix.to/#/#nuschtos:c3d2.de).

# License

Nixpkgs is licensed under the [MIT License](COPYING).

Note: MIT license does not apply to the packages built by Nixpkgs,
merely to the files in this repository (the Nix expressions, build
scripts, NixOS modules, etc.). It also might not apply to patches
included in Nixpkgs, which may be derivative works of the packages to
which they apply. The aforementioned artifacts are all covered by the
licenses of the respective packages.

