{
  inputs = {

    nixpkgs.url           =  "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url  =  "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-modules = {
      url = "github:Milner39/nix-modules/release-26.05";
      inputs.nixpkgs.follows           =  "nixpkgs";
      inputs.nixpkgs-unstable.follows  =  "nixpkgs-unstable";
    };

    cisco-packet-tracer = {
      url = "path:../../package/cisco-packet-tracer";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    ...
  } @ inputs: let

    flakeTools = import ../../../lib/flake {};

  in {
    homeConfigurations = {

      default = flakeTools.mkHomeConf {
        username = "finnm";
        system = "x86_64-linux";
        home-manager = home-manager;
        nixpkgs = {
          stable = nixpkgs;
          unstable = nixpkgs-unstable;
        };
        modules = [ ./src/home.nix ];
        extraSpecialArgs = { inherit inputs; };
      };

    };
  };
}
