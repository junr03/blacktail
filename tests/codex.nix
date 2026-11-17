{
  gallatin,
  home-manager,
  pkgs,
}:
let
  home = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs = { inherit gallatin; };
    modules = [
      ../modules/codex.nix
      {
        home.username = "codex-test";
        home.homeDirectory = "/Users/codex-test";
        home.stateVersion = "23.11";
      }
    ];
  };
  files = home.config.home.file;
in
assert files ? ".codex/AGENTS.md";
assert files ? ".codex/agents" && files.".codex/agents".recursive;
assert files ? ".codex/keybindings.json";
assert files ? ".codex/rules/gallatin.rules";
assert home.config.home.activation ? mergeCodexConfig;
pkgs.runCommand "codex-configuration-check"
  {
    nativeBuildInputs = [ (pkgs.python3.withPackages (ps: [ ps.tomlkit ])) ];
  }
  ''
    python ${../.}/tests/test_merge_codex_config.py
    touch "$out"
  ''
