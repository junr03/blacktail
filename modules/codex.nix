{
  gallatin,
  lib,
  pkgs,
  ...
}:
let
  codexConfig = pkgs.callPackage "${gallatin}/codex.nix" { };
  python = pkgs.python3.withPackages (ps: [ ps.tomlkit ]);
in
{
  home.file = {
    ".codex/AGENTS.md".source = "${codexConfig}/AGENTS.md";
    ".codex/agents" = {
      source = "${codexConfig}/agents";
      recursive = true;
    };
    ".codex/keybindings.json".source = "${codexConfig}/keybindings.json";
    # Keep Codex's locally approved commands in default.rules intact.
    ".codex/rules/gallatin.rules".source = "${codexConfig}/rules/default.rules";
  };

  home.activation.mergeCodexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${python}/bin/python ${./merge-codex-config.py} \
      ${codexConfig}/config.shared.toml "$HOME/.codex/config.toml"
  '';
}
