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
  (pre-commit.overrideAttrs (_: {
    doCheck = false;
  }))

  # Encryption and security tools
  age
  age-plugin-yubikey
  gnupg
  libfido2

  # Media-related packages
  dejavu_fonts
  ffmpeg
  fd
  fira-code
  nerd-fonts.fira-code
  font-awesome
  meslo-lgs-nf

  # Node.js development tools
  prettier
  nodejs

  # Text and terminal utilities
  ripgrep
  tmux
  zsh-powerlevel10k
  nixfmt

  # Python packages
  python3
  virtualenv
  dockutil

  # Rust packages
  (pkgs.rust-bin.stable.latest.default.override {
    extensions = [ "rust-src" ];
  })
  rust-analyzer-unwrapped
  pkg-config
]
