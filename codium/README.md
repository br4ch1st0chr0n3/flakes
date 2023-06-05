# Codium flake

Set up VSCodium with extensions and executables on its `PATH` in several lines of Nix code

See [Prerequisites](https://github.com/deemp/flakes#prerequisites)

## Conventions

In a project with multiple subprojects, one needs to switch between toolsets for each subproject.
In some cases, it's convenient to start several `VSCodium` instances, one per sub-project.
Then, one needs to decide how to deliver `VSCodium` in such a project. There are several options.

1. A single `VSCodium` with a superset of required extensions and executables on its `PATH` over the sub-projects.
1. A `VSCodium` per sub-project
1. A mix of these

## Contribute

```console
nix develop
codium .
```

## Troubleshooting

### Missing extensions

Only one instance of `VSCodium` gets supplied extensions.
Close other instances of `VSCodium` before opening a new one.

### GitHub Personal Access Token (PAT) for VS Codium extensions

- Create a `classic` PAT with permissions: `read:user, repo, user:email, workflow`
- Supply it to extensions

### Missing binaries on PATH in VSCodium

Case: VSCodium doesn't have the binaries provided in `runtimeDependencies` (like [here](https://github.com/deemp/flakes/blob/5e51f3f3b117ebc8d76222c8fa2e84a61c445cb8/templates/codium/generic/flake.nix#L41)) on `PATH`:

   1. You need to repair VSCodium's derivation
   1. Assumptions:
      - current directory is `DIR`
      - there is a `DIR/flake.nix`
      - VSCodium is given as a derivation `codium`, like [here](https://github.com/deemp/flakes/blob/5e51f3f3b117ebc8d76222c8fa2e84a61c445cb8/templates/codium/generic/flake.nix#L33)
      - In `./flake.nix`, you should have a `packages.codium`, like [here](https://github.com/deemp/flakes/blob/5e51f3f3b117ebc8d76222c8fa2e84a61c445cb8/templates/codium/generic/flake.nix#L55)
   1. `Check`:
      1. Start VSCodium: `nix run .#codium .`
      1. Open a VSCodium terminal
      1. `echo $PATH` there
      1. It doesn't contain `/bin` dirs of specified `runtimeDependencies`
   1. Close:
      - devshells with this VSCodium
      - VSCodium itself
   1. Remove direnv profiles:
      - `cd DIR && rm -rf .direnv`
   1. Open a new terminal, `cd DIR`
   1. Run `nix store repair .#codium`
   1. Make a `Check` (see above) to verify binaries are on `PATH`
   1. If still no, continue
   1. Restart your OS
   1. `nix store gc` - collect garbage in Nix store - [man](https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-store-gc.html)
   1. Again, make a `Check`
