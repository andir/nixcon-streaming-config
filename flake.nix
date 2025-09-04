{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.disko.url = "github:nix-community/disko";
  # nix run github:nix-community/nixos-anywhere -- --flake <path to configuration>    #<configuration name> --vm-test
  outputs = { self, nixpkgs, disko, ... }: {
    nixosConfigurations.streamdesk = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ./streamdesk
      ];
    };
    packages.liveCD.x86_64-linux = self.outputs.nixosConfigurations.streamdesk.config.system.build.images.iso;
  };
}
