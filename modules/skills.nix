{
  config,
  gallatin,
  lib,
  ...
}:
let
  cfg = config.blacktail.skills;
  shared = (import "${gallatin}/skills" { inherit lib; }).home.file;
  repositories = import "${gallatin}/skills/skill-files.nix" {
    inherit lib;
    inherit (cfg) repositories;
  };
  individual = lib.mapAttrs' (
    name: source: lib.nameValuePair ".agents/skills/${name}" { inherit source; }
  ) cfg.individual;
  groups = [
    shared
    repositories
    individual
  ];
  names = lib.concatMap builtins.attrNames groups;
  duplicates = lib.unique (lib.filter (name: lib.count (other: other == name) names > 1) names);
in
{
  options.blacktail.skills = {
    repositories = lib.mkOption {
      default = { };
      description = "Additional skill repositories or materialized source directories.";
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            source = lib.mkOption { type = lib.types.path; };
            directories = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [
                ".agents/skills"
                "skills"
              ];
            };
          };
        }
      );
    };
    individual = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = "Additional named skill directories containing SKILL.md.";
    };
  };

  config = {
    assertions = lib.mapAttrsToList (name: source: {
      assertion =
        builtins.match "[A-Za-z0-9._-]+" name != null
        && name != "."
        && name != ".."
        && builtins.pathExists (source + "/SKILL.md");
      message = "Skill ${name} must have a safe name and contain SKILL.md.";
    }) cfg.individual;
    home.file =
      if duplicates != [ ] then
        throw "Duplicate skill destinations: ${lib.concatStringsSep ", " duplicates}"
      else
        lib.foldl' (all: group: all // group) { } groups;
  };
}
