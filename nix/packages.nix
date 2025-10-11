{ inputs, ... }: {
  perSystem = { lib, system, ... }:
    let
      myOverlay = final: _prev: {
        hydra-invoices = final.callCabal2nix "hydra-invoices" (lib.cleanSource "${inputs.self}/hydra-invoices") { };
      };
      legacyPackages = inputs.horizon.legacyPackages.${system}.extend myOverlay;
    in
    rec {

      devShells.default = legacyPackages.shellFor {
        packages = p: [ p.hydra-invoices ];
        buildInputs = [
          legacyPackages.cabal-install
        ];
      };

      inherit legacyPackages;

      packages = rec {
        inherit (legacyPackages)
          hydra-invoices;
        default = packages.hydra-invoices;
      };

    };
}
