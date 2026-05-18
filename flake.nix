{
  description = "My Home Manager Flake";

  inputs = {
    # The DPI-bypassing nixpkgs URL that worked
    nixpkgs.url = "https://channels.nixos.org/nixos-25.11/nixexprs.tar.xz";

    # Home Manager
    home-manager = {
      url = "git+https://github.com/nix-community/home-manager.git?ref=release-25.11"; 
      inputs.nixpkgs.follows = "nixpkgs"; 
    };
    
    # nixgl
    nixgl = {
      url = "https://github.com/nix-community/nixGL/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, nixgl, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations.vkolli = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        extraSpecialArgs = { inherit nixgl; };

        # Specify your home configuration modules here
        modules = [ ./home.nix ];

        # Optionally use extraSpecialArgs to pass arguments to home.nix
        # extraSpecialArgs = { inherit inputs; };
      };
    };
}
