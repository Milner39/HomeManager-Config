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
  virtualisation = {
    libvirtd = {
      enable = true;
      package = pkgs.libvirt;

      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = false;

        swtpm = {
          enable = true;
          package = pkgs.swtpm;
        };
      };
    };
  };

  programs.virt-manager.enable = true;

  boot.kernelModules = [ "kvm-intel" ];
}