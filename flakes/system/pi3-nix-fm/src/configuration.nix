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


  # === Networking ===

  networking.hostName = hostname;

  modules.hardware.networking.networkd.enable = true;
  modules.hardware.networking.wireless.iwd.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Allow direct link connections
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    nssmdns6 = true;
    openFirewall = true;

    publish = { 
      enable = true;
      addresses = true;
    };
  };

  # === Networking ===



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


  # === Bootloader ===

  # Bootloader itself comes from the `raspberry-pi-3` profile.

  # Old generations keep their kernel + initrd in /boot on the root partition.
  boot.loader.generic-extlinux-compatible.configurationLimit = 3;

  # Loads the DTB shipped with the running kernel instead of the vendor one.
  # MUST match the kernel choice below. See ../README.md.
  boot.loader.generic-extlinux-compatible.useGenerationDeviceTree = lib.mkForce true;

  # === Bootloader ===


  # === Kernel ===

  # Mainline instead of the profile's from-source `linux-rpi`.
  # Dropping this to go back to the vendor kernel means also dropping the
  # `useGenerationDeviceTree` force above. See ../README.md.
  boot.kernelPackages = pkgs.linuxPackages;

  # `sd-image-aarch64.nix` raises this to 7, which floods the console.
  # Raise back to 7 to debug an early boot problem. See ../README.md.
  boot.consoleLogLevel = 4;

  # === Kernel ===


  # === Hardware ===

  # Firmware provided by `nixos-hardware` in flake
  hardware.enableRedistributableFirmware = false;

  hardware.raspberry-pi.firmware = {
    # Repopulates the firmware partition on every `nixos-rebuild switch`.
    # Needs `/boot/firmware` mounted, see `./filesystems.nix`.
    enable = true;

    # REQUIRED. Without it the image gets no U-Boot and no `config.txt`
    # `kernel=` line, and the board silently does not boot. See ../README.md.
    uboot.enable = true;
  };

  # Serial console, to give a headless board some output on a failed boot.
  hardware.raspberry-pi.configtxt.settings.all.enable_uart = true;

  # === Hardware ===


  # === Memory ===

  # 1GB of RAM, and swapping to an SD card is painful.
  # Compressed swap in RAM is a much better here.
  zramSwap.enable = true;

  # === Memory ===


  # === Users ===

  # Gets users options from `usersData.users.<name>.settings`
  users.users = builtins.mapAttrs
    (username: userCfg: userCfg.settings)
    (args.usersData.users);

  # === Users ===


  # === Locale ===

  time.timeZone = "Europe/London";

  i18n = let
    locale = "en_GB.UTF-8";
  in
  {
    defaultLocale = locale;
    extraLocaleSettings = {
      LC_ADDRESS = locale;
      LC_IDENTIFICATION = locale;
      LC_MEASUREMENT = locale;
      LC_MONETARY = locale;
      LC_NAME = locale;
      LC_NUMERIC = locale;
      LC_PAPER = locale;
      LC_TELEPHONE = locale;
      LC_TIME = locale;
    };
  };

  # Configure console keyMap
  console.keyMap = "uk";

  # === Locale ===


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
