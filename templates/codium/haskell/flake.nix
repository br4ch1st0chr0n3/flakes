{
  inputs = {
    nixpkgs_.url = "github:deemp/flakes?dir=source-flake/nixpkgs";
    nixpkgs.follows = "nixpkgs_/nixpkgs";
    my-codium.url = "github:deemp/flakes?dir=codium";
    drv-tools.url = "github:deemp/flakes?dir=drv-tools";
    flake-utils_.url = "github:deemp/flakes?dir=source-flake/flake-utils";
    flake-utils.follows = "flake-utils_/flake-utils";
    haskell-tools.url = "github:deemp/flakes?dir=language-tools/haskell";
    devshell.url = "github:deemp/flakes?dir=devshell";
    flakes-tools.url = "github:deemp/flakes?dir=flakes-tools";
    # necessary for stack-nix integration
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };
  outputs =
    { self
    , flake-utils
    , flakes-tools
    , nixpkgs
    , my-codium
    , drv-tools
    , haskell-tools
    , devshell
    , ...
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      # --- imports ---
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (my-codium.functions.${system}) writeSettingsJSON mkCodium;
      inherit (drv-tools.functions.${system}) mkBin withAttrs withMan withDescription mkShellApp;
      inherit (drv-tools.configs.${system}) man;
      inherit (my-codium.configs.${system}) extensions settingsNix;
      inherit (flakes-tools.functions.${system}) mkFlakesTools;
      inherit (devshell.functions.${system}) mkCommands mkShell;
      inherit (haskell-tools.functions.${system}) haskellTools;

      # set ghc version
      ghcVersion_ = "92";
      # my app name
      myPackageName = "nix-managed";

      # # --- non-haskell deps ---
      myPackageDepsLib = [ pkgs.lzma ];
      myPackageDepsBin = [ pkgs.hello ];
      myPackageDeps = myPackageDepsLib ++ myPackageDepsBin;


      # --- cabal shell ---
      inherit (pkgs.haskell.lib)
        # doJailbreak - remove package bounds from .cabal
        doJailbreak
        # dontCheck - skip tests
        dontCheck;

      override = {
        overrides = self: super: {
          lzma = dontCheck (doJailbreak super.lzma);
          myPackage = pkgs.haskell.lib.overrideCabal
            (super.callCabal2nix myPackageName ./. { })
            (_: {
              librarySystemDepends = myPackageDepsLib;
            });
        };
      };

      inherit (haskellTools ghcVersion_ override (ps: [ ps.myPackage ]) myPackageDepsBin)
        stack hls cabal implicit-hie justStaticExecutable
        ghcid callCabal2nix haskellPackages;

      cabalShellFor =
        haskellPackages.shellFor {
          packages = ps: [ ps.myPackage ];
          nativeBuildInputs = myPackageDeps ++ [ cabal ];
          withHoogle = true;
          # get other tools with names
          shellHook = framed "cabal run";
        };

      cabalShell = mkShell {
        packages = [ cabal ];
        bash.extra = framed "cabal run";
        commands = mkCommands "tools" [ cabal ];
      };

      # --- nix-packaged app ---
      # Turn app into a static executable
      myPackageExe =
        withMan
          (withDescription
            (justStaticExecutable myPackageName haskellPackages.myPackage)
            "Demo Nix-packaged `Haskell` program "
          )
          (
            x: ''
              ${man.DESCRIPTION}
              ${x.meta.description}
            ''
          )
      ;

      # --- docker image of the package ---
      myPackageImageTag = "latest";
      myPackageImage = pkgs.dockerTools.buildLayeredImage {
        name = myPackageName;
        tag = myPackageImageTag;
        config.Entrypoint = [ "bash" "-c" myPackageName ];
        contents = [ pkgs.bash myPackageExe ];
      };

      dockerShell = mkShell {
        packages = [ pkgs.docker ];
        bash.extra = ''
          docker load < ${myPackageImage}
          ${framed "docker run -it ${myPackageName}:${myPackageImageTag}"}
        '';
        commands = mkCommands "tools" [ pkgs.docker ];
      };

      # --- all dev tools ---
      codiumTools = [
        implicit-hie
        ghcid
        stack
        writeSettings
        cabal
      ];

      # --- codium ---
      # what to write in settings.json
      writeSettings = writeSettingsJSON {
        inherit (settingsNix) haskell todo-tree files editor gitlens
          git nix-ide workbench markdown-all-in-one markdown-language-features;
      };

      # VSCodium with dev tools
      codium = mkCodium {
        extensions = { inherit (extensions) nix haskell misc github markdown; };
        runtimeDependencies = codiumTools ++ [ hls ];
      };

      tools = codiumTools ++ [ codium ];

      # --- flakes tools ---
      flakesTools = mkFlakesTools [ "." ];

      # --- stack shell ---
      framed = command: ''
        printf "====\n"
        ${command}
        printf "====\n"
      '';

      # --- default shell ---
      defaultShell = mkShell
        {
          packages = tools;
          bash.extra = framed (mkBin myPackageExe);
          commands = mkCommands "tools" tools;
        };

      stackShell = mkShell {
        packages = [ stack ];
        bash.extra = framed "stack run";
        commands = mkCommands "tools" [ stack ];
      };
    in
    {
      packages = {
        default = myPackageExe;
        inherit (flakesTools) updateLocks pushToCachix;
      };

      devShells = {
        # --- devshell with dev tools ---
        # runs nix-packaged app
        default = defaultShell;

        # --- shell for cabal ---
        # runs cabal
        cabal = cabalShell;

        # --- shell for cabal via shellFor ---
        # runs cabal
        cabalShellFor = cabalShellFor;

        # --- shell for docker ---
        # runs a container with myPackage
        docker = dockerShell;

        # --- shell for stack ---
        # runs stack
        stack = stackShell;
      };

      # --- shell for stack-nix integration
      # this is not a nix devShell
      # this shell will automatically be called by stack
      stack-shell = { ghcVersion }:

        pkgs.haskell.lib.buildStackProject {
          name = "stack-shell";

          ghc = pkgs.haskell.compiler.${ghcVersion};

          buildInputs = myPackageDeps;
        };
    });

  nixConfig = {
    extra-substituters = [
      "https://haskell-language-server.cachix.org"
      "https://nix-community.cachix.org"
      "https://cache.iog.io"
      "https://deemp.cachix.org"
    ];
    extra-trusted-public-keys = [
      "haskell-language-server.cachix.org-1:juFfHrwkOxqIOZShtC4YC1uT1bBcq2RSvC7OMKx0Nz8="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      "deemp.cachix.org-1:9shDxyR2ANqEPQEEYDL/xIOnoPwxHot21L5fiZnFL18="
    ];
  };
}
