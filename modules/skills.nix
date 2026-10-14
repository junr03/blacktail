{
  lib,
  skillRepositories,
  ...
}:
let
  repositories = lib.mapAttrs' (
    name: source:
    lib.nameValuePair (lib.removeSuffix "Skills" name) {
      inherit source;
    }
  ) skillRepositories;
in
{
  home.file = import ./skill-files.nix {
    inherit lib repositories;
  };
}
