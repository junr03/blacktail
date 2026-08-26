{
  config,
  hostProfile,
  lib,
  user,
  ...
}:
let
  userHome = config.users.users.${user}.home;
  xdg_configHome = "${userHome}/.config";
  sshPublicKeyFiles = lib.mapAttrs' (
    _: identity:
    lib.nameValuePair "${userHome}/.ssh/${identity.identityFile}.pub" {
      source = ../keys/${identity.identityFile}.pub;
    }
  ) hostProfile.ssh;
in
{
  "${xdg_configHome}/ghostty/config" = {
    source = ./config/ghostty;
  };
}
// sshPublicKeyFiles
