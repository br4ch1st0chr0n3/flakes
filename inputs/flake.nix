{
  inputs = {
    source-flake.url = github:br4ch1st0chr0n3/flakes?dir=source-flake;
    nixpkgs.follows = "source-flake/nixpkgs";
    flake-utils.follows = "source-flake/flake-utils";
    gitignore.follows = "source-flake/gitignore";
    easy-purescript-nix.follows = "source-flake/easy-purescript-nix";
    dream2nix.follows = "source-flake/dream2nix";
    nix-vscode-marketplace.follows = "source-flake/nix-vscode-marketplace";
    vscodium-extensions.follows = "source-flake/vscodium-extensions";
    haskell-language-server.follows = "source-flake/haskell-language-server";
    flake-compat.follows = "source-flake/flake-compat";
    poetry2nix.follows = "source-flake/poetry2nix";
    my-codium.url = github:br4ch1st0chr0n3/flakes?dir=codium;
    json2md.url = github:br4ch1st0chr0n3/flakes?dir=json2md;
    env2json.url = github:br4ch1st0chr0n3/flakes?dir=env2json;
  };
  outputs = { source-flake, ... }: { inherit (source-flake) formatter; };
}
