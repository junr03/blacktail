# Shared modules

`host.nix` configures macOS and consumes the selected private profile.
`home-manager.nix` configures programs, generic SSH host mappings, Git signing,
and the 1Password agent. `files.nix` installs shared editor configuration and
the public keys supplied by that profile. `default.nix` sets Nixpkgs policy.

Machine profiles, package selections, SSH destinations, and operational aliases
belong in `private-config/`. Passwords and private keys belong in 1Password.
