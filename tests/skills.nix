{
  gallatin,
  home-manager,
  lib,
  pkgs,
}:
let
  mkHome =
    extra:
    home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit gallatin; };
      modules = [
        ../modules/skills.nix
        {
          home.username = "skills-test";
          home.homeDirectory = "/Users/skills-test";
          home.stateVersion = "23.11";
          blacktail.skills = extra;
        }
      ];
    };
  shared = (mkHome { }).config.home.file;
  configured =
    (mkHome {
      repositories.local.source = ./fixtures/skills-repository;
      individual.materialized = ./fixtures/materialized;
    }).config.home.file;
  duplicate = builtins.tryEval (
    builtins.deepSeq
      (mkHome {
        repositories.local.source = ./fixtures/skills-repository;
        individual.extra-skill = ./fixtures/materialized;
      }).config.home.file
      true
  );
  sharedName = lib.removePrefix ".agents/skills/" (builtins.head (builtins.attrNames shared));
  sharedDuplicate = builtins.tryEval (
    builtins.deepSeq (mkHome { individual.${sharedName} = ./fixtures/materialized; }).config.home.file
      true
  );
in
assert shared != { };
assert lib.all (name: builtins.hasAttr name configured) (builtins.attrNames shared);
assert configured ? ".agents/skills/extra-skill";
assert configured ? ".agents/skills/materialized";
assert !duplicate.success;
assert !sharedDuplicate.success;
pkgs.runCommand "skills-module-check" { } "mkdir -p $out"
