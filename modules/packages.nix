{ pkgs }:
with pkgs;
[
  # General packages for development and system management
  bash-completion
  coreutils
  killall
  fastfetch
  openssh
  sqlite
  wget
  zip
  gh
  terraform
  pre-commit

  # Security tools
  gnupg
  libfido2

  # Media-related packages
  ffmpeg
  fd

  # Node.js development tools
  prettier
  nodejs

  # Text and terminal utilities
  ripgrep
  nixfmt
  shellcheck
  tmuxinator

  # Python packages
  python3
  virtualenv

  # Rust packages
  (pkgs.rust-bin.stable.latest.default.override {
    extensions = [ "rust-src" ];
  })
  rust-analyzer-unwrapped
  pkg-config
]
