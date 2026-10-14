{
  lib,
  ...
}:
let
  repositories = {
    mattpocock = {
      source = builtins.fetchGit {
        url = "https://github.com/mattpocock/skills.git";
        rev = "49dd158d1076134a641b33efb035946536778336";
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
