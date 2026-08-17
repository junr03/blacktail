{
  lib,
  profile,
}:
let
  select =
    entries:
    map (entry: entry.name) (
      lib.filter (entry: !(entry ? tags) || lib.elem profile entry.tags) entries
    );
in
select [
  { name = "argocd"; }
  { name = "awscli"; }
  { name = "git-spice"; }
  { name = "go"; }
  { name = "gptfdisk"; }
  { name = "jira-cli"; }
  { name = "watch"; }
  { name = "worktrunk"; }
  { name = "xcodegen"; }
  { name = "yq"; }
]
