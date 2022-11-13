{
  inputs = {
    nixpkgs_.url = "github:br4ch1st0chr0n3/flakes?dir=source-flake/nixpkgs";
    nixpkgs.follows = "nixpkgs_/nixpkgs";
    flake-utils_.url = "github:br4ch1st0chr0n3/flakes?dir=source-flake/flake-utils";
    flake-utils.follows = "flake-utils_/flake-utils";
    my-codium.url = "github:br4ch1st0chr0n3/flakes?dir=codium";
    drv-tools.url = "github:br4ch1st0chr0n3/flakes?dir=drv-tools";
    flake-tools.url = "github:br4ch1st0chr0n3/flakes?dir=flake-tools";
    haskell-tools.url = "github:br4ch1st0chr0n3/flakes?dir=language-tools/haskell";
    manager.url = "github:br4ch1st0chr0n3/flakes?dir=manager";
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
    , flake-tools
    , manager
    , ...
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (my-codium.functions.${system})
        writeSettingsJSON
        mkCodium
        ;
      devshells = my-codium.functions.${system};
      inherit (my-codium.configs.${system})
        extensions
        settingsNix
        ;
      devshell = my-codium.devshell.${system};
      inherit (flake-tools.functions.${system})
        mkFlakesUtils
        ;
      inherit (haskell-tools.functions.${system})
        toolsGHC
        ;
      hsShellTools = haskell-tools.toolSets.${system}.shellTools;
      inherit (toolsGHC "92") staticExecutable stack hls;

      writeSettings = writeSettingsJSON {
        inherit (settingsNix) haskell todo-tree files editor gitlens
          git nix-ide workbench markdown-all-in-one;
      };

      tools = (builtins.attrValues hsShellTools) ++ [
        pkgs.cabal-install
        manager.packages.${system}.default
        stack
        writeSettings
        hls
        pkgs.jq
      ];

      codium = mkCodium {
        extensions = { inherit (extensions) nix haskell misc github markdown; };
        runtimeDependencies = tools;
      };

      flakesUtils = mkFlakesUtils [ "." ];
    in
    {
      packages = {
        default = codium;
        pushToCachix = flakesUtils.flakesPushToCachix;
        updateLocks = flakesUtils.flakesUpdate;
      };

      devShells.default = devshell.mkShell
        {
          packages = [ codium ] ++ tools;
          bash = {
            extra = ''
              source <(manager --bash-completion-script '$(which manager)')
            '';
          };
          commands = [
            {
              name = "codium, ghcid, stack";
              help = "available in codium";
            }
            {
              name = "${writeSettings.name}";
              help = "write .vscode/settings.json";
            }
            {
              name = "manager";
              category = "tools";
              help = "manage Haskell modules and template files";
            }
          ];
        };

      stack-shell = { ghcVersion }:

        pkgs.haskell.lib.buildStackProject {
          name = "nix-managed-stack-shell";

          ghc = pkgs.haskell.compiler.${ghcVersion};

          buildInputs = [
            pkgs.zlib
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
