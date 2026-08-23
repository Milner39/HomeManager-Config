{
  inputs = {

    nixpkgs.url           =  "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url  =  "github:nixos/nixpkgs/nixos-unstable";

    nix-modules = {
      url = "github:Milner39/nix-modules/release-26.05";
      inputs.nixpkgs.follows           =  "nixpkgs";
      inputs.nixpkgs-unstable.follows  =  "nixpkgs-unstable";
    };

  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    ...
  } @ inputs: let

    flakeTools = import ../../../lib/flake {};

  in {
    nixosConfigurations = {

      default = flakeTools.mkNixosConf {
        hostname = "wl-nix-fm";
        system = "x86_64-linux";
        nixpkgs = {
          stable = nixpkgs;
          unstable = nixpkgs-unstable;
        };
        modules = [ ./src/configuration.nix ];
        specialArgs = { inherit inputs; };
      };

    };
  };
}
