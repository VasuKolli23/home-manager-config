{
  description = "My Home Manager Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager"; 
      inputs.nixpkgs.follows = "nixpkgs"; 
    };
    
    # nixgl
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lazyvim = {
      url = "github:pfassina/lazyvim-nix";
    };
  };

  outputs = { nixpkgs, home-manager, nixgl, lazyvim, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations.vkolli = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        extraSpecialArgs = { inherit nixgl lazyvim; };

        # Specify your home configuration modules here
        modules = [ ./home.nix ];

        # Optionally use extraSpecialArgs to pass arguments to home.nix
        # extraSpecialArgs = { inherit inputs; };
      };
    };
}
