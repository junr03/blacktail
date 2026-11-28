{
  config,
  lib,
  pkgs,
  ...
}:
let
  packages = config.blacktail.npm.packages;
in
{
  options.blacktail.npm.packages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "npm package specs to install globally during Home Manager activation.";
  };

  config = {
    home.sessionPath = [ "$HOME/.npm-packages/bin" ];
    home.activation.installNpmPackages = lib.mkIf (packages != [ ]) (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.coreutils}/bin/env PATH="${pkgs.nodejs}/bin:$PATH" \
          ${pkgs.nodejs}/bin/npm install --global --prefix "$HOME/.npm-packages" \
          -- ${lib.escapeShellArgs packages}
      ''
    );
  };
}
