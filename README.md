# Blacktail

Declarative macOS configuration built with [Determinate Nix](https://docs.determinate.systems), [nix-darwin](https://github.com/nix-darwin/nix-darwin), and [Home Manager](https://github.com/nix-community/home-manager).

## Repository layout

```text
.
├── apps/                # build, switch, and rollback helpers
├── hosts/               # machine and user-specific profiles
├── keys/                # public SSH keys installed by Home Manager
├── modules/             # shared macOS, Homebrew, and Home Manager configuration
├── flake.nix
└── flake.lock
```

## Provisioning a new Mac

This configuration currently targets Apple silicon (`aarch64-darwin`). Run the setup from an administrator account.

### 1. Install the prerequisites

Install the Xcode command line tools:

```sh
xcode-select --install
```

Install Rosetta 2 once. Blacktail does not run this stateful installer during every system activation:

```sh
sudo /usr/sbin/softwareupdate --install-rosetta --agree-to-license
```

Install Determinate Nix:

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
  | sh -s -- install --nix-build-group-id 30000
```

Open a new shell after the installer finishes.

### 2. Clone and review the host profile

```sh
git clone https://github.com/junr03/blacktail.git
cd blacktail
```

Blacktail keeps each machine's configuration in a checked-in host profile:

- `personal` uses [`hosts/junr03.nix`](hosts/junr03.nix).
- `work` uses [`hosts/jose-rivera.nix`](hosts/jose-rivera.nix).

Select the profile for each checkout in the ignored `.blacktail.local` file:

```sh
printf 'BLACKTAIL_HOST_PROFILE=work\n' > .blacktail.local
```

Use `personal` on the personal Mac. The build and switch helpers keep the selection local while the full profile remains checked into the repository. Rollback operates on the active Mac's existing system generations and does not need a profile selection. You can override the local selection for one command:

```sh
BLACKTAIL_HOST_PROFILE=personal nix run .#build
```

Review the selected profile's macOS username, Git identity, SSH identity filenames, and remote usernames before the first activation. To add another Mac, create another profile under `hosts/` and register it in `hostProfiles` in `flake.nix`; do not put machine-specific identity into the shared modules.

Packages are shared by default. Casks, Homebrew formulae, and Nix packages can be limited to a profile by adding a `profiles` list to their entry in `modules/casks.nix`, `modules/brews.nix`, or `modules/packages.nix`. Profile names match the keys in `hostProfiles` (currently `personal` and `work`); an entry is installed when the selected profile is listed. For example:

```nix
{ name = "some-work-only-cask"; profiles = [ "work" ]; }
{ name = "some-personal-cask"; profiles = [ "personal" ]; }
```

Leave `profiles` off to make an entry universal. All entries use `name`, including Nix packages:

```nix
{ name = pkgs.some-package; profiles = [ "work" ]; }
```

Blacktail configures OpenSSH to use the 1Password SSH agent. Before the first activation, open 1Password, go to **Settings > Developer**, and enable **Use the SSH agent**.

Import each existing private key into 1Password as an SSH Key item:

```text
~/.ssh/github
~/.ssh/electricpeak
~/.ssh/devbox (work profile)
```

Store the items in a vault available to the agent. By default, 1Password makes keys in the Personal, Private, and Employee vaults available. Configure `~/.config/1Password/ssh/agent.toml` in 1Password if the keys live in another vault.

Blacktail checks in the matching public keys:

```text
keys/github.pub
keys/electricpeak.pub
keys/devbox.pub
```

Home Manager installs the public keys required by the selected profile under `~/.ssh`. The public files let OpenSSH select the right agent key for each host while the private keys stay in 1Password. A new Mac only needs the Blacktail checkout and access to the matching 1Password SSH Key items.

Before removing any local private key, confirm that the imported item has the same fingerprint as its checked-in public key and that the agent lists it:

```sh
ssh-keygen -lf keys/github.pub
SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ssh-add -l
```

Repeat the fingerprint check for `electricpeak` and `devbox` when using the work profile. Then activate Blacktail and test each connection. Remove the local private-key files only after every connection succeeds through 1Password.

To rotate a key, create or import its replacement in 1Password, add the new public key to the remote service, and replace the matching file under `keys/`. Run the Blacktail checks and activate the new generation before removing the old public key from the remote service. This keeps 1Password, Blacktail, and the remote host aligned without putting private key material in the Nix store.

### 3. Handle the one-time Home Manager migration

The host profile temporarily sets `homeManager.backupFileExtension = "before-nix"`. During the first activation, Home Manager renames conflicting regular files with that suffix before taking ownership.

Before switching, preserve any settings you still need from existing shell, SSH, Git, Ghostty, tmux, and VS Code configuration. An existing `*.before-nix` destination or an unmanaged conflicting symlink will still stop activation.

After the first successful switch:

1. Review every `*.before-nix` file and merge any settings that belong in this repository.
2. Remove the backups when they are no longer needed.
3. Set `homeManager.backupFileExtension = null` in the host profile so future collisions fail instead of silently creating more backups.

### 4. Build and activate

```sh
nix run .#build-switch
```

The Homebrew activation policy upgrades declared packages but uses `cleanup = "check"`; it will report undeclared formulae or casks without deleting them. Review each reported item, then either declare it or uninstall it manually. In particular, `gh`, Node.js, Python, Rust, tmux, and tmuxinator are Nix-owned, and Bambu Studio is intentionally absent.

## Normal workflow

Build without changing the active system:

```sh
nix run .#build
```

Build and switch:

```sh
nix run .#build-switch
```

Select and activate an older system generation:

```sh
nix run .#rollback
```

The build helpers use `--no-link`, so they do not leave a `result` symlink in the checkout.

## Development

Enter the pinned development environment and install the Git hooks:

```sh
nix develop
pre-commit install
```

Run the same formatting and lint checks used in CI:

```sh
nix develop -c pre-commit run --all-files
```

Validate every flake check, including the full nix-darwin system closure:

```sh
nix flake check --all-systems --print-build-logs
```

Format Nix files:

```sh
nix fmt
```
