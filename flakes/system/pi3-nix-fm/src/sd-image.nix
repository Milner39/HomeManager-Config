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

  This brings in `fileSystems` (see `./filesystems.nix`), the bootloader
  settings, and `system.build.sdImage`.

  It composes with the `raspberry-pi-3` profile without conflict:
  - It sets `boot.loader.grub.enable = false` and
    `boot.loader.generic-extlinux-compatible.enable = true`
  - It sets `sdImage.populateFirmwareCommands` for the generic mainline
    Pi 2/3/4 path, which `hardware.raspberry-pi.firmware` then `mkForce`s away
    in favour of its own install script.
    That is what we want, and it is why `firmware.uboot.enable` has to be on.
*/
{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
  ];
}
