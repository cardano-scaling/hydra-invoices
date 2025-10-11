{ self, ... }: {

  perSystem = { compiler, inputMap, pkgs, ... }:


    let
      hsPkgs = pkgs.haskell-nix.project {
        src = pkgs.haskell-nix.haskellLib.cleanSourceWith {
          name = "hydra";
          src = self;
          filter = path: _type:
            builtins.all (x: baseNameOf path != x) [
              "flake.nix"
              "flake.lock"
              "nix"
              ".github"
              "demo"
              "docs"
              "sample-node-config"
              "spec"
              "testnets"
            ];
        };
        projectFileName = "cabal.project";

        inherit inputMap;

        compiler-nix-name = compiler;

        modules = [
          {
            packages = {
              hydra-invoices.writeHieFiles = true;
            };
          }
         {
            reinstallableLibGhc = false;
          }
        ];
      };

    in
    {
      _module.args = { inherit hsPkgs; };
    };
}
