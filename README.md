# Blacktail

Declarative macOS configuration built with Determinate Nix, nix-darwin, and
Home Manager. Shared modules and tooling live here. Actual machine profiles
live in the private `blacktail-sensitive` repository. Credentials stay in
1Password.

## Layout

- `modules/`: shared macOS and Home Manager configuration.
- `apps/`: build, switch, and rollback helpers.
- `private-config/`: pinned private submodule containing profiles, public keys,
  and machine-specific commands. Software selections stay in public modules.
- `flake.nix` and `flake.lock`: configuration assembly and pinned dependencies.

There is no example machine target. Without the private submodule the flake
exposes development tools, but no machine configurations. The build and switch
helpers stop if private configuration is absent.

## Provision a Mac

Install the Xcode command line tools, Rosetta 2 where needed, and Determinate
Nix. Run setup from an administrator account on Apple silicon.

```sh
xcode-select --install
sudo /usr/sbin/softwareupdate --install-rosetta --agree-to-license
```

Install Nix using the instructions at https://docs.determinate.systems, then
open a new shell. Clone with authenticated access to the private repository:

```sh
git clone --recurse-submodules https://github.com/junr03/blacktail.git
cd blacktail
```

For an existing checkout:

```sh
git submodule update --init private-config
```

Select a profile declared in `private-config/default.nix` through the ignored
`.blacktail.local` file:

```sh
printf 'BLACKTAIL_HOST_PROFILE=YOUR_PROFILE\n' > .blacktail.local
```

Review its username, Git identity, SSH destinations, application selections,
and Home Manager backup policy before activation. Enable the SSH agent in
1Password's developer settings. Keep SSH and signing private keys in
1Password; the private repository contains only their matching public keys.

## Build and activate

```sh
nix run .#build
nix run .#build-switch
nix run .#register_as_ssh_server
nix run .#rollback
```

The helpers include the private submodule in the Nix source and use `--no-link`.
Rollback operates on the current Mac's existing generations. Build does not
activate the system. Build-switch does, including the existing Homebrew policy
of upgrading declared applications and uninstalling undeclared packages.

`register_as_ssh_server` is an explicit, idempotent registration command. It
uses this Mac's `LocalHostName` and Tailscale IPv4 address, creates or reuses an
Ed25519 SSH Key item named `blacktail-<LocalHostName>` in the `blacktail`
1Password vault, and opens or updates a PR in `blacktail-sensitive`. The PR
contains only the public key and SSH host metadata. It never auto-merges.

The generated configuration also makes the custom `blacktail` vault available
to the 1Password SSH agent. If 1Password does not recognize the new agent
configuration immediately, lock and unlock 1Password once.

Blacktail activation enables macOS Remote Login for the configured user,
disables password and keyboard-interactive SSH authentication, and authorizes
all registered Blacktail public keys. The SSH server listens on macOS's normal
SSH interfaces; the generated client aliases use Tailscale addresses.

Preserve existing settings before first activation. When a profile sets a
Home Manager backup extension, inspect those backups after migration before
removing them or disabling the backup setting in the private profile.

## Development

```sh
nix develop -c pre-commit run --all-files
python3 tests/test_build_helpers.py
nix flake check --all-systems
```

The last command checks the public flake without including the submodule.
For real profile builds on macOS, include it explicitly:

```sh
nix flake check 'git+file://PATH_TO_CHECKOUT?submodules=1' --all-systems
```

Private profiles supply `username`, `git`, `ssh`, `keysDirectory`, and
`homeManager`. Public modules select software by profile name. Optional
`shellAliases` extend the shared aliases. SSH entries supply `host` and
`identityFile`, with optional `hostName` and `user`. They need not use any
particular machine name.

## Integration CI

Public CI runs without private access. Owner-authored PRs from this repository
request a private integration build. External contributions need a maintainer
to review the exact commit and dispatch the private workflow manually.

Integration checks out the requested Blacktail SHA and the private commit
pinned by its gitlink. It builds every real profile without activation and
reports only `Private integration` pass/fail to that Blacktail SHA. Build logs
and artifacts remain private. New PR commits need new integration results.

Maintainers can also dispatch `Request private integration` manually with a
reviewed full Blacktail SHA. During bootstrap, select the reviewed private
workflow branch with `private_workflow_ref`; normal runs use `main`. Manual
dispatch approves executing the selected code with access to private config.

The request workflow needs the `PRIVATE_INTEGRATION_DISPATCH_TOKEN` Actions
secret with Actions write on `blacktail-sensitive`. The private workflow needs
its separate status-reporting token and revision variable; setup is documented
in the private repository. Keep the private workflow on main before enabling
dispatch. Require the integration status in branch protection after validating
that the cross-repository connection works.

Private configuration changes merge first. Update this repository's submodule
pointer in a PR afterward and wait for the combined integration result.

This change separates current configuration. It does not sanitize Git history
or change repository visibility.
