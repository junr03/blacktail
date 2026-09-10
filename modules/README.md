# Shared modules

`host.nix` configures macOS and consumes the selected private profile.
`home-manager.nix` configures programs, generic SSH host mappings, Git signing,
and the 1Password agent. `host.nix` also enables Apple's OpenSSH server and
authorizes the registered Blacktail server keys. `files.nix` installs shared
editor configuration and the public keys supplied by that profile.
`default.nix` sets Nixpkgs policy.

Homebrew and Nix package selections live in `brews.nix`, `casks.nix`, and
`packages.nix`. `profile-packages.nix` selects entries for each profile.
App Store selections live in `home-manager.nix`.

Machine identities, SSH destinations, and operational aliases
belong in `private-config/`. Passwords and private keys belong in 1Password.
