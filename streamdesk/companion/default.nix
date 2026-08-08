{ pkgs, ... }:
let
  spec = {
    imageName = "ghcr.io/bitfocus/companion/companion";
    imageDigest = "sha256:8d4968d537d788fc48e37d6fdf4466c91be7a36f9108f48665b73f10253633c3";
    hash = "sha256-avlkeTXEAFmMDQ3UndOGEpQoTRVBRXMi7Ex4+IbcaJY=";
    finalImageName = "ghcr.io/bitfocus/companion/companion";
    finalImageTag = "5.1.0-9664-main-18291cbf27";
  };
  image = pkgs.dockerTools.pullImage spec;
in
{
  systemd.tmpfiles.rules = [
    "d /var/lib/companion 0755 1000 1000 -"
  ];
  virtualisation.oci-containers.containers.companion = {
    autoStart = true;
    image = spec.imageName;
    imageFile = image;
    volumes = [
      "/var/lib/companion:/companion"
    ];
    ports = [
      "8000:8000"
      "16622:16622"
      "16623:16622"
    ];
  };
  systemd.services.companion-ipv6 = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.socat ];
    script = ''
      exec socat TCP6-LISTEN:8000,reuseaddr,fork,ipv6only=1 TCP:localhost:8000
    '';
    serviceConfig.DynamicUser = true;
  };
  networking.firewall.allowedTCPPorts = [ 8000 ];
}
