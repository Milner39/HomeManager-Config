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
  Only imported by the running system, never by the SD image, since
  `sd-image.nix` declares both of these itself without `mkDefault`.

  The labels must match what the image writes:
  `sdImage.rootVolumeLabel` defaults to "NIXOS_SD" and
  `sdImage.firmwarePartitionName` defaults to "FIRMWARE".
*/
{
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };

    "/boot/firmware" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";

      /*
        `nofail` only, deliberately not `noauto` as `sd-image.nix` uses.

        `hardware.raspberry-pi.firmware.enable` adds an activation script that
        writes into `/boot/firmware` on every `nixos-rebuild switch`. If the
        partition is not mounted, that write silently lands on the root
        filesystem instead and the firmware partition is never updated.
      */
      options = [ "nofail" ];
    };
  };
}
