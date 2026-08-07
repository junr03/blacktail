{
  config,
  hostProfile,
  user,
  ...
}:
let
  xdg_configHome = "${config.users.users.${user}.home}/.config";
in
{
  ".ssh/${hostProfile.ssh.github.identityFile}.pub" = {
    text = hostProfile.ssh.github.publicKey;
  };

  ".ssh/${hostProfile.ssh.electricpeak.identityFile}.pub" = {
    text = hostProfile.ssh.electricpeak.publicKey;
  };

  "${xdg_configHome}/ghostty/config" = {
    source = ./config/ghostty;
  };
}
