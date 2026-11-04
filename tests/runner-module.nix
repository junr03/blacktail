{
  gallatinRunners,
  lib,
  pkgs,
}:
let
  patch = import ../modules/runner-bootstrap.nix { inherit lib; };
  original = "/usr/bin/su -s /bin/bash -l runner -c command";
  upstream = builtins.functionArgs (import "${gallatinRunners}/darwin-github-runner.nix");
  wrapper = builtins.functionArgs (import ../modules/runner-module.nix);
in
assert upstream ? config && upstream ? lib && upstream ? pkgs;
assert wrapper ? gallatinRunners && wrapper ? lib && wrapper ? pkgs;
assert patch original == "/usr/bin/sudo -n -u runner -H /bin/bash -lc command";
assert !(builtins.tryEval (patch "unexpected upstream script")).success;
pkgs.runCommand "runner-module-test" { } "touch $out"
