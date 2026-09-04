{
  lib,
  ...
}:

lib.custom.users.mkUsersData {
  users = {

    # === root ===
    root = {
      settings = {
        # Make sure special `root` user options are forced
        uid = 0;
        isSystemUser = true;
        home = "/root";
        #
      };

      trusted = true;
    };
    # === root ===


    # === nixos ===
    nixos = {
      settings = {
        description = "Finn Milner";
        isNormalUser = true;
        extraGroups = [
          "wheel"  # Sudo
          "networkmanager"  # Network Config
        ];

        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHGydLwle8HWBT5Y6vuaEK4th4R/2h0Ih+j5WDoERGbD"
        ];

        # ALWAYS CHANGE AFTER THE USER IS FIRST CREATED!!!
        initialPassword = "tmp";
      };

      trusted = true;
    };
    # === nixos ===

  };
}
