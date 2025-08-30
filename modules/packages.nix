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
  neofetch
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
  noto-fonts-emoji
  meslo-lgs-nf

  # Node.js development tools
  nodePackages.npm # globally install npm
  nodePackages.prettier
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
  nixfmt-rfc-style

  # Python packages
  python3
  virtualenv
  dockutil
]
