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

let
  # Extend args
  args = baseArgs // {
    usersData = (import ./users.nix baseArgs);
  };
in
{
  imports = [
    /*
      No `hardware-configuration.nix`: there is nothing to scan on this board.
      `nixos-hardware.nixosModules.raspberry-pi-3` (added in `flake.nix`) covers
      the kernel, initrd modules and wireless firmware, and `fileSystems` come
      from either `./filesystems.nix` or `./sd-image.nix`.
    */

    (inputs.nix-modules.lib.nixosModuleTree {})

    (import ./gui args)
  ];



  # === Profiles ===

  modules.profiles.minimal = {
    enable = true;
    rebuildable = false;
  };

  # === Profiles ===


  # === Kernel ===

  # Mainline instead of the profile's from-source `linux-rpi`.
  # Dropping this to go back to the vendor kernel means also dropping the
  # `useGenerationDeviceTree` force. See ../README.md.
  boot.kernelPackages = pkgs.linuxPackages;

  # `sd-image-aarch64.nix` raises this to 7, which floods the console.
  # Raise back to 7 to debug an early boot problem. See ../README.md.
  boot.consoleLogLevel = 4;

  # === Kernel ===


  # === Bootloader ===

  # Old generations keep their kernel + initrd in /boot on the root partition,
  # using up storage.
  boot.loader.generic-extlinux-compatible.configurationLimit = 3;

  # Loads the DTB shipped with the running kernel instead of the vendor one.
  # MUST match the kernel choice. See ../README.md.
  boot.loader.generic-extlinux-compatible.useGenerationDeviceTree = lib.mkForce true;

  # REQUIRED. Without it the image gets no U-Boot and no `config.txt`
  # `kernel=` line, and the board silently does not boot. See ../README.md.
  hardware.raspberry-pi.firmware.uboot.enable = true;

  # === Bootloader ===


  # === Hardware ===

  # Comes from `github:nixos/nixos-hardware`

  # Repopulates the firmware partition on every `nixos-rebuild switch`.
  # Needs `/boot/firmware` mounted, see `./filesystems.nix`.
  hardware.raspberry-pi.firmware.enable = true;

  # Serial console, to give a headless board some output on a failed boot.
  hardware.raspberry-pi.configtxt.settings.all.enable_uart = true;

  hardware.enableRedistributableFirmware = false;

  # === Hardware ===


  # === Memory ===

  # Needed on Pi with 1GB of RAM
  zramSwap.enable = true;

  # === Memory ===


  # === Networking ===

  networking.hostName = hostname;

  modules.networking = {
    backend.networkd.enable = true;
    wireless.iwd.enable = true;
    directLink.enable = true;
  };

  services.openssh.enable = true;

  # === Networking ===


  # === Locale ===

  # Use default UK settings
  modules.locale.enable = true;

  # === Locale ===




  # === Nix ===

  nix = {
    settings = {
      trusted-users = args.usersData.trusted-users;

      experimental-features = [ "nix-command" "flakes" ];
      accept-flake-config = true;

      cores = 0;  # Use all
      max-jobs = "auto";

      auto-optimise-store = true;
    };

    # Garbage collection
    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
  };


  system.stateVersion = "26.05";

  # === Nix ===


  # === Users ===

  # Gets users options from `usersData.users.<name>.settings`
  users.users = builtins.mapAttrs
    (username: userCfg: userCfg.settings)
    (args.usersData.users);

  # === Users ===


  # === Global Environment ===

  # Packages
  environment.systemPackages = with pkgs; [
    # Version control
    git

    # Must haves
    pkgs-unstable.fastfetch
    pkgs-unstable.btop
  ];

  # === Global Environment ===
}
