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
  { name = "1password"; }
  { name = "1password-cli"; }
  { name = "adobe-creative-cloud"; }
  { name = "chatgpt"; }
  { name = "docker-desktop"; }
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
  { name = "zerotier-one"; }
  { name = "zoom"; }
]
