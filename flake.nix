{
  description = "Nix configuration for Mac Clients";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    hashicorp-tap = {
      url = "github:hashicorp/homebrew-tap";
      flake = false;
    };
    gallatin = {
      url = "github:junr03/gallatin?rev=7281e93b508c432fc2e83aa1c5250fe5ee92f8c9";
      flake = false;
    };
  };
  outputs =
    {
      darwin,
      determinate,
      gallatin,
      home-manager,
      homebrew-bundle,
      homebrew-cask,
      homebrew-core,
      hashicorp-tap,
      nix-homebrew,
      nix-vscode-extensions,
      nixpkgs,
      rust-overlay,
      self,
    }@inputs:
    let
      darwinSystems = [ "aarch64-darwin" ];
      hostProfiles = {
        personal = import ./hosts/junr03.nix;
        work = import ./hosts/jose-rivera.nix;
      };
      toolSystems = darwinSystems ++ [ "x86_64-linux" ];
      forAllToolSystems = f: nixpkgs.lib.genAttrs toolSystems f;
      devShell =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default =
            with pkgs;
            mkShell {
              packages = [
                bashInteractive
                git
                nixfmt
                pre-commit
                shellcheck
              ];
            };
        };
      mkApp =
        scriptName: system:
        let
          app = nixpkgs.legacyPackages.${system}.writeShellApplication {
            name = scriptName;
            text = ''
              exec ${self}/apps/${scriptName} "$@"
            '';
          };
        in
        {
          type = "app";
          program = "${app}/bin/${scriptName}";
        };
      mkDarwinApps = system: {
        build = mkApp "build" system;
        build-switch = mkApp "build-switch" system;
        create-keys = mkApp "create-keys" system;
        rollback = mkApp "rollback" system;
      };
      mkDarwinConfiguration =
        hostProfile:
        darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = inputs // {
            inherit hostProfile;
          };
          modules = [
            {
              nixpkgs.overlays = [
                nix-vscode-extensions.overlays.default
                rust-overlay.overlays.default
              ];
            }
            determinate.darwinModules.default
            ./modules/host.nix
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                user = hostProfile.username;
                enable = true;
                taps = {
                  "homebrew/homebrew-core" = homebrew-core;
                  "homebrew/homebrew-cask" = homebrew-cask;
                  "homebrew/homebrew-bundle" = homebrew-bundle;
                  "hashicorp/homebrew-tap" = hashicorp-tap;
                };
                mutableTaps = false;
              };
            }
          ];
        };
      darwinConfigurations = nixpkgs.lib.mapAttrs (_: mkDarwinConfiguration) hostProfiles;
    in
    {
      inherit darwinConfigurations;

      apps = nixpkgs.lib.genAttrs darwinSystems mkDarwinApps;
      checks = nixpkgs.lib.genAttrs darwinSystems (
        _: nixpkgs.lib.mapAttrs (_: configuration: configuration.system) darwinConfigurations
      );
      devShells = forAllToolSystems devShell;
      formatter = forAllToolSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
