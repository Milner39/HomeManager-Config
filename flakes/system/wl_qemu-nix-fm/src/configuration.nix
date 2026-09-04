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
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    (inputs.nix-modules.lib.nixosModuleTree {})
  ];



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


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

  # === Nix ===




  # === Bootloader ===

  boot.loader = {
    grub = {
      enable = true;
      device = "/dev/vda";
    };
  };

  # === Bootloader ===


  # === Kernel ===

  boot = {
    # Chose Linux kernel version
    # https://www.kernel.org

    # Kernel versions in `pkgs` are tied to the specific `nixpkgs` release
    # currently being used, so make sure to update `nixpkgs` if you want a more
    # up-to-date kernel version.

    # mainline / stable  =  `pkgs.linuxPackages_latest`
    # latest LTS         =  `pkgs.linuxPackages`
    # specific version   =  `pkgs.linuxPackages_X_X`
    kernelPackages = pkgs.linuxPackages;
  };

  # === Kernel ===


  # === Networking ===

  networking = {
    hostName = hostname;

    # Enable networking
    networkmanager = {
      enable = true;
      package = pkgs.networkmanager;

      # WiFi options
      wifi = {
        powersave = false;
        backend = "iwd";
      };
    };
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # === Networking ===


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
    # defaultCharset = "UTF-8";
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


  # === Battery Life ===

  powerManagement.enable = true;
  services.tlp.enable = true;

  # === Battery Life ===



  # === Global Environment ===

  # Packages
  environment.systemPackages = with pkgs; [
    # Version control
    git

    # Must haves
    usbutils
    pkgs-unstable.fastfetch
    pkgs-unstable.btop
  ];

  # === Global Environment ===
}
