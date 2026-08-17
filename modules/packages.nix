{
  lib,
  pkgs,
  profile,
}:
let
  select =
    entries:
    map (entry: entry.package) (
      lib.filter (entry: !(entry ? profiles) || lib.elem profile entry.profiles) entries
    );
in
select (
  with pkgs;
  [
    # General packages for development and system management
    { package = bash-completion; }
    { package = coreutils; }
    { package = killall; }
    { package = fastfetch; }
    { package = openssh; }
    { package = sqlite; }
    { package = wget; }
    { package = zip; }
    { package = gh; }
    { package = terraform; }
    { package = pre-commit; }

    # Security tools
    { package = gnupg; }
    { package = libfido2; }

    # Media-related packages
    { package = ffmpeg; }
    { package = fd; }

    # Node.js development tools
    { package = prettier; }
    { package = nodejs; }

    # Text and terminal utilities
    { package = ripgrep; }
    { package = nixfmt; }
    { package = shellcheck; }
    { package = tmuxinator; }

    # Python packages
    { package = python3; }
    { package = virtualenv; }

    # Rust packages
    {
      package = pkgs.rust-bin.stable.latest.default.override {
        extensions = [ "rust-src" ];
      };
    }
    { package = rust-analyzer-unwrapped; }
    { package = pkg-config; }
  ]
)
