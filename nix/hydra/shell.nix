{ self, ... }: {

  perSystem = { pkgs, hsPkgs, compiler, self', ... }:
    let

      buildInputs = [
        pkgs.cabal-fmt
        pkgs.cabal-install
        pkgs.cabal-plan
        pkgs.fourmolu
        pkgs.git
        pkgs.haskell-language-server
        pkgs.haskellPackages.hspec-discover
        pkgs.haskellPackages.ghcid
        pkgs.jq
        pkgs.nixpkgs-fmt
        pkgs.pkg-config
        pkgs.weeder
        pkgs.yq
      ];
      libs = [
        pkgs.glibcLocales
        pkgs.libsodium-vrf
        pkgs.secp256k1
        pkgs.xz
        pkgs.zlib
      ]
      ++
      pkgs.lib.optionals pkgs.stdenv.isLinux [
        pkgs.systemd
      ];
    in
    {
      devShells.default = hsPkgs.shellFor {
        buildInputs = libs ++ buildInputs;
      };
    };
}
