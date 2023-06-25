{
  inputs = {
    nixpkgs_.url = "github:deemp/flakes?dir=source-flake/nixpkgs";
    flake-utils_.url = "github:deemp/flakes?dir=source-flake/flake-utils";
    drv-tools.url = "github:deemp/flakes?dir=drv-tools";
    nixpkgs.follows = "nixpkgs_/nixpkgs";
    flake-utils.follows = "flake-utils_/flake-utils";
  };
  outputs =
    { self
    , nixpkgs
    , flake-utils
    , drv-tools
    , ...
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      activateVenv = ''
        ${builtins.readFile ./scripts/activate.sh}
        set +e
      '';
      inherit (drv-tools.lib.${system}) runInEachDir;
      createVenvs = dirs: runInEachDir
        {
          name = "create-venvs";
          message = "creating environment in";
          inherit dirs;
          command = ''
            ${activateVenv}
            poetry install --no-root
          '';
          runtimeInputs = [ pkgs.poetry ];
          description = "Create Python `.venv`s via `poetry` in given directories";
        };
      testCreateVenvs = createVenvs [ "." ];
    in
    {
      lib = {
        inherit
          activateVenv
          createVenvs
          ;
      };
      devShells.default = pkgs.mkShell {
        buildInputs = [ testCreateVenvs ];
      };
    }
    );
}
