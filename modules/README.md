# Shared modules

`host.nix` configures macOS and consumes the selected private profile.
`home-manager.nix` configures programs, generic SSH host mappings, Git signing,
and the 1Password agent. `files.nix` installs shared editor configuration and
the public keys supplied by that profile. `home-manager.nix` also imports the
shared agent skill module from Gallatin. `default.nix` sets Nixpkgs policy.

Gallatin's `skills/` module installs both its custom skills from `codex/skills/`
and its pinned external repositories into `~/.agents/skills`. One inventory
checks for duplicate names across all sources. Update the source list in
Gallatin, then update Blacktail's pinned `gallatin` input and lock file.

Homebrew and Nix package selections live in `brews.nix`, `casks.nix`, and
`packages.nix`. `profile-packages.nix` selects entries for each profile.
App Store selections live in `home-manager.nix`.

Machine identities, SSH destinations, and operational aliases
belong in `private-config/`. Passwords and private keys belong in 1Password.
