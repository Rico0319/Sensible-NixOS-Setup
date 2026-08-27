{
  description = "Sensible NixOS setup — my machines, declaratively.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Only used for packages that move faster than the stable release
    # (currently: pi-coding-agent).
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager }: {
    # Add more hosts by adding directories under hosts/ and more entries here.
    nixosConfigurations.server = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/server
        ./modules/base.nix

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.ricoz = import ./home {
            unstable = nixpkgs-unstable.legacyPackages.x86_64-linux;
          };
        }
      ];
    };
  };
}
