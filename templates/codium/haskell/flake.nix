{
  inputs = {
    nixpkgs_.url = "github:br4ch1st0chr0n3/flakes?dir=source-flake/nixpkgs";
    nixpkgs.follows = "nixpkgs_/nixpkgs";
    my-codium.url = "github:br4ch1st0chr0n3/flakes?dir=codium";
    drv-tools.url = "github:br4ch1st0chr0n3/flakes?dir=drv-tools";
    flake-utils_.url = "github:br4ch1st0chr0n3/flakes?dir=source-flake/flake-utils";
    flake-utils.follows = "flake-utils_/flake-utils";    
    haskell-tools.url = "github:br4ch1st0chr0n3/flakes?dir=language-tools/haskell";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    my-devshell.url = "github:br4ch1st0chr0n3/flakes?dir=devshell";
  };
  outputs =
    { self
    , flake-utils
    , nixpkgs
    , my-codium
    , drv-tools
    , haskell-tools
    , my-devshell
    , ...
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (my-codium.functions.${system})
        writeSettingsJSON
        mkCodium
        ;
      inherit (drv-tools.functions.${system})
        mkBinName
        ;
      inherit (my-codium.configs.${system})
        extensions
        settingsNix
        ;
      devshell = my-devshell.devshell.${system};
      inherit (haskell-tools.functions.${system})
        toolsGHC
        ;
      hsShellTools = haskell-tools.toolSets.${system}.shellTools;
      inherit (toolsGHC "90") stack hls ghc;

      writeSettings = writeSettingsJSON {
        inherit (settingsNix) haskell todo-tree files editor gitlens
          git nix-ide workbench markdown-all-in-one;
      };

      tools = (builtins.attrValues hsShellTools) ++ [
        stack
        writeSettings
        hls
        ghc
        pkgs.jq
      ];

      codium = mkCodium {
        extensions = { inherit (extensions) nix haskell misc github markdown; };
        runtimeDependencies = tools;
      };
    in
    {
      packages = {
        default = codium;
      };

      devShells.default = devshell.mkShell
        {
          packages = [ codium ] ++ tools;
          bash = {
            extra = ''
              printf "Hello!"
            '';
          };
          commands = [
            {
              name = "ghcid, stack, ghc, jq";
            }
            {
              name = "codium";
              help = "VSCodium with several tool binaries on `PATH` and a couple of extensions";
              category = "ide";
            }
            {
              name = "${writeSettings.name}";
              help = "write `.vscode/settings.json`";
              category = "ide";
            }
          ];
        };
    });

  nixConfig = {
    extra-substituters = [
      "https://haskell-language-server.cachix.org"
      "https://nix-community.cachix.org"
      "https://hydra.iohk.io"
      "https://br4ch1st0chr0n3.cachix.org"
    ];
    extra-trusted-public-keys = [
      "haskell-language-server.cachix.org-1:juFfHrwkOxqIOZShtC4YC1uT1bBcq2RSvC7OMKx0Nz8="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      "br4ch1st0chr0n3.cachix.org-1:o1FA93L5vL4LWi+jk2ECFk1L1rDlMoTH21R1FHtSKaU="
    ];
  };
}
