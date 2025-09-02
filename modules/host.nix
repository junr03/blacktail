{
  agenix,
  gallatin,
  config,
  pkgs,
  ...
}:
let
  user = "junr03";
  nfsServer = "100.81.172.57";
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
      (callPackage "${gallatin}/rename-cr3.nix" { })
    ]
    ++ (import ./packages.nix { inherit pkgs; });

  # Font configuration
  fonts.packages = with pkgs; [
    fira-code
    nerd-fonts.fira-code
  ];

  # Provide autofs direct maps via the default static map.
  # macOS' /etc/auto_master contains: "/-    -static" which reads /etc/auto_static.
  # Writing our entries to /etc/auto_static avoids editing /etc/auto_master.
  environment.etc."auto_static".text = ''
    /Volumes/photos/raw    -fstype=nfs,vers=3,resvport,nosuid     ${nfsServer}:/photos/raw
    /Volumes/photos/edited -fstype=nfs,vers=3,resvport,nosuid     ${nfsServer}:/photos/edited
  '';

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

    # Extend the existing applications phase to also install Capture One
    applications.text = pkgs.lib.mkAfter ''
      set -euo pipefail
      echo "Installing Capture One from DMG (if missing)"
      if ! find /Applications -maxdepth 1 -type d -name 'Capture One*.app' | grep -q .; then
        DMG_PATH='${pkgs.capture-one}'
        if [ ! -e "$DMG_PATH" ]; then
          echo "Capture One DMG not found at $DMG_PATH" >&2
        else
          MNT=$(mktemp -d)
          cleanup() { hdiutil detach "$MNT" >/dev/null 2>&1 || true; rmdir "$MNT" 2>/dev/null || true; }
          trap cleanup EXIT
          echo "Mounting DMG $DMG_PATH..."
          hdiutil attach -quiet -nobrowse -readonly -mountpoint "$MNT" "$DMG_PATH"
          PKG=$(find "$MNT" -maxdepth 2 -type f -name '*.pkg' | head -n 1 || true)
          if [ -n "$PKG" ]; then
            echo "Installing via pkg: $PKG"
            /usr/sbin/installer -pkg "$PKG" -target / -verboseR || true
          else
            SRC_APP=$(find "$MNT" -maxdepth 2 -type d -name 'Capture One*.app' -not -iname '*install*' -not -iname '*installer*' | head -n 1 || true)
            if [ -n "$SRC_APP" ]; then
              DEST="/Applications/$(basename "$SRC_APP")"
              echo "Copying $SRC_APP to $DEST (using ditto)..."
              ditto "$SRC_APP" "$DEST"
              xattr -dr com.apple.quarantine "$DEST" || true
            else
              echo "Failed to locate Capture One .app or .pkg on mounted DMG" >&2
              /bin/ls -la "$MNT" || true
            fi
          fi
        fi
      fi
    '';
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

  # Create mount points and refresh autofs at activation/boot
  system.activationScripts.nfsMounts = {
    text = ''
      set -euo pipefail
      echo "Ensuring NFS mount points exist"
      /bin/mkdir -p /Volumes/photos /Volumes/photos/raw /Volumes/photos/edited

      echo "[nfsAutofs] Reloading automount maps"
      /usr/sbin/automount -vc || true

      echo "[nfsAutofs] Touching paths to trigger mounts"
      /bin/ls -1 /Volumes/photos/raw >/dev/null 2>&1 || true
      /bin/ls -1 /Volumes/photos/edited >/dev/null 2>&1 || true
    '';
    deps = [
      "users"
      "groups"
    ];
  };

  # Keep mounts pinned: lightweight LaunchDaemon that periodically touches them
  launchd.daemons."photos-nfs-pin" = {
    script = ''
      #! /bin/sh
      set -euo pipefail
      /bin/mkdir -p /Volumes/photos /Volumes/photos/raw /Volumes/photos/edited
      while true; do
        # Touch inside the directories to trigger autofs mounts if needed
        /bin/ls -1 /Volumes/photos/raw >/dev/null 2>&1 || true
        /bin/ls -1 /Volumes/photos/edited >/dev/null 2>&1 || true
        /bin/sleep 60
      done
    '';
    serviceConfig = {
      Label = "net.electricpeak.photos-nfs-pin";
      RunAtLoad = true;
      KeepAlive = {
        SuccessfulExit = false;
        NetworkState = true;
      };
      ProcessType = "Background";
      StandardOutPath = "/var/log/photos-nfs-pin.log";
      StandardErrorPath = "/var/log/photos-nfs-pin.err.log";
    };
  };
}
