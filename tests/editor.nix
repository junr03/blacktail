{
  gallatin,
  home-manager,
  pkgs,
  rex,
}:
let
  username = "editor-test";
  host = import ../modules/home-manager.nix {
    config.users.users.${username}.home = "/Users/${username}";
    inherit gallatin pkgs rex;
    inherit (pkgs) lib;
    hostProfile = {
      inherit username;
      ssh = { };
      keysDirectory = ./fixtures;
      git = {
        signingKey = "editor-test";
        signer = "ssh-keygen";
        name = "Editor Test";
        email = "editor@example.test";
      };
    };
    hostProfileLineage = [ "personal" ];
  };
  home = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs = { inherit gallatin rex; };
    modules = [
      host.home-manager.users.${username}
      {
        home.username = username;
        home.homeDirectory = "/Users/${username}";
        # This check exercises editor defaults without building GUI applications
        # or installing profile-specific files.
        programs.vscode.enable = pkgs.lib.mkForce false;
        home.file = pkgs.lib.mkForce { };
      }
    ];
  };
  cfg = home.config;
in
assert cfg.home.sessionVariables.EDITOR == "nvim";
assert cfg.home.sessionVariables.VISUAL == "nvim";
assert cfg.programs.git.settings.core.editor == "nvim";
assert cfg.programs.neovim.enable && cfg.programs.neovim.viAlias && cfg.programs.neovim.vimAlias;
assert !cfg.programs.vim.enable;
assert cfg.home.activation ? lazyvimPlugins;
pkgs.runCommand "editor-configuration-check" { } ''
  touch "$out"
''
