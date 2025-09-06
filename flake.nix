{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.disko.url = "github:nix-community/disko";
  outputs = { self, nixpkgs, disko, ... }: {
    nixosConfigurations.streamdesk = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./streamdesk
        disko.nixosModules.disko
        ./disk-config.nix
        ./hardware-configuration.nix
      ];
    };
    packages.liveCD.x86_64-linux = self.outputs.nixosConfigurations.streamdesk.config.system.build.images.iso;
    packages.default.install = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (arch: nixpkgs.legacyPackages.${arch}.writeScriptBin "install" ''
      #!/bin/sh
      git clone https://github.com/andir/nixcon-streaming-config nixcon-streaming-config
      cd nixcon-streaming-config
      sudo nixos-generate-config --no-filesystems --show-hardware-config > hardware-configuration.nix
      git add hardware-configuration.nix
      sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko#disko-install -- --flake .#streamdesk --disk main /dev/nvme0n1
    '');
  };
}
