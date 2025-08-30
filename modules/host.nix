{
  agenix,
  config,
  pkgs,
  ...
}:
let
  user = "junr03";
in
{
  imports = [
    ./secrets.nix
    ./home-manager.nix
    ./.
    agenix.darwinModules.default
  ];

  # Setup user, packages, programs
  nix = {
    package = pkgs.nix;

    settings = {
      trusted-users = [
        "@admin"
        "${user}"
      ];
      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
    };

    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 2;
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };

    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Load configuration that is shared across systems
  environment.systemPackages =
    with pkgs;
    [
      agenix.packages."${pkgs.system}".default
      age-plugin-yubikey
    ]
    ++ (import ./packages.nix { inherit pkgs; });

  # Font configuration
  fonts.packages = with pkgs; [
    fira-code
    nerd-fonts.fira-code
  ];

  # System activation scripts
  system.activationScripts = {
    # Install Rosetta 2 early, before Homebrew
    installRosetta = {
      text = ''
        echo "=== Installing Rosetta 2 ==="
        if ! /usr/bin/pgrep -q oahd; then
          echo "Installing Rosetta 2..."
          sudo softwareupdate --install-rosetta --agree-to-license
          echo "Rosetta 2 installed"
        else
          echo "Rosetta 2 is already installed"
        fi
      '';
      deps = [
        "users"
        "groups"
      ];
    };

    # Copy Capture One into /Applications using macOS tools (preserve attributes)
    installCaptureOne = {
      text = ''
        set -e
        echo "=== Installing Capture One (if missing) ==="
        if [ ! -d "/Applications/Capture One.app" ]; then
          DMG_PATH='${pkgs.capture-one}'
          if [ ! -e "$DMG_PATH" ]; then
            echo "Capture One DMG not found at $DMG_PATH" >&2
            exit 1
          fi
          MNT=$(mktemp -d)
          echo "Mounting DMG..."
          hdiutil attach -nobrowse -readonly -mountpoint "$MNT" "$DMG_PATH" >/dev/null
          SRC_APP=$(find "$MNT" -maxdepth 2 -type d -name 'Capture One*.app' | head -n 1)
          if [ -z "$SRC_APP" ]; then
            echo "Failed to locate Capture One .app on DMG" >&2
            /bin/ls -la "$MNT"
            hdiutil detach "$MNT" >/dev/null || true
            rmdir "$MNT" || true
            exit 1
          fi
          echo "Copying $SRC_APP to /Applications (using ditto)..."
          ditto "$SRC_APP" "/Applications/Capture One.app"
          echo "Detaching DMG..."
          hdiutil detach "$MNT" >/dev/null || true
          rmdir "$MNT" || true
          echo "Capture One installed to /Applications"
        else
          echo "Capture One already present in /Applications"
        fi
      '';
      deps = [
        "users"
        "groups"
      ];
    };
  };

  system = {
    checks.verifyNixPath = false;
    primaryUser = user;
    stateVersion = 4;

    defaults = {
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        ApplePressAndHoldEnabled = false;

        # 120, 90, 60, 30, 12, 6, 2
        KeyRepeat = 2;

        # 120, 94, 68, 35, 25, 15
        InitialKeyRepeat = 15;

        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.sound.beep.feedback" = 0;
      };

      dock = {
        autohide = true;
        show-recents = false;
        launchanim = true;
        orientation = "bottom";
        tilesize = 96;
      };

      finder = {
        _FXShowPosixPathInTitle = false;
      };

      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = true;
      };
    };
  };
}
