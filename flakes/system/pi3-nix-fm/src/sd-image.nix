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

/*
  Only imported by the `sd-image` config.

  This brings in `fileSystems` (see `./filesystems.nix`) and
  `system.build.sdImage`.

  The generic `sd-image.nix` rather than `sd-image-aarch64.nix`, which wraps it
  in `profiles/base.nix`, the installation-CD package set: ZFS, testdisk,
  cryptsetup, tcpdump and ~20 more, none of which belong on this card. Nothing
  else that file provides is needed here:
  - `boot.loader.grub.enable = false` and
    `generic-extlinux-compatible.enable = true` come from the `raspberry-pi-3`
    profile
  - its `boot.kernelParams` console entries do too
  - its `boot.consoleLogLevel = mkDefault 7` is overridden in
    `./configuration.nix` anyway
  - its `sdImage.populateFirmwareCommands` is `mkForce`d away by
    `hardware.raspberry-pi.firmware`, which is why `firmware.uboot.enable` has
    to be on
*/
{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image.nix"
  ];


  /*
    `linux-firmware` plus every SATA/PATA initrd module, none of which exist on 
    a Pi 3 booting from SD.
  */
  hardware.enableAllHardware = lib.mkForce false;


  /*
    The one thing `sd-image-aarch64.nix` provided that is needed.
    `populateRootCommands` has no default, so it must be set: it writes
    `extlinux.conf` plus the kernel and initrd into the root partition.
  */
  sdImage.populateRootCommands = ''
    mkdir -p ./files/boot
    ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
  '';
}
