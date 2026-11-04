{ lib }:
text:
let
  replacements = {
    "/usr/bin/su -s /bin/bash -l" = "/usr/bin/sudo -n -u";
    " -c " = " -H /bin/bash -lc ";
  };
in
assert lib.all (needle: lib.hasInfix needle text) (builtins.attrNames replacements);
builtins.replaceStrings (builtins.attrNames replacements) (builtins.attrValues replacements) text
