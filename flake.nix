{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/0e304ff0d9db453a4b230e9386418fd974d5804a";
    flake-utils.url = "github:numtide/flake-utils";
    my-codium = {
      url = "github:br4ch1st0chr0n3/flakes?dir=codium&rev=cd6e1ce937177cb9d8229919a0fe8eac841cfac9";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };
  outputs =
    { self
    , flake-utils
    , nixpkgs
    , my-codium
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};

      inherit (my-codium.packages.${system})
        writeSettingsJson
        settingsNix
        extensions
        codium
        mergeValues
        toList
        haskellTools
        shellTools
        json2nix
        ;
      # Wrap Stack to work with our Nix integration. 
      stack-wrapped = pkgs.symlinkJoin {
        # will be available as the usual `stack` in terminal
        name = "stack";
        paths = [ pkgs.stack ];
        buildInputs = [ pkgs.makeWrapper ];
        # --system-ghc    # Use the existing GHC on PATH (will come from this Nix file)
        # --no-install-ghc  # Don't try to install GHC if no matching GHC found on PATH
        postBuild = ''
          wrapProgram $out/bin/stack \
            --add-flags "\
              --system-ghc \
              --no-install-ghc \
            "
        '';
      };
      python3 = pkgs.python3.withPackages (p: with p; [ pyyaml ]);
      addProblem = pkgs.writeScriptBin "problem" ''
        ${python3}/bin/python -c """from scripts import problem; problem('$1', '$2')"""
      '';
    in
    {
      devShells =
        {
          default = pkgs.mkShell {
            name = "codium";
            buildInputs =
              (toList { inherit (shellTools) haskell nix; }) ++
              [
                codium
                (builtins.attrValues haskellTools."902")
                stack-wrapped
                json2nix
                python3
                addProblem
                (pkgs.rustup)
              ]
            ;
          };
          writeSettings = writeSettingsJson (
            settingsNix // {
              python = { "python.defaultInterpreterPath" = "${python3}/bin/python"; };
              window = { "window.zoomLevel" = 0.3; };
            }
          );
          # inherit addProblem;
        };
    });
}
