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

  # Explicitly manage autofs master and a dedicated direct map to ensure mounts are active.
  # This avoids depending on the system's "-static" entry which may not be present on all hosts.
  environment.etc."auto_master".text = ''
    # Automounter master map
    +auto_master            # Use DirectoryService-managed entries if present
    /net    -hosts         -nobrowse,hidefromfinder,nosuid
    /home   auto_home      -nobrowse,hidefromfinder
    /Network/Servers       -fstab
    /-      auto_photos    -nosuid
  '';

  environment.etc."auto_photos".text = ''
    /Volumes/photos/raw    -fstype=nfs,vers=3,resvport,nosuid,nolock     ${nfsServer}:/photos/raw
    /Volumes/photos/edited -fstype=nfs,vers=3,resvport,nosuid,nolock     ${nfsServer}:/photos/edited
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
