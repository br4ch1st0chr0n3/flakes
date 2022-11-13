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
  };
  outputs =
    { self
    , flake-utils
    , nixpkgs
    , my-codium
    , drv-tools
    , haskell-tools
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
      devshells = my-codium.functions.${system};
      inherit (my-codium.configs.${system})
        extensions
        settingsNix
        ;
      devshell = my-codium.devshell.${system};

      writeSettings = writeSettingsJSON {
        inherit (settingsNix) todo-tree files editor gitlens
          git nix-ide workbench markdown-all-in-one;
      };

      tools = [
        writeSettings
        pkgs.sbt
      ];

      codium = mkCodium {
        extensions = {
          inherit (extensions)
            nix haskell misc github markdown;
        };
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
            '';
          };
          commands = [
            {
              name = "codium, sbt";
            }
            {
              name = "${writeSettings.name}";
              help = "write .vscode/settings.json";
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
