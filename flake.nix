{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.nixpkgs-2505.url = "github:nixos/nixpkgs/nixos-25.05";
  inputs.disko.url = "github:nix-community/disko";
  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.companion = {
    url = "github:bitfocus/companion/stable-4.0";
    flake = false;
  };
  inputs.ontime = {
    url = "github:cpvalente/ontime/v4";
    flake = false;
  };
  outputs = { self, nixpkgs, nixpkgs-2505, disko, companion, ontime, home-manager, ... }: let

    mkSystemConfig = { nixpkgs, hardwareConfig ? null, diskConfig ? null }: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./streamdesk
        disko.nixosModules.disko
        home-manager.nixosModules.home-manager
        ({
          nixpkgs.overlays = [(_: _: {
            ontime = self.packages.ontime.x86_64-linux.runScript;
          })];
        })
      ] ++ (if hardwareConfig != null then [ hardwareConfig ] else [])
      ++ (if diskConfig != null then [ diskConfig ] else [])
      ;
    };
  in {
    nixosConfigurations.streamdesk = mkSystemConfig { inherit nixpkgs; hardwareConfig = ./hardware-config.nix; diskConfig = ./disk-config.nix; };
    nixosConfigurations.streamdeskNoHW = mkSystemConfig { inherit nixpkgs; };
    nixosConfigurations.streamdeskStableNoHW = mkSystemConfig { nixpkgs = nixpkgs-2505; };
    packages.vm.x86_64-linux = self.outputs.nixosConfigurations.streamdeskNoHW.config.system.build.vm;
    packages.liveCD.x86_64-linux = self.outputs.nixosConfigurations.streamdeskNoHW.config.system.build.images.iso;
    packages.liveCDStable.x86_64-linux = self.outputs.nixosConfigurations.streamdeskStableNoHW.config.system.build.images.iso;
    packages.default.install = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (arch: nixpkgs.legacyPackages.${arch}.writeScriptBin "install" ''
      #!/bin/sh
      git clone https://github.com/andir/nixcon-streaming-config nixcon-streaming-config
      cd nixcon-streaming-config
      sudo nixos-generate-config --no-filesystems --show-hardware-config > hardware-configuration.nix
      git add hardware-configuration.nix
      sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko#disko-install -- --flake .#streamdesk --disk main /dev/nvme0n1
    '');

    devShells = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux"] (arch: {
      default =  with nixpkgs.legacyPackages.${arch}; mkShell {
        nativeBuildInputs = [
          
          (writeShellScriptBin "update-companion" ''
            mkdir -p companion
            exec ${yarn-berry_4.yarn-berry-fetcher}/bin/yarn-berry-fetcher missing-hashes ${companion}/yarn.lock > companion/missing-hashes.json
          '')
        ];
      };
    });
    packages.ontime = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux"] (arch: with nixpkgs.legacyPackages.${arch}; stdenv.mkDerivation (finalAttrs: {
      pname = "ontime";
      version = "4-nix-${ontime.rev}";
      src = ontime;
      nativeBuildInputs = [
        nodejs
        pnpm
        pnpm.configHook
      ];
      pnpmDeps = pnpm.fetchDeps {
          inherit (finalAttrs) pname version src;
          fetcherVersion = 2;
          hash = "sha256-8B0MbVDH8jLOXxtm4aqBux/swW6vY0ixpV5oU5IHsm4=";
      };
      env = {
        ELECTRON_SKIP_BINARY_DOWNLOAD = true;
        NODE_ENV = "prod";
      };
      buildPhase = ''
        (cd apps/client && pnpm addversion && pnpm build)
        (cd apps/server && pnpm addversion && pnpm build:docker)
        mkdir -p $out
        cp -rv apps/client/build $out/client

        cp -rv apps/server/dist $out/server
        cp -rv apps/server/src/external $out/external
        cp -rv apps/server/src/html $out/html
      '';

      testPhase = ''
        node $out/server/index.cjs --help
      '';
      passthru.runScript = writeShellScriptBin "ontime" ''
        cd ${self.packages.ontime.${arch}}
        exec ${nodejs}/bin/node server/docker.cjs "$@"
      '';
    }));

    packages.companion = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux"] (arch: with nixpkgs.legacyPackages.${arch}; let
      yarn-berry = yarn-berry_4;
    in stdenv.mkDerivation (finalAttrs: {
      src = companion;
      pname = "companion";
      version = "4.0-${companion.rev}";
      missingHashes = ./companion/missing-hashes.json;


      offlineCache = yarn-berry.fetchYarnBerryDeps {
        inherit (finalAttrs) src missingHashes;
        hash = "sha256-9+unG7z6YpsN7NuVC8b76Uj/I4IRwa7hkpAvN+JrpLI=";
      };

      patches = [
        ./companion/0001-Use-environment-information-for-git-revision-in-vers.patch
        ./companion/0002-Remove-binary-copying.patch
      ];

      env = {
        NIX_SRC_REV = companion.rev;
        ELECTRON_SKIP_BINARY_DOWNLOAD = true;
        npm_config_build_from_source = "true";
        NIX_CFLAGS_COMPILE="-I${lib.getDev libusb1}/include/libusb-1.0";
        dontUseCmakeConfigure = 1;
        npm_config_node_gyp = "${nodejs}/lib/node_modules/npm/node_modules/node-gyp/bin/node-gyp.js";
        mitmCache = mitm-cache.fetch {
            data = {
                "https://github.com/libjpeg-turbo/libjpeg-turbo/archive/refs/tags/3.0.1.tar.gz" = {
                    hash = "sha256-W5u8orKofGYyyCF5lDjTWOJwBKtSir95hTPBXVCzn4I=";
                };
            };
        };
      };

      buildInputs = [
        python3
        systemd
        libusb1
      ];

      ignoreMissingDeps = [ "libc.musl-x86_64.so.1" ];

      buildPhase = ''
        autoPatchelf node_modules/sass-embedded-linux-*
        yarn dist
      '';

      installPhase = ''
        cp -rv dist $out
      '';
      nativeBuildInputs = [
        cmake
        nodejs
        yarn-berry
        yarn-berry.yarnBerryConfigHook
        electron
        autoPatchelfHook
        mitm-cache
      ];
    }));
  };
}
