{
  config,
  lib,
  pkgs,
  pkgs-unstable,

  # extraSpecialArgs
  username,
  system,
  inputs,
  ...
} @ args:

{
  home.pointerCursor = {
    enable = true;
    package = pkgs-unstable.bibata-cursors;
    name = "Bibata-Modern-Ice";
  };

  home.sessionVariables = {
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = 24;
  };

  modules.gui = {
    window-manager.hyprland.enable = true;
    window-manager.niri.enable = true;
    menu.rofi.enable = true;
    screenshot.custom.enable = true;
  };
}
