{ lib, ... }:
{
  programs.rex = {
    enable = true;
    config = builtins.readFile ./init.lua;
  };

  programs.zsh.initContent = lib.mkAfter ''
    # Rex sets REX_BIN_DIR for its terminals; Nix shell setup can replace PATH.
    if [[ -n "$REX_BIN_DIR" ]]; then
      export PATH="$REX_BIN_DIR:$PATH"
    fi
  '';

}
