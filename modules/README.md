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
App Store selections live in `mas-apps.nix`.

Global npm package selections live in `npm.nix`, using the same
profile selection as the other package lists. Add entries such as
`{ name = "@scope/package@1.2.3"; }`, or add `profiles = [ "work" ];` to
restrict an entry. `rex-usage` is installed for all profiles.

`home-manager.nix` installs those packages into `~/.npm-packages` during Home Manager
activation and adds its `bin` directory to PATH. A nonempty list requires
network access to the configured npm registry. Pin exact versions for consistent
installs; unversioned specs resolve the current release on activation. Packages
removed from the list remain installed until manually uninstalled with
`npm uninstall --global --prefix ~/.npm-packages <package>`. Existing global
packages and npm configuration are preserved. Nix-provided Node.js tools, such
as Prettier, remain in `packages.nix`.

Muse from Meta uses `Casks/muse.rb` because its Mac app is a direct download
and Homebrew's upstream cask is disabled. The custom download strategy resolves
an expiring installer link from Meta's official page at download time. The cask
tracks the latest release without a pinned checksum; Muse handles its own updates.

Agent Meter uses `Casks/agent-meter.rb` because upstream publishes source without
a prebuilt app. The cask pins an upstream commit and builds the app with its
provided script during installation. It requires Swift 6.0 or later from Xcode
Command Line Tools; bump the cask's version to update the source revision.

LazyVim configuration lives in Gallatin's `neovim/home-manager.nix`, imported by
the Home Manager user module alongside Gallatin's Herdr and agent skill modules.
Activation restores Gallatin's shared plugin lockfile and extras selection and
requires network access. Configure the starter in Gallatin to share changes with
Electricpeak.

`codex.nix` installs Gallatin's Codex instructions, agents, keybindings, and
rules through Home Manager. On activation it merges the shared TOML settings
into `~/.codex/config.toml`, preserving other host settings and local approval
rules. Existing files at managed destinations follow the Home Manager backup
policy. A symlinked `config.toml` must be converted to a regular file before
activation.

Machine identities, SSH destinations, and operational aliases
belong in `private-config/`. Passwords and private keys belong in 1Password.
