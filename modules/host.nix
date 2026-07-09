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
  photosMountScript = ''
    set -u

    /bin/mkdir -p /Volumes/photos/raw /Volumes/photos/edited
    failures=0

    mount_if_missing() {
      remote="$1"
      mountpoint="$2"

      if /sbin/mount | /usr/bin/grep -q " on $mountpoint "; then
        echo "$mountpoint is already mounted"
        return 0
      fi

      echo "Mounting $remote at $mountpoint"
      if ! /sbin/mount_nfs -o vers=3,resvport,nosuid,nolock "$remote" "$mountpoint"; then
        echo "Failed to mount $remote at $mountpoint" >&2
        failures=1
      fi
    }

    mount_if_missing "${nfsServer}:/photos/raw" /Volumes/photos/raw
    mount_if_missing "${nfsServer}:/photos/edited" /Volumes/photos/edited
    exit "$failures"
  '';
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
      agenix.packages."${pkgs.stdenv.hostPlatform.system}".default
      age-plugin-yubikey
      (callPackage "${gallatin}/rename-picture.nix" { })
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

  # Create mount points and try to mount immediately during activation.
  system.activationScripts.nfsMounts = {
    text = ''
      (
        ${photosMountScript}
      ) || true
    '';
    deps = [
      "users"
      "groups"
    ];
  };

  # Mount the photo shares at boot and retry periodically for network changes.
  launchd.daemons."photos-nfs-mount" = {
    script = ''
      ${photosMountScript}
    '';
    serviceConfig = {
      Label = "net.electricpeak.photos-nfs-mount";
      RunAtLoad = true;
      StartInterval = 60;
      KeepAlive = {
        NetworkState = true;
      };
      ProcessType = "Background";
      StandardOutPath = "/var/log/photos-nfs-mount.log";
      StandardErrorPath = "/var/log/photos-nfs-mount.err.log";
    };
  };
}
