#!/usr/bin/env python3
"""Merge Gallatin's managed Codex settings while preserving host settings."""

import os
from pathlib import Path
import stat
import sys
import tempfile

import tomlkit
from tomlkit.items import Table


def merge(destination, shared):
    for key, value in shared.items():
        if isinstance(value, Table) and isinstance(destination.get(key), Table):
            merge(destination[key], value)
        else:
            destination[key] = value


def main():
    shared_path, config_path = map(Path, sys.argv[1:])
    if config_path.is_symlink():
        raise SystemExit(f"Refusing to replace symlink: {config_path}")
    shared = tomlkit.parse(shared_path.read_text())
    config = tomlkit.parse(config_path.read_text()) if config_path.exists() else tomlkit.document()
    merge(config, shared)
    updated = tomlkit.dumps(config)
    if config_path.exists() and config_path.read_text() == updated:
        return
    config_path.parent.mkdir(parents=True, exist_ok=True)
    mode = stat.S_IMODE(config_path.stat().st_mode) if config_path.exists() else 0o600
    fd, name = tempfile.mkstemp(dir=config_path.parent, prefix=".config.toml.")
    try:
        with os.fdopen(fd, "w") as output:
            os.fchmod(output.fileno(), mode)
            output.write(updated)
        os.replace(name, config_path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


if __name__ == "__main__":
    main()
