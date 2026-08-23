{
  inputs = {

    nixpkgs.url           =  "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url  =  "github:nixos/nixpkgs/nixos-unstable";

    my-utils = {
      url = github:Milner39/nix-utils/release-1.0;
      inputs.nixpkgs.follows = "nixpkgs";
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

      "hd-nix-fm" = flakeTools.mkNixosConf {
        hostname = "hd-nix-fm";
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