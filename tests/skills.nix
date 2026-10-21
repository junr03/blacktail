{
  gallatin,
  lib,
  pkgs,
}:
let
  skillModule = import "${gallatin}/skills" {
    inherit lib;
  };
  skillFiles = skillModule.home.file;
  allFilesHaveSkillManifest = lib.all (file: builtins.pathExists (file.source + "/SKILL.md")) (
    builtins.attrValues skillFiles
  );
in
assert skillFiles != { };
assert allFilesHaveSkillManifest;
pkgs.runCommand "skills-module-check" { } "mkdir -p $out"
