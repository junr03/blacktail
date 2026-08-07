# nix-configs

Configuration for provisioning macOS machines with [Nix](https://nixos.org), [`nix-darwin`](https://github.com/LnL7/nix-darwin), and [`home-manager`](https://github.com/nix-community/home-manager).

## Repository layout

```
.
├── apps/                # helper scripts invoked via `nix run`
├── modules/             # shared modules and options
├── overlays/            # package overlays
├── flake.nix
└── flake.lock
```

## Provisioning a new Mac

1. **Install Nix**

   Install the Xcode command line tools and Nix using the Determinate Systems installer:

   ```sh
   xcode-select --install
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --nix-build-group-id 30000
   ```

1. **Clone this repository**

   ```sh
   git clone https://github.com/junr03/blacktail.git
   cd blacktail
   ```

1. **Build and activate the system**

   ```sh
   nix run .#build-switch
   ```

   This builds the configuration for `aarch64-darwin` and switches to the new generation.

1. **After the initial provisioning**

   - Rebuild and switch after making changes: `nix run .#build-switch`
   - Build without switching: `nix run .#build`
   - Roll back to a previous generation: `nix run .#rollback`

## Development

This repository uses `pre-commit` for linting and formatting. Install the hooks with:

```sh
pre-commit install
```

Run the checks locally before committing:

```sh
pre-commit run --all-files
```

Nix files can be formatted uniformly using `nix fmt` thanks to the flake's `formatter` attribute:

```sh
nix fmt
```
