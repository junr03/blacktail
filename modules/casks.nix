{
  lib,
  profile,
}:
let
  select = (import ./profile-packages.nix { inherit lib; }).select;
in
select {
  inherit profile;
  entries = [
    { name = "1password"; }
    { name = "1password-cli"; }
    { name = "adobe-creative-cloud"; }
    {
      name = "bluebubbles";
      profiles = [ "personal" ];
    }
    { name = "chatgpt"; }
    {
      name = "docker-desktop";
      profiles = [ "work" ];
    }
    { name = "ghostty"; }
    { name = "google-drive"; }
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
