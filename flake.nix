{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/0e304ff0d9db453a4b230e9386418fd974d5804a";
    flake-utils.url = "github:numtide/flake-utils";
    my-codium = {
      url = "github:br4ch1st0chr0n3/flakes?dir=codium&rev=80fae01958519a663f81891e91674d0808a5ca3f";
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
        shellTools
        json2nix
        ;
      python3 = pkgs.python3.withPackages (p: with p; [
        pyyaml
        (pkgs.python310Packages.pip)
      ]);
      addProblem = pkgs.writeScriptBin "problem" ''
        ${python3}/bin/python -c "from scripts.scripts import problem; problem('$1', '$2')"
      '';
      writeSettings = writeSettingsJson ((pkgs.lib.recursiveUpdate
        settingsNix
        {
          python."python.defaultInterpreterPath" = "${python3}/bin/python";
          window."window.zoomLevel" = 0.3;
        })
        // {
          vscode-dhall-lsp-server = { };
          ide-purescript = { };
        }
      );
    in
    {
      devShells =
        {
          default = pkgs.mkShell {
            name = "codium";
            buildInputs = pkgs.lib.lists.flatten
              [
                (toList { inherit (shellTools) haskell nix; })
                (pkgs.haskell.compiler.ghc902)
                codium
                json2nix
                python3
                addProblem
                writeSettings
              ];
            shellHook = ''
              write-settings
            '';
          };
        };
    });

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://br4ch1st0chr0n3-acpoj.cachix.org"
      "https://br4ch1st0chr0n3-flakes.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "br4ch1st0chr0n3-acpoj.cachix.org-1:OYzTMty0XgyEIcm+o9tjKotr9ZjNeC4JCWmc0P0nx3U="
      "br4ch1st0chr0n3-flakes.cachix.org-1:Dyc2yLlRIkdbq8CtfOe24QQhQVduQaezkyV8J9RhuZ8="
    ];
  };
}
