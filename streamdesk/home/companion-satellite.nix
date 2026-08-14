{ lib, pkgs, ... }: {
  systemd.user.services = {
    companion-satellite = {
      Unit = {
        Description = "Companion satellite rewritten in rust";
        After = "graphical-session.target";
        PartOf = "graphical-session.target";
      };
      Install.WantedBy = [ "graphical-session.target" ];

      Service = {
        ExecStart = "${lib.getExe pkgs.streamdeck-satellite}";
      };
    };

    # cheap chinese knock-off we don't want to use. It works but
    # sometimes defaults to some builtin screen an requires a replug /
    # explicit push of new images.
    companion-satellite-ulanzi = lib.mkIf false {
      Unit = {
        Description = "Companion satellite rewritten in rust for the ulanzi device";
        After = "graphical-session.target";
        PartOf = "graphical-session.target";
      };
      Install.WantedBy = [ "graphical-session.target" ];

      Service = {
        ExecStart = "${lib.getExe pkgs.ulanzi-satellite}";
      };
    };
  };

}
