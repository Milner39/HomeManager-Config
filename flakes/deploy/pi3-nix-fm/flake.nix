{
  inputs = {

    nixpkgs.url =  "github:nixos/nixpkgs/nixos-26.05";

    pi3-nix-fm.url = "path:../../system/pi3-nix-fm";

    deploy-rs.url = "github:serokell/deploy-rs";

  };

  outputs = {
    self,
    nixpkgs,
    pi3-nix-fm,
    deploy-rs,
    ...
  } @ inputs: let

    hostname = "pi3-nix-fm";
    system = "aarch64-linux";
    pkgs = import nixpkgs { inherit system; };

    # Use cached binary (recommended approach)
    deployPkgs = import nixpkgs {
      inherit system;
      overlays = [
        deploy-rs.overlays.default
        (final: prev: {
          deploy-rs = {
            inherit (pkgs) deploy-rs;
            inherit (prev.deploy-rs) lib;
          };
        })
      ];
    };

  in {
    deploy.nodes.default = {
      inherit hostname;

      user = "root";
      sshUser = "finnm";
      interactiveSudo = true;

      # Doesn't work with `interactiveSudo`
      # See https://github.com/serokell/deploy-rs/issues/107
      magicRollback = false;

      # Flake output to deploy
      profiles.system.path = 
        deployPkgs.deploy-rs.lib.activate.nixos
        pi3-nix-fm.nixosConfigurations.default;
    };
  };
}
