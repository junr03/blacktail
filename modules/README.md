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
Vim configuration lives in Gallatin's `vim/home-manager.nix`, imported by the
Home Manager user module alongside Gallatin's Herdr and agent skill modules.

`codex.nix` installs Gallatin's Codex instructions, agents, keybindings, and
rules through Home Manager. On activation it merges the shared TOML settings
into `~/.codex/config.toml`, preserving other host settings and local approval
rules. Existing files at managed destinations follow the Home Manager backup
policy. A symlinked `config.toml` must be converted to a regular file before
activation.

Machine identities, SSH destinations, and operational aliases
belong in `private-config/`. Passwords and private keys belong in 1Password.
