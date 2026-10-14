# Shared modules

`host.nix` configures macOS and consumes the selected private profile.
`home-manager.nix` configures programs, generic SSH host mappings, Git signing,
and the 1Password agent. `files.nix` installs shared editor configuration and
the public keys supplied by that profile. `skills.nix` configures pinned skill
repositories, while `skill-files.nix` links discovered skills into
`~/.agents/skills`. `default.nix` sets Nixpkgs policy.

The skill module searches `.agents/skills/` and `skills/` in each repository by
default. It links directories that contain `SKILL.md` and fails if two skills
have the same directory name. Add repositories to `skills.nix`, using a pinned
Git revision for each source.

Homebrew and Nix package selections live in `brews.nix`, `casks.nix`, and
`packages.nix`. `profile-packages.nix` selects entries for each profile.
App Store selections live in `home-manager.nix`.

Machine identities, SSH destinations, and operational aliases
belong in `private-config/`. Passwords and private keys belong in 1Password.
