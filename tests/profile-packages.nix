{
  lib,
  pkgs,
}:
let
  select = (import ../modules/profile-packages.nix { inherit lib; }).select;
  selected = select {
    profiles = [
      "runner"
      "personal"
    ];
    entries = [
      { name = "shared"; }
      {
        name = "personal-only";
        profiles = [ "personal" ];
      }
      {
        name = "runner-only";
        profiles = [ "runner" ];
      }
      {
        name = "work-only";
        profiles = [ "work" ];
      }
    ];
  };
in
assert
  selected == [
    "shared"
    "personal-only"
    "runner-only"
  ];
pkgs.runCommand "profile-packages-test" { } ''
  touch "$out"
''
