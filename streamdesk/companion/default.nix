{ pkgs, ... }:
{
  virtualisation.oci-containers.containers.companion = {
    autoStart = false;
    image = "ghcr.io/bitfocus/companion/companion:4.1.0-8356-main-c340bb5ed5" /* pkgs.fetchdocker {
      registry = "https://ghcr.io";
      repository = "bitfocus";
      imageName = "companion";
      tag = "4.1.0-8356-main-c340bb5ed5";
    } */ ;
  };
}
