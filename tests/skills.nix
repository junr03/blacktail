{
  lib,
  pkgs,
  source,
}:
let
  skillFiles = import ../modules/skill-files.nix {
    inherit lib;
    repositories.mattpocock = {
      inherit source;
      directories = [ "skills" ];
    };
  };
  allFilesHaveSkillManifest = lib.all (file: builtins.pathExists (file.source + "/SKILL.md")) (
    builtins.attrValues skillFiles
  );
in
assert skillFiles != { };
assert allFilesHaveSkillManifest;
pkgs.runCommand "skills-module-check" { } "mkdir -p $out"
