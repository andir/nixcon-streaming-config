{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations.streamdesk = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./streamdesk
      ];
    };
    packages.liveCD.x86_64-linux = self.outputs.nixosConfigurations.streamdesk.config.system.build.images.iso;
  };
}
