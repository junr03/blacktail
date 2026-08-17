{
  lib,
  pkgs,
  profile,
}:
let
  select =
    entries:
    map (entry: entry.name) (
      lib.filter (entry: !(entry ? profiles) || lib.elem profile entry.profiles) entries
    );
in
select (
  with pkgs;
  [
    # General packages for development and system management
    { name = bash-completion; }
    { name = coreutils; }
    { name = killall; }
    { name = fastfetch; }
    { name = openssh; }
    { name = sqlite; }
    { name = wget; }
    { name = zip; }
    { name = gh; }
    { name = terraform; }
    { name = pre-commit; }
    { name = nil; }

    # Security tools
    { name = gnupg; }
    { name = libfido2; }

    # Media-related packages
    { name = ffmpeg; }
    { name = fd; }

    # Node.js development tools
    { name = prettier; }
    { name = nodejs; }

    # Text and terminal utilities
    { name = ripgrep; }
    { name = nixfmt; }
    { name = shellcheck; }
    { name = tmuxinator; }

    # Python packages
    { name = python3; }
    { name = virtualenv; }

    # Rust packages
    {
      name = pkgs.rust-bin.stable.latest.default.override {
        extensions = [ "rust-src" ];
      };
    }
    { name = rust-analyzer-unwrapped; }
    { name = pkg-config; }
  ]
)
