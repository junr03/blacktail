args@{
  gallatinRunners,
  lib,
  pkgs,
  ...
}:
let
  patchBootstrap = import ./runner-bootstrap.nix { inherit lib; };
in
import "${gallatinRunners}/darwin-github-runner.nix" (
  args
  // {
    pkgs = pkgs // {
      writeShellScript =
        name: text:
        pkgs.writeShellScript name (
          if lib.hasPrefix "gallatin-github-runner-" name && lib.hasSuffix "-bootstrap" name then
            patchBootstrap text
          else
            text
        );
    };
  }
)
