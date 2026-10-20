{
  lib,
  ...
}:
let
  repositories = {
    junr03 = {
      source = builtins.fetchGit {
        url = "https://github.com/junr03/skills.git";
        rev = "f1a08a0c90850d34689194f40fdc0ad18b987eb1";
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
