{
  config,
  hostProfile,
  lib,
  pkgs,
  ...
}:
let
  user = hostProfile.username;
  userHome = "/Users/${user}";
  userFiles = import ./files.nix { inherit config hostProfile user; };
in
{
  users.users.${user} = {
    name = user;
    home = userHome;
    isHidden = false;
    shell = pkgs.zsh;
  };

  homebrew = {
    enable = true;
    casks = pkgs.callPackage ./casks.nix { };
    brews = pkgs.callPackage ./brews.nix { };
    taps = builtins.attrNames config.nix-homebrew.taps;

    onActivation = {
      autoUpdate = false;
      cleanup = "check";
      upgrade = true;
    };

    # These app IDs are from using the mas CLI app
    # mas = mac app store
    # https://github.com/mas-cli/mas
    #
    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    #
    # If you have previously added these apps to your Mac App Store profile (but not installed them on this system),
    # you may receive an error message "Redownload Unavailable with This Apple ID".
    # This message is safe to ignore.

    masApps = {
      "photomator" = 1444636541;
    };
  };

  home-manager = {
    backupFileExtension = hostProfile.homeManager.backupFileExtension;
    useGlobalPkgs = true;
    users.${user} =
      {
        pkgs,
        config,
        lib,
        ...
      }:
      {
        home = {
          file = userFiles;
          sessionPath = [
            "$HOME/.pnpm-packages/bin"
            "$HOME/.pnpm-packages"
            "$HOME/.npm-packages/bin"
            "$HOME/bin"
            "$HOME/.local/share/bin"
          ];
          sessionVariables = {
            ALTERNATE_EDITOR = "";
            EDITOR = "code";
            HISTIGNORE = "pwd:ls:cd";
            VISUAL = "code";
          };
          stateVersion = "23.11";
        };
        programs = {
          zsh = {
            enable = true;
            autocd = false;
            cdpath = [ "~/.local/share/src" ];
            plugins = [
              {
                name = "powerlevel10k";
                src = pkgs.zsh-powerlevel10k;
                file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
              }
              {
                name = "powerlevel10k-config";
                src = lib.cleanSource ./config;
                file = "p10k.zsh";
              }
            ];
            shellAliases = {
              ll = "ls -lh --color=auto";

              # Use difftastic for diffing
              diff = "difft";

              # Use ghostscript for PDF compression
              compress-pdf = ''
                compress_pdf() {
                  if [ $# -ne 2 ]; then
                    echo "Usage: compress-pdf <input.pdf> <output.pdf>"
                    return 1
                  fi
                  gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$2" "$1"
                }; compress_pdf
              '';
            };
            initContent = lib.mkBefore ''
              # nix shortcuts
              shell() {
                if (( $# != 1 )); then
                  echo "Usage: shell <package>"
                  return 1
                fi

                nix shell "nixpkgs#$1"
              }

              # pnpm is a javascript package manager
              alias pn=pnpm
              alias px=pnpx

              # Always color ls and group directories
              alias ls='ls --color=auto'

              # Path to iCloud Drive
              alias icloud='cd $HOME/Library/Mobile\ Documents/com~apple~CloudDocs'
            '';
          };
          git = {
            enable = true;
            ignores = [ "*.swp" ];
            lfs = {
              enable = true;
            };
            settings = {
              user = {
                name = hostProfile.git.name;
                email = hostProfile.git.email;
              };
              init.defaultBranch = "main";
              core = {
                editor = "vim";
                autocrlf = "input";
              };
              commit.gpgsign = false;
              pull.rebase = true;
              rebase.autoStash = true;
            };
          };
          vim = {
            enable = true;
            plugins = with pkgs.vimPlugins; [
              vim-airline
              vim-airline-themes
              vim-startify
              vim-tmux-navigator
            ];
            settings = {
              ignorecase = true;
            };
            extraConfig = ''
              "" General
              set number
              set history=1000
              set modelines=0
              set encoding=utf-8
              set scrolloff=3
              set showmode
              set showcmd
              set hidden
              set wildmenu
              set wildmode=list:longest
              set cursorline
              set ttyfast
              set nowrap
              set ruler
              set backspace=indent,eol,start
              set laststatus=2
              set clipboard=autoselect

              " Dir stuff
              set nobackup
              set nowritebackup
              set noswapfile

              " Relative line numbers for easy movement
              set relativenumber

              "" Whitespace rules
              set tabstop=8
              set shiftwidth=2
              set softtabstop=2
              set expandtab

              "" Searching
              set incsearch
              set gdefault

              "" Statusbar
              let g:airline_theme='bubblegum'
              let g:airline_powerline_fonts = 1

              "" Local keys and such
              let mapleader=","
              let maplocalleader=" "

              "" Change cursor on mode
              :autocmd InsertEnter * set cul
              :autocmd InsertLeave * set nocul

              "" File-type highlighting and configuration
              syntax on
              filetype plugin indent on

              "" Paste from clipboard
              nnoremap <Leader>, "+gP

              "" Copy from clipboard
              xnoremap <Leader>. "+y

              "" Move cursor by display lines when wrapping
              nnoremap j gj
              nnoremap k gk

              "" Map leader-q to quit out of window
              nnoremap <leader>q :q<cr>

              "" Move around split
              nnoremap <C-h> <C-w>h
              nnoremap <C-j> <C-w>j
              nnoremap <C-k> <C-w>k
              nnoremap <C-l> <C-w>l

              "" Easier to yank entire line
              nnoremap Y y$

              "" Move buffers
              nnoremap <tab> :bnext<cr>
              nnoremap <S-tab> :bprev<cr>

              "" Like a boss, sudo AFTER opening the file to write
              cmap w!! w !sudo tee % >/dev/null

              let g:startify_lists = [
                \ { 'type': 'dir',       'header': ['   Current Directory '. getcwd()] },
                \ { 'type': 'sessions',  'header': ['   Sessions']       },
                \ { 'type': 'bookmarks', 'header': ['   Bookmarks']      }
                \ ]

              let g:startify_bookmarks = [
                \ '~/.local/share/src',
                \ ]
            '';
          };
          ssh = {
            enable = true;
            enableDefaultConfig = false;

            settings = {
              "*" = {
                ForwardAgent = false;
                AddKeysToAgent = "no";
                Compression = false;
                ServerAliveInterval = 0;
                ServerAliveCountMax = 3;
                HashKnownHosts = true;
                UserKnownHostsFile = "~/.ssh/known_hosts";
              };

              "${hostProfile.ssh.github.host}" = {
                IdentitiesOnly = true;
                IdentityFile = "${userHome}/.ssh/${hostProfile.ssh.github.identityFile}";
              };

              "${hostProfile.ssh.electricpeak.host}" = {
                IdentitiesOnly = true;
                IdentityFile = "${userHome}/.ssh/${hostProfile.ssh.electricpeak.identityFile}";
              };
            };
          };
          tmux = {
            enable = true;
            plugins = with pkgs.tmuxPlugins; [
              vim-tmux-navigator
              sensible
              yank
              prefix-highlight
              {
                plugin = power-theme;
                extraConfig = ''
                  set -g @tmux_power_theme 'gold'
                '';
              }
              {
                plugin = resurrect; # Used by tmux-continuum

                # Use XDG data directory
                # https://github.com/tmux-plugins/tmux-resurrect/issues/348
                extraConfig = ''
                  set -g @resurrect-dir '$HOME/.cache/tmux/resurrect'
                  set -g @resurrect-capture-pane-contents 'on'
                  set -g @resurrect-pane-contents-area 'visible'
                '';
              }
              {
                plugin = continuum;
                extraConfig = ''
                  set -g @continuum-restore 'on'
                  set -g @continuum-save-interval '5' # minutes
                '';
              }
            ];
            terminal = "screen-256color";
            prefix = "C-x";
            escapeTime = 10;
            historyLimit = 50000;
            extraConfig = ''
              # Remove Vim mode delays
              set -g focus-events on

              # Enable full mouse support
              set -g mouse on

              # -----------------------------------------------------------------------------
              # Key bindings
              # -----------------------------------------------------------------------------

              # Unbind default keys
              unbind C-b
              unbind '"'
              unbind %

              # Split panes, vertical or horizontal
              bind-key x split-window -v
              bind-key v split-window -h

              # Move around panes with vim-like bindings (h,j,k,l)
              bind-key -n M-k select-pane -U
              bind-key -n M-h select-pane -L
              bind-key -n M-j select-pane -D
              bind-key -n M-l select-pane -R

              bind-key -T copy-mode-vi 'C-h' select-pane -L
              bind-key -T copy-mode-vi 'C-j' select-pane -D
              bind-key -T copy-mode-vi 'C-k' select-pane -U
              bind-key -T copy-mode-vi 'C-l' select-pane -R
              bind-key -T copy-mode-vi 'C-\\' select-pane -l
            '';
          };
          vscode = {
            enable = true;

            profiles.default = {
              # Optional: You can also include user settings here
              userSettings = {
                "[rust]"."editor.defaultFormatter" = "rust-lang.rust-analyzer";
                "editor.formatOnSave" = true;
                "rust-analyzer.checkOnSave" = true;
                "rust-analyzer.check.command" = "clippy";
                "workbench.colorTheme" = "Gruvbox Dark Medium";
                "extensions.autoCheckUpdates" = true;
                "extensions.autoUpdate" = true;
                "github.copilot.nextEditSuggestions.enabled" = true;
                "terminal.integrated.fontFamily" = "FiraCode Nerd Font";
                "terminal.integrated.fontSize" = 14;
                "terminal.integrated.fontWeight" = "normal";
                "editor.fontFamily" = "FiraCode Nerd Font, 'Courier New', monospace";
                "editor.fontSize" = 14;
                "editor.fontLigatures" = true;
                "editor.fontWeight" = "400";
              };

              extensions = with pkgs.vscode-marketplace; [
                jdinhlife.gruvbox
                rust-lang.rust-analyzer
                jnoortheen.nix-ide
                openai.chatgpt
              ];
            };
          };
        };

      };
  };
}
