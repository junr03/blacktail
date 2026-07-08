{ pkgs }:
with pkgs;
[
  # General packages for development and system management
  aspell
  aspellDicts.en
  bash-completion
  bat
  btop
  coreutils
  killall
  fastfetch
  openssh
  sqlite
  wget
  zip
  gh
  pre-commit

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
  hack-font
  noto-fonts
  noto-fonts-color-emoji
  meslo-lgs-nf

  # Node.js development tools
  prettier
  nodejs

  # Text and terminal utilities
  htop
  hunspell
  iftop
  jq
  ripgrep
  tree
  tmux
  unrar
  unzip
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
