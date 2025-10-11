_: {

  perSystem = { pkgs, hsPkgs, lib, ... }:
    let
      allComponents = x:
        [ x.components.library ]
        ++ lib.concatMap
          (y: builtins.attrValues x.components."${y}")
          [ "benchmarks" "exes" "sublibs" "tests" ];

    in
    {


      coding.standards.hydra = {
        enable = true;
        haskellPackages = with hsPkgs; builtins.concatMap allComponents [
          hydra-invoices         
        ];
        inherit (pkgs) weeder;
        haskellType = "haskell.nix";
      };

    };
}
