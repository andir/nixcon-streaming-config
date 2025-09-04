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
  };
}
