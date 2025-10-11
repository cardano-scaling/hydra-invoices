{
  perSystem = { self', lib, ... }: {
    coding.standards.hydra = {
      enable = true;
      haskellPackages = with self'.packages; [
        hydra-invoices
      ];
    };
    weeder.enable = lib.mkForce false;
  };

}
