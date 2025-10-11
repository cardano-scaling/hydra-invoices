{ inputs, ... }: {

  imports = [
    inputs.hydra-coding-standards.flakeModule
  ];

  perSystem = { pkgs, hsPkgs, ... }:
    let
      compiler = "ghc967";
      inputMap = { "https://intersectmbo.github.io/cardano-haskell-packages" = inputs.CHaP; };
    in
    {
      _module.args = { inherit compiler inputMap; };
      legacyPackages = pkgs // hsPkgs;
    };
}
