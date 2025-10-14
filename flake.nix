{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    horizon.url = "git+https://gitlab.horizon-haskell.net/package-sets/horizon-cardano";
    hydra-coding-standards.url = "github:cardano-scaling/hydra-coding-standards/0.7.1";
    import-tree.url = "github:vic/import-tree";
    nixpkgs.follows = "horizon/nixpkgs";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./nix);

  nixConfig = {
    extra-substituters = [
      "https://cache.iog.io"
      "https://cardano-scaling.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      "cardano-scaling.cachix.org-1:QNK4nFrowZ/aIJMCBsE35m+O70fV6eewsBNdQnCSMKA="
    ];
    allow-import-from-derivation = true;
  };
}
