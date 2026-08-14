{ pkgs, ... }:
{
  home-manager = {
    useGlobalPkgs = true;

    users.nixos = {
      home.stateVersion = "26.05";

      imports = [ ./companion-satellite.nix ];


      programs.plasma = {
        enable = true;

        workspace.wallpaper =
          let

            rainbowLogo = pkgs.fetchurl {
              url = "https://raw.githubusercontent.com/NixOS/nixos-artwork/9d2cdedd73d64a068214482902adea3d02783ba8/logo/nix-snowflake-rainbow.svg";
              hash = "sha256-gMeJgiSSA5hFwtW3njZQAd4OHji6kbRCJKVoN6zsRbY=";
            };

            rainbowWallpaper = pkgs.runCommand "nix-rainbow-wallpaper.png"
              {
                nativeBuildInputs = with pkgs; [ librsvg imagemagick ];
              } ''
              rsvg-convert -h 1200 ${rainbowLogo} -o logo.png
              magick logo.png -background '#2e3440' -gravity center -extent 3840x2160 $out
            '';
          in
          rainbowWallpaper;

        kscreenlocker = {
          autoLock = false;
          timeout = 0;
        };

        kwin = {
          tiling.padding = 4;
          effects = {
            desktopSwitching.animation = "off"; # slideEnabled
            minimization.animation = "off"; # squashEnabled
            windowOpenClose.animation = "off"; # scaleEnabled
          };
        };

        powerdevil.AC = {
          powerButtonAction = "nothing"; # PowerButtonAction = 0
          dimDisplay.enable = false; # DimDisplayWhenIdle=false + IdleTimeoutSec=-1
          turnOffDisplay.idleTimeout = "never"; # TurnOffDisplayIdleTimeoutSec=-1
        };
      };

      programs.plasma.configFile = {
        kwalletrc.Wallet = {
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

        plasmarc = {
          OSD.Enabled = false;
          PlasmaToolTips.Delay = -1;
        };

        kwinrc = {
          "Effect-overview".BorderActivate = 9;
          Plugins = {
            fadingpopupsEnabled = false;
            fullscreenEnabled = false;
            loginEnabled = false;
            logoutEnabled = false;
            maximizeEnabled = false;
            overviewEnabled = false;
            screenedgeEnabled = false;
            slidingpopupsEnabled = false;
            windowapertureEnabled = false;
          };
          Windows = {
            ElectricBorderMaximize = false;
            ElectricBorderTiling = false;
          };
          Xwayland.Scale = 1;
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
