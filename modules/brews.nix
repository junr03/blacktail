{
  lib,
  profiles,
}:
let
  select = (import ./profile-packages.nix { inherit lib; }).select;
in
select {
  inherit profiles;
  entries = [
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
  ];
}
