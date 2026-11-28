{
  home-manager,
  pkgs,
}:
let
  fakeNode = pkgs.writeShellScriptBin "npm" ''
    printf '%s\n' "$@" > "$NPM_TEST_ARGS"
    test "''${PATH%%:*}" = "${placeholder "out"}/bin"
    exit "''${NPM_TEST_EXIT:-0}"
  '';
  mkHome =
    packages:
    home-manager.lib.homeManagerConfiguration {
      pkgs = pkgs.extend (_: _: { nodejs = fakeNode; });
      modules = [
        ../modules/npm.nix
        {
          home.username = "npm-test";
          home.homeDirectory = "/Users/npm-test";
          home.stateVersion = "23.11";
          blacktail.npm.packages = packages;
        }
      ];
    };
  empty = mkHome [ ];
  populated = mkHome [
    "@scope/package@1.2.3"
    "alias@npm:package@4.5.6"
  ];
  activation = populated.config.home.activation.installNpmPackages;
  script = pkgs.writeText "npm-activation-test.sh" ''
    set -e
    run() { "$@"; }
    ${activation.data}
  '';
in
assert !(empty.config.home.activation ? installNpmPackages);
assert builtins.elem "$HOME/.npm-packages/bin" empty.config.home.sessionPath;
assert builtins.elem "writeBoundary" activation.after;
pkgs.runCommand "npm-activation-check" { } ''
  export HOME="$TMPDIR/home with spaces"
  export NPM_TEST_ARGS="$TMPDIR/args"
  ${pkgs.bash}/bin/bash ${script}
  cat > expected <<EOF
  install
  --global
  --prefix
  $HOME/.npm-packages
  --
  @scope/package@1.2.3
  alias@npm:package@4.5.6
  EOF
  diff -u expected "$NPM_TEST_ARGS"

  # A failed npm install must fail activation too.
  status=0
  NPM_TEST_EXIT=42 ${pkgs.bash}/bin/bash ${script} || status=$?
  test "$status" -eq 42
  touch "$out"
''
