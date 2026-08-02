# Shade 1.1 “Phobos”

## Improvements

- Rebuilds overlays automatically when displays are connected, disconnected, or rearranged.
- Supports full-screen Spaces through auxiliary full-screen window behavior.
- Prevents overlays from taking keyboard focus or appearing in normal window cycling.
- Removes unnecessary overlay shadows.
- Handles missing, invalid, and out-of-range opacity configuration safely.
- Builds natively on both Apple Silicon and Intel Macs.
- Replaces the previous app bundle only after the new build has compiled, signed, and verified successfully.

## Repository

- Adds publication-ready documentation and privacy information.
- Adds GitHub Actions validation.

## Command-line interface

- Ships the companion `shade` command in the repository.
- Sets opacity, reports status, and stops the exact matching Shade process.
- Writes configuration atomically and rolls back when restart fails.
- Locates Shade automatically in standard user, system, repository, and legacy development locations.
- Adds an installer for both `Shade.app` and the CLI.
