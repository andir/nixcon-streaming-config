{ pkgs, ... }:
{
  systemd.services.ontime = {
    script = ''
      export HOME=/var/lib/ontime
      exec ${pkgs.ontime}/bin/ontime
    '';
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      DynamicUser = true;
      User = "ontime";
      Group = "ontime";
      StateDirectory = "ontime";
      RuntimeDirectory = "/var/lib/ontime";
    };
  };
}
