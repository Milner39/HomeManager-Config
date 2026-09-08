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

    (import ./gui args)
    (import ./work.nix args)
    (import ./vms.nix args)
  ];



  # === Profiles ===

  # None

  # === Profiles ===


  # === Hardware ===

  modules.hardware.video.intel = {
    enable = true;
  };

  # === Hardware ===


  # === Networking ===

  networking.hostName = hostname;

  modules.networking = {
    backend.networkmanager.enable = true;
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

  # Nix Helper
  programs.nh = {
    enable = true;
    package = pkgs-unstable.nh;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

  # === Nix ===




  # === Build ===

  # Disable building some docs
  documentation = {
    nixos.enable = false;
    man.enable = true;
    info.enable = false;
  };

  # === Build ===


  # === Bootloader ===

  # Use SystemD bootloader
  boot.loader = {
    systemd-boot = {
      enable = true;

      # https://search.nixos.org/options?show=boot.loader.systemd-boot.editor&type=packages
      editor = false;
    };

    efi.canTouchEfiVariables = true;
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

    # So this host can build and run aarch64 derivations.
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  # === Kernel ===


  # === Security ===

  security.polkit.enable = true;

  # === Security ===


  # === Users ===

  # Gets users options from `usersData.users.<name>.settings`
  users.users = builtins.mapAttrs
    (username: userCfg: userCfg.settings)
    (args.usersData.users);

  # === Users ===


  # === Fonts ===

  # modules.fonts.nerd-fonts = {
  #   # all = true;  # For all NerdFonts
  #   fonts = nf: with nf; [
  #     jetbrains-mono
  #   ];
  # };

  # === Fonts ===


  # === Audio ===

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    # media-session.enable = true;
  };

  # === Audio ===


  # === Battery Life ===

  powerManagement.enable = true;
  services.tlp.enable = true;

  # === Battery Life ===



  # === Global Environment ===

  # Packages
  environment.systemPackages = with pkgs; [
    # Version control
    git

    # Browsers
    brave

    # Must haves
    usbutils
    brightnessctl
    pkgs-unstable.fastfetch
    pkgs-unstable.btop
  ];

  # Programs
  programs = {
    steam.enable = true;
  };

  # === Global Environment ===

}
