{
  config,
  lib,
  pkgs,
  pkgs-unstable,

  # extraSpecialArgs
  system,
  username,
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
    (inputs.nix-modules.lib.homeModuleTree {})

    (import ./gui.nix args)
  ];



  # === Home Manager ===

  home = {
    username = username;
    homeDirectory = "/home/${username}";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "26.05"; # Please read the comment before changing.

  # === Home Manager ===




  # Packages
  home.packages = with pkgs; [
    liberation_ttf

    obsidian
    obs-studio
    shotcut
    mpv
    pkgs-unstable.ncspot

    inputs.cisco-packet-tracer.packages.${system}.cisco-packet-tracer
  ];


  # Shells
  modules.programs.shells = {
    zsh = {
      enable = true;
      preferred = true;  # Sets `$SHELL`
    };
    bash.enable = true;

    ui.oh-my-posh.enable = true;
  };


  # Terminals
  modules.programs.terminals = {
    ghostty = {
      enable = true;
      preferred = true;  # Sets `$TERMINAL`
    };
  };


  # File Explorers
  modules.programs.file-explorers = {
    yazi = {
      enable = true;
    };
  };


  # Text Editors
  modules.programs.text-editors = {
    vscode = {
      enable = true;
      preferred = true;  # Sets `$EDITOR`
    };
  };


  # Dev Tools
  modules.programs.dev = {
    git.enable = true;
  };


  # Fonts
  modules.fonts.nerd-fonts = {
    # all = true;  # For all NerdFonts
    fonts = nf: with nf; [
      jetbrains-mono
    ];
  };


  # Other
  modules.gaming.installers.steam.enable = true;
}
