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


    # === finnm ===
    finnm = {
      settings = {
        description = "Finn Milner";
        isNormalUser = true;
        extraGroups = [
          "wheel"  # Sudo
          "networkmanager"  # Network Config
        ];

        openssh.authorizedKeys.keys = [
        ];

        # ALWAYS CHANGE AFTER THE USER IS FIRST CREATED!!!
        initialPassword = "tmp";
      };

      trusted = true;
    };
    # === finnm ===
  };
}
