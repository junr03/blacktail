{
  gallatin,
  hostProfile,
  hostProfileName,
  lib,
  pkgs,
  ...
}:
let
  user = hostProfile.username;
in
{
  imports = [
    ./home-manager.nix
    ./.
  ];

  determinateNix = {
    enable = true;

    customSettings = {
      sandbox = true;
      trusted-users = [
        "root"
        "@admin"
        user
      ];
      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };

    determinateNixd.garbageCollector.strategy = "automatic";
  };

  # Load configuration that is shared across systems
  environment.systemPackages =
    with pkgs;
    [
      (callPackage "${gallatin}/rename-picture.nix" { })
    ]
    ++ (import ./packages.nix {
      inherit lib pkgs;
      profile = hostProfileName;
    });

  # Font configuration
  fonts.packages = with pkgs; [
    dejavu_fonts
    fira-code
    font-awesome
    meslo-lgs-nf
    nerd-fonts.fira-code
  ];

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
