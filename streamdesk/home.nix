{
  home-manager = {
    useGlobalPkgs = true;

    users.nixos = {
      home.stateVersion = "26.05";

      imports = [ ./companion-satellite.rs ];

      # ensure KDE doesn't ever go to sleep, disable active corners, ....
      qt.kde.settings = {
        kwalletrc = {
          Wallet = {
            "Close When Idle" = false;
            "Close on Screensaver" = false;
            "Enabled" = false;
            "Idle Timeout" = 10;
            "Launch Manager" = false;
            "Leave Manager Open" = false;
            "Leave Open" = true;
            "Prompt on Open" = false;
            "Use One Wallet" = true;
          };
        };
        kscreenlockerrc = {
          Daemon = {
            Autolock = false;
            Timeout = 0;
          };
        };
        plamsarc = {
          OSD.Enabled = false;
          PlamsaToolTips.Delay = -1;
        };
        kwinrc = {
          Effect-overview.BorderActivate = 9;
          Plugins = {
            fadingpopupsEnabled = false;
            fullscreenEnabled = false;
            loginEnabled = false;
            logoutEnabled = false;
            maximizeEnabled = false;
            overviewEnabled = false;
            scaleEnabled = false;
            screenedgeEnabled = false;
            slideEnabled = false;
            slidingpopupsEnabled = false;
            squashEnabled = false;
            windowapertureEnabled = false;
          };
          Tiling.padding = 4;
          Windows = {
            ElectricBorderMaximize = false;
            ElectricBorderTiling = false;
            XWayland.Scale = 1;
          };
        };
        powerdevilrc = {
          AC.Display = {
            DimDisplayIdleTimeoutSec = -1;
            DimDisplayWhenIdle = false;
            TurnOffDisplayIdleTimeoutSec = -1;
            TurnOffDisplayWhenIdle = false;
          };
          AC.SuspendAndShutdown = {
            PowerButtonAction = 0;
          };
        };
      };

      # configure the firefox profile to contain uBlock Origin & some bookmarks
      programs.firefox = {
        enable = true;
        profiles.default = {
          bookmarks = {
            force = true;
            settings = [
              {
                name = "Ontime";
                tags = [
                  "ontime"
                  "time"
                ];
                keyword = "ontime";
                # FIXME: update for 2026
                url = "http://localhost:4001/editor";
              }
              "separator"
              {
                name = "Pads";
                tags = [ "pad" ];
                keyword = "pads";
                url = "https://pad.lassul.us/dc_kC6hEQai20cOIZ5JeTg";
              }
              "separator"
              {
                name = "Syncthing";
                tags = [ "Syncthing" ];
                keyword = "syncthing";
                url = "http://localhost:8384";
              }
            ];
          };
        };
        policies = {
          ExtensionSettings = {
            "uBlock0@raymondhill.net" = {
              default_area = "menupanel";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
              installation_mode = "force_installed";
              private_browsing = true;
            };
          };
        };
      };
      services.syncthing = {
        enable = true;
      };
    };
  };
}
