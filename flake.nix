{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.nixpkgs-2505.url = "github:nixos/nixpkgs/nixos-25.05";
  inputs.disko.url = "github:nix-community/disko";
  inputs.companion = {
    url = "github:bitfocus/companion/stable-4.0";
    flake = false;
  };
  outputs = { self, nixpkgs, nixpkgs-2505, disko, companion, ... }: let

    mkSystemConfig = { nixpkgs, hardwareConfig ? null }: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./streamdesk
        disko.nixosModules.disko
        ./disk-config.nix
#        ./hardware-configuration.nix
      ];
    };
  in {
    nixosConfigurations.streamdesk = mkSystemConfig { inherit nixpkgs; hardwareConfig = ./hardware-config.nix; };
    nixosConfigurations.streamdeskNoHW = mkSystemConfig { inherit nixpkgs; };
    nixosConfigurations.streamdeskStableNoHW = mkSystemConfig { nixpkgs = nixpkgs-2505; };
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
