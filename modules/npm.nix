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
    { name = "rex-usage"; }

    # Add npm package specs here, optionally restricted to profiles:
    # { name = "@scope/package@1.2.3"; }
    # { name = "package@1.2.3"; profiles = [ "work" ]; }
  ];
}
