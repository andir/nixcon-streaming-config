{ config, pkgs, ... }:

{
  services.prometheus = {
    enable = false;
    port = 9090;
    listenAddress = "127.0.0.1";
    retentionTime = "30d";

    exporters.node = {
      enable = true;
      port = 9100;
      listenAddress = "[::]";
      enabledCollectors = [
        "systemd"
        "processes"
        "hwmon"
        "arp"
        "cpu"
        "diskstats"
        "ethtool"
        "filesystem"
        "interrupts"
        "slabinfo"
        "qdisc"
        "netdev"
        "sysctl"
      ];
    };
  };
  networking.firewall.allowedTCPPorts = [ 9100 ];
}
