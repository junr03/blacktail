{
  config,
  gallatin,
  hostProfile,
  hostProfileLineage,
  lib,
  pkgs,
  rex,
  ...
}:
let
  user = hostProfile.username;
  userHome = "/Users/${user}";
  # Shared configuration files and profile-supplied public keys.
  userFiles = import ./files.nix {
    inherit
      config
      hostProfile
      lib
      user
      ;
  };
in
{
  users.users.${user} = {
    name = user;
    home = userHome;
    isHidden = false;
    shell = pkgs.zsh;
  };

  # Nix system packages from packages.nix are wired in host.nix.
  # Homebrew selections are wired here and installed during Darwin activation.
  homebrew = {
    enable = true;
    # Homebrew casks selected for this profile.
    casks = import ./casks.nix {
      inherit lib;
      profiles = hostProfileLineage;
    };
    # Homebrew formulae selected for this profile.
    brews = import ./brews.nix {
      inherit lib;
      profiles = hostProfileLineage;
    };
    # Shared Mac App Store applications.
    masApps = import ./mas-apps.nix;
    # Use the taps declared by nix-homebrew; trust the custom cask sources.
    taps = map (
      tap:
      if
        builtins.elem tap [
          "junr03/homebrew-blacktail"
          "saffsanity/homebrew-sill"
        ]
      then
        {
          name = tap;
          trusted = true;
        }
      else
        tap
    ) (builtins.attrNames config.nix-homebrew.taps);

    # Reconcile Homebrew installations with the declared selections.
    onActivation = {
      autoUpdate = false;
      cleanup = "uninstall";
      upgrade = true;
    };

  };

  home-manager = {
    backupFileExtension = hostProfile.homeManager.backupFileExtension;
    extraSpecialArgs = { inherit gallatin rex; };
    useGlobalPkgs = true;
    # Install declared npm packages in the user's prefix during Home Manager activation.
    sharedModules = [
      (
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          packages = config.blacktail.npm.packages;
        in
        {
          options.blacktail.npm.packages = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "npm package specs to install globally during Home Manager activation.";
          };

          config = {
            home.sessionPath = [ "$HOME/.npm-packages/bin" ];
            home.activation.installNpmPackages = lib.mkIf (packages != [ ]) (
              lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                run ${pkgs.coreutils}/bin/env PATH="${pkgs.nodejs}/bin:$PATH" \
                  ${pkgs.nodejs}/bin/npm install --global --prefix "$HOME/.npm-packages" \
                  -- ${lib.escapeShellArgs packages}
              ''
            );
          };
        }
      )
    ];
    users.${user} =
      {
        pkgs,
        config,
        lib,
        rex,
        ...
      }:
      {
        imports = [
          # Shared editor and Herdr packages and configuration from Gallatin.
          "${gallatin}/neovim/home-manager.nix"
          "${gallatin}/herdr/home-manager.nix"
          # Rex package installation and local configuration.
          rex.homeManagerModules.default
          ./rex/home-manager.nix
          # Link Gallatin's shared skills and any additional Blacktail skill sources.
          ./skills.nix
          # Install Gallatin's shared Codex configuration and supporting files.
          ./codex.nix
        ];

        # Feed profile-selected npm specs into the activation installer above.
        blacktail.npm.packages = import ./npm.nix {
          inherit lib;
          profiles = hostProfileLineage;
        };

        # Home Manager's generated manpage uses nixosOptionsDoc, which emits
        # a Nix 2.34 string-context warning while creating options.json.
        manual.manpages.enable = false;

        home = {
          # Install the shared files selected by files.nix.
          file = userFiles;
          # Expose user-installed tools; the npm installer adds its own bin directory.
          sessionPath = [
            "$HOME/.pnpm-packages/bin"
            "$HOME/.pnpm-packages"
            "$HOME/bin"
            "$HOME/.local/bin"
            "$HOME/.local/share/bin"
          ];
          sessionVariables = {
            ALTERNATE_EDITOR = "";
            HISTIGNORE = "pwd:ls:cd";
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
            }
            // (hostProfile.shellAliases or { });
            initContent = lib.mkBefore ''
              # nix shortcuts
              shell() {
                if (( $# != 1 )); then
                  echo "Usage: shell <package>"
                  return 1
                fi

                nix shell "nixpkgs#$1"
              }

              # Copy missing files with per-file progress, preserving existing destinations.
              copy_files() {
                if (( $# != 2 )); then
                  echo "Usage: copy_files <src> <dst>"
                  return 1
                fi

                rsync --archive --verbose --progress --ignore-existing -- "$1" "$2"
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
            signing = {
              key = "${userHome}/.ssh/${hostProfile.git.signingKey}.pub";
              format = "ssh";
              signer = hostProfile.git.signer;
              signByDefault = true;
            };
            settings = {
              user = {
                name = hostProfile.git.name;
                email = hostProfile.git.email;
              };
              init.defaultBranch = "main";
              core = {
                editor = "nvim";
                autocrlf = "input";
              };
              pull.rebase = true;
              rebase.autoStash = true;
            };
          };
          ssh = {
            enable = true;
            enableDefaultConfig = false;

            settings = {
              "*" = {
                ForwardAgent = false;
                AddKeysToAgent = "no";
                Compression = false;
                IdentityAgent = ''"${userHome}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'';
                ServerAliveInterval = 0;
                ServerAliveCountMax = 3;
                HashKnownHosts = true;
                UserKnownHostsFile = "~/.ssh/known_hosts";
              };
            }
            // lib.mapAttrs' (
              _: identity:
              lib.nameValuePair identity.host (
                {
                  IdentitiesOnly = true;
                  IdentityFile = "${userHome}/.ssh/${identity.identityFile}";
                }
                // lib.optionalAttrs (identity ? hostName) { HostName = identity.hostName; }
                // lib.optionalAttrs (identity ? user) { User = identity.user; }
              )
            ) hostProfile.ssh;
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

              # Install VS Code extensions from the pinned Nix marketplace input.
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
