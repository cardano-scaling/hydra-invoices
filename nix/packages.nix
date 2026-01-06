{ inputs, ... }: {
  perSystem = { lib, system, ... }:
    let
      myOverlay = final: _prev: {
        bech32-records = final.callCabal2nix "bech32-records" (lib.cleanSource "${inputs.self}/bech32-records") { };
        hydra-invoices = final.callCabal2nix "hydra-invoices" (lib.cleanSource "${inputs.self}/hydra-invoices") { };
      };
      legacyPackages = inputs.horizon.legacyPackages.${system}.extend myOverlay;
    in
    rec {

      devShells.default = legacyPackages.shellFor {
        packages = p: [ p.bech32-records p.hydra-invoices ];
        buildInputs = [
          legacyPackages.cabal-install
        ];
      };

      inherit legacyPackages;

      packages = rec {
        inherit (legacyPackages)
          bech32-records
          hydra-invoices;
        default = packages.hydra-invoices;
      };

    };
}
