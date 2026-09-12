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
    { name = "1password"; }
    { name = "1password-cli"; }
    { name = "adobe-creative-cloud"; }
    { name = "chatgpt"; }
    {
      name = "docker-desktop";
      profiles = [ "work" ];
    }
    { name = "ghostty"; }
    { name = "google-drive"; }
    { name = "insta360-link-controller"; }
    { name = "junr03/homebrew-blacktail/nuphy-io"; }
    { name = "microsoft-office"; }
    { name = "microsoft-teams"; }
    { name = "obsidian"; }
    { name = "okta-verify"; }
    { name = "postico"; }
    { name = "raycast"; }
    { name = "slack"; }
    { name = "tailscale-app"; }
    { name = "todoist-app"; }
    { name = "zed"; }
    {
      name = "zerotier-one";
      profiles = [ "work" ];
    }
    { name = "zoom"; }
  ];
}
