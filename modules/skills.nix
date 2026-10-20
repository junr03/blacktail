{
  lib,
  ...
}:
let
  repositories = {
    junr03 = {
      source = builtins.fetchGit {
        url = "https://github.com/JUNERDD/skills.git";
        rev = "f76dec9eacbcea858e1d469710067020bd3fec6a";
      };
      directories = [ "skills" ];
    };
  };
in
{
  home.file = import ./skill-files.nix {
    inherit lib repositories;
  };
}
