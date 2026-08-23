{
  config,
  lib,
  pkgs,
  pkgs-unstable,

  # specialArgs
  system,
  hostname,
  inputs,
  ...
} @ baseArgs:

{
  services.samba = {
    enable = true;
    package = pkgs.samba4Full;
  };

  services.resolved = {
    enable = true;
  };

  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openconnect
  ];

  environment.systemPackages = with pkgs; [
    samba4Full
    rustdesk
    networkmanagerapplet
  ];

  programs.obs-studio = {
    enable = true;
    package = pkgs.obs-studio;

    enableVirtualCamera = true;
  };
}
