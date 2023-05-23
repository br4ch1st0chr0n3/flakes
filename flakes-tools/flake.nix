{
  inputs = {
    nixpkgs_.url = "github:deemp/flakes?dir=source-flake/nixpkgs";
    nixpkgs.follows = "nixpkgs_/nixpkgs";
    flake-utils_.url = "github:deemp/flakes?dir=source-flake/flake-utils";
    flake-utils.follows = "flake-utils_/flake-utils";
    drv-tools.url = "github:deemp/flakes?dir=drv-tools";
  };
  outputs =
    { self
    , nixpkgs
    , drv-tools
    , flake-utils
    , ...
    }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (drv-tools.functions.${system})
        withMan runFishScript mkShellApp wrapShellApp
        mkShellApps mkBin framedBrackets
        concatStringsNewline mkDevShellsWithDefault runInEachDir
        indentStrings4 withDescription
        ;
      inherit (pkgs.lib.lists) flatten;

      # TODO update cachix
      # https://github.com/cachix/cachix/issues/529
      cachix = pkgs.haskellPackages.cachix_1_3_3;

      man = drv-tools.configs.${system}.man // {
        ENV = "# EXPECTED ENV VARIABLES";
        CACHIX_CACHE = ''
          `CACHIX_CACHE`
          :   cachix cache name  
        '';
        CACHIX_AUTH_TOKEN = ''
          `CACHIX_AUTH_TOKEN`
          :   cachix authorization token
        '';
      };
      pushXToCachix = inp@{ name, fishScriptPath, runtimeInputs ? [ ], text ? "" }:
        withMan
          (runFishScript
            (
              inp // {
                name = "push-${name}-to-cachix";
                runtimeInputs =
                  runtimeInputs ++
                  [
                    cachix
                    pkgs.jq
                    pkgs.findutils
                    pkgs.nix
                  ];
              }
            )
          )
          (_: ''A helper function for pushing to `cachix`'');

      pushPackagesToCachix =
        withMan
          (pushXToCachix { name = "packages"; fishScriptPath = ./scripts/cache-packages.fish; })
          (
            x:
            ''
              ${man.DESCRIPTION}
              ${x.meta.description}
          
              ${man.ENV}

              `PATHS_FOR_PACKAGES`
              :   (optional) temporary file where to store the build output paths
            ''
          );

      pushDevShellsToCachix =
        withMan
          (withDescription
            (pushXToCachix { name = "devshells"; fishScriptPath = ./scripts/cache-devshells.fish; })
            (_: "Push full closures (build and runtime dependencies) of all flake's devshells to `cachix`")
          )
          (x:
            ''
              ${man.DESCRIPTION}
              ${x.meta.description}
            
              ${man.ENV}

              
              `PROFILES_FOR_DEVSHELLS`
              :  (optional) temporary dir where to store the dev profiles
            ''
          )
      ;

      pushInputsToCachix =
        withMan
          (withDescription (pushXToCachix { name = "flake-inputs"; fishScriptPath = ./scripts/cache-inputs.fish; })
            (_: "Push all flake inputs to `cachix`")
          )
          (x:
            ''
              ${man.DESCRIPTION}
              ${x.meta.description}
          
              ${man.ENV}
              ${man.CACHIX_CACHE}
            ''
          )
      ;
      pushAllToCachix =
        withMan
          (mkShellApp {
            name = "push-all-to-cachix";
            text = ''
              ${mkBin pushInputsToCachix}
              ${mkBin pushDevShellsToCachix}
              ${mkBin pushPackagesToCachix}
            '';
            description = "Push inputs and outputs (`packages` and `devShells`) of a flake to `cachix`";
          })
          (x:
            ''
              ${man.DESCRIPTION}
              ${x.meta.description}

              ${man.ENV}
              ${man.CACHIX_CACHE}
            ''
          );


      flakesUpdate = dirs:
        runInEachDir
          rec {
            inherit dirs;
            name = "flakes-update";
            command = "${pkgs.nix}/bin/nix flake update";
            description = ''Update `flake.lock`s'';
          };


      # push to cachix all about flakes in specified directories relative to CWD
      flakesPushToCachix = dirs:
        let description = "Push flakes inputs and outputs to `cachix` in given directories";
        in
        runInEachDir {
          inherit dirs;
          name = "flakes-push-to-cachix";
          command = "${mkBin pushAllToCachix}";
          inherit description;
          longDescription = ''
            ${man.ENV}
            ${man.CACHIX_CACHE}
          '';
        };

      # update and push flakes to cachix in specified directories relative to CWD
      flakesUpdateAndPushToCachix = dirs:
        let
          flakesUpdate_ = flakesUpdate dirs;
          flakesPushToCachix_ = flakesPushToCachix dirs;
          dirs_ = flatten dirs;
        in
        withMan
          (mkShellApp {
            name = "flakes-update-and-push-to-cachix";
            text = ''
              ${mkBin flakesUpdate_}
              ${mkBin flakesPushToCachix_}
            '';
            description = "Update and push flakes to `cachix` in specified directories relative to `CWD`.";
          })
          (x: ''
            ${man.DESCRIPTION}
            ${x.meta.description}
            
            ${man.ENV}
            ${man.CACHIX_CACHE}

            ${man.NOTES}
            The given directories relative to `CWD` are:
            ${indentStrings4 dirs_}
          ''
          );

      # dump a devshell by running a dummy command in it
      dumpDevShells = runFishScript {
        name = "dump-devshells";
        fishScriptPath = ./scripts/dump-devshells.fish;
        runtimeInputs = [ pkgs.jq pkgs.findutils ];
      };

      # dump devshells in given directories
      # can be combined with updating flake locks
      flakesDumpDevshells = dirs:
        let description = "Evaluate devshells to in given directories to dump them"; in
        runInEachDir {
          inherit dirs;
          name = "flakes-dump-devshells";
          command = ''
            ${mkBin dumpDevShells}
          '';
          inherit description;
          longDescription = ''
            ${man.DESCRIPTION}
            ${description}
          '';
        };

      # watch nix files existing at the moment
      flakesWatchDumpDevshells = dirs:
        let dirs_ = flatten dirs; in
        withMan
          (mkShellApp {
            name = "flakes-watch-dump-devshells";
            text = ''
              printf "${framedBrackets "watcher set"}"
              inotifywait -qmr -e close_write ./ | \
              while read dir action file; do
                if [[ $file =~ .*nix$ ]]; then
                  set +e
                  printf "${framedBrackets "started dumping devshells"}"
                  ${mkBin (flakesUpdate dirs)}
                  ${mkBin (flakesDumpDevshells dirs)}
                  printf "${framedBrackets "finished dumping devshells"}"
                  set -e
                fi
              done
            '';
            runtimeInputs = [ pkgs.inotify-tools ];
            description = "Start a watcher that will update `flake.lock`s and evaluate devshells in given directories";
          })
          (x:
            ''
              ${man.DESCRIPTION}
              ${x.meta.description}
            
              The given directories relative to `CWD` are:
              ${indentStrings4 dirs_}
            ''
          );

      logInToCachix = withMan
        (mkShellApp {
          name = "logInToCachix";
          text = "${cachix}/bin/cachix authtoken $CACHIX_AUTH_TOKEN";
          description = "Log in to cachix";
        })
        (x:
          ''
            ${man.DESCRIPTION}
            ${x.meta.description}

            ${man.ENV}
            
          ''
        );

      # format all .nix files with the formatter specified in the flake in the CWD
      flakesFormat =
        withMan
          (mkShellApp {
            name = "flakes-format";
            text = ''${pkgs.nix}/bin/nix fmt **/*.nix'';
            description = "Format `.nix` files in `CWD` and its subdirectories";
          })
          (x: ''
            ${man.DESCRIPTION}
            ${x.meta.description} using the formatter set in the `CWD` `flake.nix`
          ''
          );

      # all flake tools together
      mkFlakesTools = dirs: (
        (__mapAttrs (name: app: wrapShellApp { inherit name app; })
          {
            updateLocks = flakesUpdate dirs;
            pushToCachix = flakesPushToCachix dirs;
            logInToCachix = logInToCachix;
            updateAndPushToCachix = flakesUpdateAndPushToCachix dirs;
            dumpDevshells = flakesDumpDevshells dirs;
            watchDumpDevshells = flakesWatchDumpDevshells dirs;
            format = flakesFormat;
          })
      );
    in
    {
      functions = {
        inherit
          flakesDumpDevshells
          flakesPushToCachix
          flakesUpdate
          flakesUpdateAndPushToCachix
          flakesWatchDumpDevshells
          mkFlakesTools
          pushXToCachix
          ;
      };

      packages = {
        inherit
          dumpDevShells flakesFormat pushAllToCachix
          pushInputsToCachix pushDevShellsToCachix
          pushPackagesToCachix logInToCachix;
      };


      devShells.default = pkgs.mkShell {
        buildInputs = [ (builtins.attrValues (mkFlakesTools [ "." ])) ];
      };
    });
}
