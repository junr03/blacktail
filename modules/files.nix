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
  onePasswordAgentItems = lib.unique (
    [ hostProfile.git.signingKey ]
    ++ lib.mapAttrsToList (_: identity: identity.identityFile) hostProfile.ssh
  );
  onePasswordAgentConfig =
    lib.concatMapStrings (item: ''
      [[ssh-keys]]
      item = "${item}"
    '') onePasswordAgentItems
    + ''
      [[ssh-keys]]
      vault = "blacktail"
    '';
  sshPublicKeyFiles = lib.mapAttrs' (
    _: identity:
    lib.nameValuePair "${userHome}/.ssh/${identity.identityFile}.pub" {
      source = hostProfile.keysDirectory + "/${identity.identityFile}.pub";
    }
  ) hostProfile.ssh;
in
{
  "${xdg_configHome}/ghostty/config" = {
    source = ./config/ghostty;
  };
  "${xdg_configHome}/1Password/ssh/agent.toml" = {
    text = onePasswordAgentConfig;
  };
  "${userHome}/.ssh/${hostProfile.git.signingKey}.pub" = {
    source = hostProfile.keysDirectory + "/${hostProfile.git.signingKey}.pub";
  };
}
// sshPublicKeyFiles
