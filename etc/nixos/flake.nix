{
  description = "DarkR NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    polymc.url = "github:PolyMC/PolyMC";
  };

  outputs = { self, nixpkgs, polymc }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ./configuration.nix
      ];

      specialArgs = {
        inherit polymc;
      };
    };
  };
}
