{
  gallatin,
  gallatinRunners,
  hostProfile,
  hostProfileLineage,
  hostProfileName,
  lib,
  nixpkgs,
  pkgs,
  ...
}:
let
  user = hostProfile.username;
  dnsARecords = hostProfile.dnsARecords or { };
  dnsResolvers = hostProfile.dnsResolvers or { };
  ipv4AddressRegex =
    "((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\\.){3}"
    + "(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])";
  dnsmasqConfig = pkgs.writeText "blacktail-dnsmasq.conf" (
    lib.concatStringsSep "\n" (
      [
        "port=53"
        "listen-address=127.0.0.1"
        "bind-interfaces"
        "no-hosts"
        "no-resolv"
      ]
      ++ lib.mapAttrsToList (domain: address: "address=/${domain}/${address}") dnsARecords
      ++ lib.mapAttrsToList (domain: _: "local=/${domain}/") dnsARecords
    )
    + "\n"
  );
  gallatinRunnerModule =
    nixpkgs.legacyPackages."aarch64-darwin".runCommand "gallatin-darwin-github-runner-blacktail" { }
      ''
        mkdir -p "$out"
        cp -R ${gallatinRunners}/. "$out/"
        substituteInPlace "$out/darwin-github-runner.nix" \
          --replace-fail "/usr/bin/su -s /bin/bash -l" "/usr/bin/sudo -n -u" \
          --replace-fail " -c " " -H /bin/bash -lc "
      '';
in
{
  imports = [
    (import "${gallatinRunnerModule}/darwin-github-runner.nix")
    ./home-manager.nix
    ./.
  ];

  # Let macOS send queries for configured internal domains to their resolver.
  # The profile owns the machine-specific domain and nameserver mapping.
  environment.etc =
    lib.mapAttrs' (
      domain: nameserver:
      lib.nameValuePair "resolver/${domain}" {
        text = "nameserver ${nameserver}\n";
      }
    ) dnsResolvers
    // lib.mapAttrs' (
      domain: _:
      lib.nameValuePair "resolver/${domain}" {
        text = "nameserver 127.0.0.1\n";
      }
    ) dnsARecords;

  assertions = [
    {
      assertion = lib.all (
        address: builtins.isString address && builtins.match ipv4AddressRegex address != null
      ) (builtins.attrValues dnsARecords);
      message = "Every dnsARecords value must be a valid IPv4 address.";
    }
  ];

  # Keep A-record overrides local to the selected host profile.
  # The local rule makes AAAA queries return no record instead of going upstream.
  launchd.daemons = lib.mkIf (dnsARecords != { }) {
    blacktail-dnsmasq = {
      serviceConfig = {
        ProgramArguments = [
          (lib.getExe pkgs.dnsmasq)
          "--keep-in-foreground"
          "--conf-file=${dnsmasqConfig}"
        ];
        RunAtLoad = true;
        KeepAlive = true;
      };
    };
  };

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
    ++ import ./packages.nix {
      inherit lib pkgs;
      profiles = hostProfileLineage;
    };

  services.gallatin.githubActionsRunners.blacktail-macos = lib.mkIf (hostProfileName == "runner") {
    enable = true;
    repository = "https://github.com/junr03/blacktail-sensitive";
    labels = [ "blacktail-macos" ];
    accessTokenFile = "/private/var/db/blacktail-github-runner/access-token";
    user = "blacktail-runner";
    uid = 502;
    workDirectory = "/Users/blacktail-runner";
    preventSleep = true;
  };

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
