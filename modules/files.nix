{
  config,
  user,
  ...
}:
let
  xdg_configHome = "${config.users.users.${user}.home}/.config";
in
{
  "${xdg_configHome}/ghostty/config" = {
    source = ./config/ghostty;
  };
}
