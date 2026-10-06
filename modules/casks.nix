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
    { name = "claude"; }
    {
      name = "docker-desktop";
      profiles = [ "work" ];
    }
    {
      name = "figma";
      profiles = [ "work" ];
    }
    { name = "ghostty"; }
    { name = "google-drive"; }
    { name = "granola"; }
    { name = "insta360-link-controller"; }
    { name = "junr03/homebrew-blacktail/nuphy-io"; }
    { name = "szamowski-dev/tap/hora"; }
    { name = "microsoft-office"; }
    { name = "microsoft-teams"; }
    { name = "monitorcontrol"; }
    { name = "obsidian"; }
    { name = "okta-verify"; }
    { name = "openscad@snapshot"; }
    { name = "postico"; }
    {
      name = "postman";
      profiles = [ "work" ];
    }
    { name = "raycast"; }
    { name = "slack"; }
    { name = "tailscale-app"; }
    { name = "todoist-app"; }
    { name = "work-louder-input"; }
    { name = "zed"; }
    {
      name = "zerotier-one";
      profiles = [ "work" ];
    }
    { name = "zoom"; }
  ];
}
