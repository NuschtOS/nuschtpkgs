# NuschtOS / Nuschtpkgs

This is a [Nixpkgs](https://github.com/NixOS/nixpkgs) fork where we manually backport PRs that are *relevant to us*.

The following branches are available. 
- `backports-26.05`
- `backports-25.11` 
- `backports-25.05` 
- `backports-24.11` 
- `backports-24.05` 

The currently active branches get automatically rebased daily onto upstream.

## Usage

This repo can be used as the nixpkgs input as follows, replace `backports-26.05` with your desired branch name:

```nix
{
  inputs = {
    nixpkgs.url = "git+https://elbforge.org/NuschtOS/nuschtpkgs/?ref=backports-26.05&shallow=1";
  };
}
```

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

