{
  description = "Nix configuration for Mac Clients";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
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
      nix-homebrew,
      nix-vscode-extensions,
      nixpkgs,
      rust-overlay,
      self,
    }@inputs:
    let
      localPrimaryUser = builtins.getEnv "BLACKTAIL_PRIMARY_USER";
      primaryUser =
        if localPrimaryUser == "" then
          "junr03"
        else if builtins.match "[a-zA-Z_][a-zA-Z0-9._-]*" localPrimaryUser != null then
          localPrimaryUser
        else
          throw "BLACKTAIL_PRIMARY_USER must be a valid macOS short username";
      darwinSystems = [ "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs darwinSystems f;
      devShell =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default =
            with pkgs;
            mkShell {
              nativeBuildInputs = with pkgs; [
                bashInteractive
                git
              ];
              shellHook = with pkgs; ''
                export EDITOR=code
              '';
            };
        };
      mkApp = scriptName: system: {
        type = "app";
        program = "${
          (nixpkgs.legacyPackages.${system}.writeScriptBin scriptName ''
            #!/usr/bin/env bash
            PATH=${nixpkgs.legacyPackages.${system}.git}/bin:$PATH
            echo "Running ${scriptName} for ${system}"
            exec ${self}/apps/${scriptName}
          '')
        }/bin/${scriptName}";
      };
      mkDarwinApps = system: {
        "apply" = mkApp "apply" system;
        "build" = mkApp "build" system;
        "build-switch" = mkApp "build-switch" system;
        "rollback" = mkApp "rollback" system;
      };
    in
    {
      devShells = forAllSystems devShell;
      apps = nixpkgs.lib.genAttrs darwinSystems mkDarwinApps;
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      darwinConfigurations = nixpkgs.lib.genAttrs darwinSystems (
        system:
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = inputs // {
            inherit primaryUser;
          };
          modules = [
            {
              nixpkgs.overlays = [
                nix-vscode-extensions.overlays.default
                rust-overlay.overlays.default
              ];
            }
            determinate.darwinModules.default
            ./modules/host.nix # Load host first to ensure Rosetta activation script runs before Homebrew
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                user = primaryUser;
                enable = true;
                taps = {
                  "homebrew/homebrew-core" = homebrew-core;
                  "homebrew/homebrew-cask" = homebrew-cask;
                  "homebrew/homebrew-bundle" = homebrew-bundle;
                };
                mutableTaps = false;
                autoMigrate = true;
              };
            }
          ];
        }
      );
    };
}
