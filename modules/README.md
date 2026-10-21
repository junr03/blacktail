# Shared modules

`host.nix` configures macOS and consumes the selected private profile.
`home-manager.nix` configures programs, generic SSH host mappings, Git signing,
and the 1Password agent. `files.nix` installs shared editor configuration and
the public keys supplied by that profile. `home-manager.nix` also imports the
shared agent skill module from Gallatin. `default.nix` sets Nixpkgs policy.

Gallatin owns the pinned repositories and skill discovery in its `skills/`
directory. It links skills into `~/.agents/skills` and rejects duplicate names.
Add or update repositories there, then update Blacktail's pinned `gallatin`
input and lock file.

Homebrew and Nix package selections live in `brews.nix`, `casks.nix`, and
`packages.nix`. `profile-packages.nix` selects entries for each profile.
App Store selections live in `home-manager.nix`.

Machine identities, SSH destinations, and operational aliases
belong in `private-config/`. Passwords and private keys belong in 1Password.
