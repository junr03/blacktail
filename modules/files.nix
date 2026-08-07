{
  user,
  pkgs,
  config,
  ...
}:
let
  xdg_configHome = "${config.users.users.${user}.home}/.config";
  xdg_dataHome = "${config.users.users.${user}.home}/.local/share";
  xdg_stateHome = "${config.users.users.${user}.home}/.local/state";
  githubPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFepB8gnsQw2fqna5epnucL2/UBL+1pQoh26GlKH29ye recruiting@junr03.com";
  electricpeakPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHVuvU35QsaFextBWDvK/Bsz+2YGwpMO+J4dFZMukuj7 admin@electricpeak.net";
in
{
  ".ssh/github.pub" = {
    text = githubPublicKey;
  };

  ".ssh/electricpeak.pub" = {
    text = electricpeakPublicKey;
  };

  "${xdg_configHome}/ghostty/config" = {
    source = ./config/ghostty;
  };
}
