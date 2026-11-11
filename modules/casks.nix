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
    { name = "firefox"; }
    { name = "ghostty"; }
    { name = "google-drive"; }
    { name = "google-gemini"; }
    { name = "herdr"; }
    { name = "insta360-link-controller"; }
    { name = "junr03/homebrew-blacktail/lightcraft"; }
    { name = "junr03/homebrew-blacktail/nuphy-io"; }
    { name = "microsoft-office"; }
    { name = "microsoft-teams"; }
    { name = "monitorcontrol"; }
    { name = "notion"; }
    { name = "notion-calendar"; }
    { name = "obsidian"; }
    {
      name = "postico";
      profiles = [ "work" ];
    }
    { name = "raycast"; }
    { name = "saffsanity/sill/sill"; }
    { name = "slack"; }
    { name = "superhuman"; }
    { name = "tailscale-app"; }
    { name = "todoist-app"; }
    { name = "work-louder-input"; }
    { name = "zed"; }
    { name = "zerotier-one"; }
    { name = "zoom"; }
  ];
}
