{
  lib,
  mattpocockSkills,
  ...
}:
{
  home.file = import ./skill-files.nix {
    inherit lib;
    repositories = {
      mattpocock = {
        source = mattpocockSkills;
        directories = [ "skills" ];
      };
    };
  };
}
