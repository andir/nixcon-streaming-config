{ config, pkgs, ... }:

{
  services.prometheus = {
    enable = true;
    port = 9090;
    listenAddress = "127.0.0.1";
    retentionTime = "30d";

    exporters.node = {
      enable = true;
      port = 9100;
      listenAddress = "127.0.0.1";
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

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{
          targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
        }];
      }
    ];
  };

  services.grafana = {
    enable = true;

    settings = {
      server = {
        http_addr = "::";
        http_port = 3000;
        domain = "localhost";
      };
      security.secret_key = "whatevaerasdfasdfsadf";
      "auth.anonymous" = {
        enabled = true;
        org_name = "Main Org.";
        org_role = "Viewer";
        hide_version = true;
      };

      users = {
        allow_sign_up = false;
        allow_org_create = false;
        viewers_can_edit = false;
        default_theme = "dark";
      };

      dashboards.default_home_dashboard_path = "${./node-exporter-dashboard.json}";

      analytics.reporting_enabled = false;
      snapshots.external_enabled = false;
    };

    provision.datasources.settings.datasources = [{
      name = "Prometheus";
      type = "prometheus";
      uid = "prometheus";
      url = "http://127.0.0.1:${toString config.services.prometheus.port}";
      isDefault = true;
    }];
  };
}
