{
  inputs = {

    nixpkgs.url           =  "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url  =  "github:nixos/nixpkgs/nixos-unstable";

    nix-modules = {
      url = "github:Milner39/nix-modules/release-26.05";
      inputs.nixpkgs.follows           =  "nixpkgs";
      inputs.nixpkgs-unstable.follows  =  "nixpkgs-unstable";
    };

    nixos-hardware = {
      url = "github:nixos/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nixos-hardware,
    ...
  } @ inputs: let

    flakeTools = import ../../../lib/flake {};

    system = "aarch64-linux";

    /*
      The running system and the SD image share everything in
      `./src/configuration.nix` and differ only in the last module.
    */
    mkPi = extraModules: flakeTools.mkNixosConf {
      hostname = "pi3-nix-fm";
      inherit system;
      nixpkgs = {
        stable = nixpkgs;
        unstable = nixpkgs-unstable;
      };
      modules = [
        nixos-hardware.nixosModules.raspberry-pi-3
        ./src/configuration.nix
      ] ++ extraModules;
      specialArgs = { inherit inputs; };
    };

  in {
    nixosConfigurations = {
      sd-image  =  mkPi [ ./src/sd-image.nix ];
      default   =  mkPi [ ./src/filesystems.nix ];
    };

    packages.${system}.sd-image =
      self.nixosConfigurations.sd-image.config.system.build.sdImage;
  };
}
