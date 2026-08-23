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


    # Import modules that can be configured under the `modules` option.
    # This is a special function that recursively builds a "tree" of options 
    # based on the directory structure of choice.
    # https://github.com/Milner39/nix-utils
    (inputs.my-utils.lib.${system}.mkOptionTreeFromDir {
      configRoot = config;
      optionTreeName = "modules";
      modulesDir = lib.custom.fromRoot "modules/nixos";
      specialArgs = args;
    })

    (import ./gui args)
  ];



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
  };

  # === Kernel ===


  # === Hardware ===

  # For proprietary firmware (fix WiFi cards)
  hardware.enableRedistributableFirmware = true;


  modules.hardware.video.nvidia = {
    enable = true;
  };

  # === Hardware ===


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
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # === Networking ===


  # === Security ===

  security.polkit.enable = true;


  modules.security.passwords.passwd-persist = {
    enable = true;
    users = args.usersData.passwd-persist-users;
  };

  # === Security ===


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



  # === Global Environment ===

  # Packages
  environment.systemPackages = with pkgs; [
    # Version control
    git
    gh

    # Terminals
    kitty

    # Editors
    vscode

    # Browsers
    firefox
    brave

    # Must haves
    pkgs-unstable.fastfetch
    pkgs-unstable.btop
  ];

  # Programs
  programs = {

  };

  # === Global Environment ===

}