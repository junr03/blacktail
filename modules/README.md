# Shared modules

`host.nix` configures macOS and consumes the selected private profile.
`home-manager.nix` configures programs, generic SSH host mappings, Git signing,
and the 1Password agent. `files.nix` installs shared editor configuration and
the public keys supplied by that profile. `home-manager.nix` also imports the
shared agent skill module from Gallatin. `default.nix` sets Nixpkgs policy.

Gallatin supplies its shared skills and discovery logic. Blacktail can add
sources without changing Gallatin, for example in its Home Manager user module:

```nix
blacktail.skills.repositories.my-repo = {
  source = "${builtins.fetchGit {
    url = "https://github.com/example/skills.git";
    rev = "REPLACE_WITH_COMMIT";
  }}";
  directories = [ "skills" ];
};
blacktail.skills.individual.my-skill = /path/to/my-skill;
```

Repository roots default to `.agents/skills` and `skills`. Individual sources
must contain `SKILL.md`. This also accepts directories materialized by another
source, such as a future Notion exporter; it does not fetch Notion data itself.
Skills are linked individually into `~/.agents/skills`; unrelated manually
installed skills remain in place. Duplicate names across sources fail evaluation,
and Home Manager's normal collision checks apply to existing destinations.
Update the pinned `gallatin` input and lock file to update Gallatin's sources.

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
