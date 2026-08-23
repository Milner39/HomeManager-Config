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

  };
in
{
  imports = [
    # For WSL
    inputs.wsl.nixosModules.default    

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



  # === Nix ===

  nix = {
    settings = {
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




  # === WSL ===

  wsl.enable = true;
  wsl.defaultUser = "nixos";

  # Hardware Acceleration
  wsl.useWindowsDriver = true;
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  hardware.graphics.package = pkgs.mesa;
  hardware.graphics.extraPackages = with pkgs; [
    libvdpau-va-gl
    libva-vdpau-driver
  ];
  environment.sessionVariables.LD_LIBRARY_PATH = [
    "/run/opengl-driver/lib"
    "${pkgs.openssl.out}/lib"
  ];
  environment.sessionVariables.GALLIUM_DRIVER = "d3d12";
  environment.sessionVariables.MESA_D3D12_DEFAULT_ADAPTER_NAME = "Nvidia";

  # For VSCode
  programs.nix-ld.enable = true;

  # === WSL ===


  # === Build ===

  # Disable building some docs
  documentation = {
    nixos.enable = false;
    man.enable = true;
    info.enable = false;
  };

  # === Build ===


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

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # === Networking ===


  # === Security ===

  security.polkit.enable = true;

  # === Security ===


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



  # === Global Environment ===

  # Packages
  environment.systemPackages = with pkgs; [
    # Version control
    git
    gh

    # Browsers
    firefox
    brave

    # Must haves
    brightnessctl
    pkgs-unstable.fastfetch
    pkgs-unstable.btop
  ];

  # Programs
  programs = {

  };

  # === Global Environment ===

}
