{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.disko.url = "github:nix-community/disko";
  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.plasma-manager = {
    url = "github:nix-community/plasma-manager";
    inputs.home-manager.follows = "home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.treefmt-nix.url = "github:numtide/treefmt-nix";
  inputs.hws.url = "path:/home/andi/dev/private/unisheen-capture-card/unisheen";
  inputs.companion-satellite-rs =
    {
      url = "git+https://forgejo.rammhold.de/nixcon/companion-satellite-rs.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  #  inputs.companion = {
  #    url = "github:bitfocus/companion/stable-4.0";
  #    flake = false;
  #  };
  #  inputs.ontime = {
  #    url = "github:cpvalente/ontime/v4";
  #    flake = false;
  #  };
  outputs =
    { self
    , nixpkgs
    , disko
    , hws
    , companion-satellite-rs
    , treefmt-nix
    , plasma-manager,
      home-manager
    , ...
    }:
    let

      mkSystemConfig =
        { nixpkgs
        , hardwareConfig ? null
        , diskConfig ? null
        ,
        }:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            hws.nixosModules.default
            ./streamdesk
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            ({
              home-manager.sharedModules = [ plasma-manager.homeModules.plasma-manager ];
            })
            companion-satellite-rs.nixosModules.web-deck
            ({
              nixpkgs.overlays = [
                (self: _: {
                  mkHwsVendorModule = kernelPackages: kernelPackages.callPackage (hws + "/package-vendor.nix") { };
                  inherit (companion-satellite-rs.packages.${self.system}) streamdeck-satellite ulanzi-satellite;
                })
              ];
            })
          ]
          ++ (if hardwareConfig != null then [ hardwareConfig ] else [ ])
          ++ (if diskConfig != null then [ diskConfig ] else [ ]);
        };

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      treefmtEval = nixpkgs.lib.genAttrs systems (
        arch:
        let
          pkgs = nixpkgs.legacyPackages.${arch};
        in
        treefmt-nix.lib.evalModule pkgs ./treefmt.nix
      );
    in
    {
      nixosConfigurations.streamdesk = mkSystemConfig {
        inherit nixpkgs; # hardwareConfig = ./hardware-config.nix;
        diskConfig = ./disk-config.nix;
      };
      nixosConfigurations.x600 = mkSystemConfig {
        inherit nixpkgs;
        hardwareConfig = {
          imports = [
            ./streamdesk/asrock-x600-itx.nix
            ({ networking.hostName = "x600"; })
          ];
        };
        diskConfig = ./disk-config.nix;
      };
      nixosConfigurations.streamdeskNoHW = mkSystemConfig { inherit nixpkgs; };
      packages.x86_64-linux.vm = self.outputs.nixosConfigurations.streamdeskNoHW.config.system.build.vm;
      packages.x86_64-linux.liveCD =
        self.outputs.nixosConfigurations.streamdeskNoHW.config.system.build.images.iso;
      packages.x86_64-linux.liveCDStable =
        self.outputs.nixosConfigurations.streamdeskStableNoHW.config.system.build.images.iso;
      packages.x86_64-linux.install = nixpkgs.legacyPackages.x86_64-linux.writeScriptBin "install" ''
        #!/bin/sh
        git clone https://github.com/andir/nixcon-streaming-config nixcon-streaming-config
        cd nixcon-streaming-config
        sudo nixos-generate-config --no-filesystems --show-hardware-config > hardware-configuration.nix
        git add hardware-configuration.nix
        sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko#disko-install -- --flake .#streamdesk --disk main /dev/nvme0n1
      '';

      checks = {
        x600 = self.nixosConfigurations.x600.config.system.build.toplevel;
      };
      formatter = nixpkgs.lib.genAttrs systems (arch: treefmtEval.${arch}.config.build.wrapper);
      devShells = nixpkgs.lib.genAttrs systems (arch: {
        default =
          with nixpkgs.legacyPackages.${arch};
          mkShell {
            nativeBuildInputs = [
              ffmpeg_7-full
              (python3.withPackages (p: [
                p.google-api-python-client
                p.google-auth
                p.google-auth-httplib2
                p.google-auth-oauthlib
              ]))
            ];
          };
      });
    };
}
