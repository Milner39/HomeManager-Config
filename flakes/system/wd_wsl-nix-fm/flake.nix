{
  inputs = {

    nixpkgs.url           =  "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url  =  "github:nixos/nixpkgs/nixos-unstable";

    wsl = {
      url = "github:nix-community/nixos-wsl";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

      default = flakeTools.mkNixosConf {
        hostname = "wd_wsl-nix-fm";
        system = "x86_64-linux";
        nixpkgs = {
          stable = nixpkgs;
          unstable = nixpkgs-unstable;
        };

        overlays = [
          (final: prev: {
            # https://lists.buildroot.org/pipermail/buildroot/2026-March/799494.html
            mesa = prev.mesa.overrideAttrs (old: {
              mesonFlags = (old.mesonFlags or []) ++ [
                "-Dlegacy-wayland=bind-wayland-display"
              ];
            });
          })
        ];

        modules = [ ./src/configuration.nix ];
        specialArgs = { inherit inputs; };
      };

    };
  };
}
