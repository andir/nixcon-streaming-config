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
    companion-satellite-ulanzi = {
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
