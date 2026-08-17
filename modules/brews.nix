{
  lib,
  profile,
}:
let
  select =
    entries:
    map (entry: entry.name) (
      lib.filter (entry: !(entry ? profiles) || lib.elem profile entry.profiles) entries
    );
in
select [
  {
    name = "argocd";
    profiles = [ "work" ];
  }
  { name = "awscli"; }
  { name = "git-spice"; }
  { name = "go"; }
  { name = "gptfdisk"; }
  {
    name = "jira-cli";
    profiles = [ "work" ];
  }
  { name = "watch"; }
  { name = "worktrunk"; }
  { name = "xcodegen"; }
  { name = "yq"; }
]
