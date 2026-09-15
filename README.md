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

Select a profile through the ignored `.blacktail.local` file. Private profiles
are declared in `private-config/default.nix`; the public `runner` profile
inherits `personal` and adds the GitHub Actions runner:

```sh
printf 'BLACKTAIL_HOST_PROFILE=YOUR_PROFILE\n' > .blacktail.local
```

Review its username, Git identity, SSH destinations, application selections,
and Home Manager backup policy before activation. Enable the SSH agent in
1Password's developer settings. Keep SSH and signing private keys in
1Password; the private repository contains only their matching public keys.

Before activating the `runner` profile, create
`/private/var/db/blacktail-github-runner/access-token` as a root-readable file.
It must contain a GitHub access token for the runner's repository. A
fine-grained token needs repository Administration write permission; a classic
token needs the `repo` scope for a private repository. The bootstrap service
uses it only to request GitHub's short-lived runner registration token; never
commit the token.

## Build and activate

```sh
nix run .#build
nix run .#build-switch
nix run .#rollback
```

The helpers include the private submodule in the Nix source and use `--no-link`.
Rollback operates on the current Mac's existing generations. Build does not
activate the system. Build-switch does, including the existing Homebrew policy
of upgrading declared applications and uninstalling undeclared packages.

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
`homeManager`. Public modules select software by profile lineage, so `runner`
receives everything selected for `personal`. Optional
`shellAliases` extend the shared aliases. SSH entries supply `host` and
`identityFile`, with optional `hostName` and `user`. They need not use any
particular machine name.

## Public/private boundary

Blacktail is public. Machine identities, SSH destinations, operational aliases,
public keys, and credentials belong in the private `blacktail-sensitive`
repository. Keep `private-config` as a gitlink. Never replace it with a regular
directory or commit files beneath it here. Shared modules and software
selections belong in this repository.

The repository checks this boundary in three places:

- `scripts/check_public.py` rejects private-looking paths and high-confidence
  credential material from the Git index, and its push mode scans every commit
  introduced by each pushed ref update.
- `pre-commit install` installs the checker for both commit and push hooks.
- The required `Public boundary` GitHub check runs from trusted base-branch code,
  scans the candidate commit as Git data, and never checks out or executes PR
  code or the private submodule.

The local hooks are an early warning. Do not bypass them; the trusted GitHub
check and branch ruleset protect pull requests targeting `main`. GitHub
secret-scanning push protection remains enabled as a second credential
safeguard.

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

The current tree is sanitized, but deleting a private file in a normal commit
does not erase it from older Git history or from already-public refs. Treat the
history cleanup as a separate repository migration and rotate any credential
material that was ever committed.
