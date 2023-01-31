# Troubleshooting

## Prerequisites

See [Nix Prerequisites](NixPrerequisites.md)

## Red text in the output

This is not a problem. Just read the text and answer. When asked like:

```console
do you want to allow configuration setting 'extra-trusted-substituters' to be set to 'https://haskell-language-server.cachix.org https://nix-community.cachix.org https://cache.iog.io https://deemp.cachix.org' (y/N)?
```

answer `y`.

And then, when asked

```console
do you want to permanently mark this value as trusted (y/N)? 
```

answer `y` again. This is to let you use the binary caches listed by the flake.

## Unreliable inputs

Many of my flakes provide `VSCodium` with extensions in devshells. This dependency on extensions makes devshells prone to errors when such extensions are unavailable. Should this be the case, exclude `VSCodium` (usually called `codium`) from devshells inputs (in `devshell`, usually called `packages`).

## Substituters and keys

To provide binary caches, `flake.nix` files specify `nixConfig.extra-trusted-substituters`. If you try, e.g., `nix develop`, and `Nix` unsuccessfully tries to download from a cache several times, this cache has probably failed. Comment out the lines containing its `URL` address in `extra-trusted-substituters`.

## Repair a derivation

Repair a derivation - [manual](https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-store-repair.html)

Alternative steps:

   1. Assumptions:
      - current working directory contains `flake.nix`
      - your corrupt derivation is available inside this `flake.nix` by . name `your-corrupt-derivation`
   1. Set `packages.default = your-corrupt-derivation` in this `flake.nix`
   1. Run `nix store repair .#`
      - `.#` denotes an [installable](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix.html?highlight=installable#installables)

## VSCodium troubleshooting

See [VSCodium troubleshooting](https://github.com/deemp/flakes/blob/main/codium/README.md#troubleshooting)
