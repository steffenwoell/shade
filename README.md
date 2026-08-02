# shade 1.1 "Phobos"

<img src="assets/shade.jpg" alt="Shade icon">

A multi-display screen dimmer for macOS, controlled from the command line.

Shade places a translucent black overlay over every connected display. It dims below the normal hardware-brightness range without changing display settings, intercepting input, appearing in the Dock, or requesting accessibility permissions.

## Features

- Covers every connected display
- Updates when displays are connected, removed, or rearranged
- Works across Spaces and alongside full-screen apps
- Ignores all mouse input and never takes keyboard focus
- Runs without a Dock icon or menu-bar item
- Leaves hardware brightness and color settings untouched
- Reads a simple per-user opacity configuration

## Requirements

- macOS 13 or later
- Apple Silicon or Intel Mac
- Xcode Command Line Tools when building from source

## Build

```zsh
git clone https://github.com/steffenwoell/shade.git
cd shade
./build.zsh
```

The build script creates an optimized `Shade.app`, validates its property list, signs it ad hoc, and verifies the finished bundle. A previously successful build is retained until its replacement has passed every validation step.

To use a Developer ID or Apple Development certificate:

```zsh
APPLE_SIGN_IDENTITY="Your Signing Identity" ./build.zsh
```

## Install

Install both the app and the `shade` command:

```zsh
./install.zsh
```

By default, the app is installed to `~/Applications/Shade.app` and the CLI to `${BIN:-$HOME/bin}/shade`. An existing installed app is moved to a timestamped backup first.

Custom destinations can be selected with environment variables:

```zsh
SHADE_INSTALL_APP_DIR=/Applications BIN=/usr/local/bin ./install.zsh
```

System-wide destinations may require appropriate permissions.

## Usage

Set the desired dimming percentage with the CLI:

```zsh
shade 40
```

Accepted values range from `0` to `100`. Invalid or missing configuration uses a 35% default input. Shade applies a gamma curve and caps the actual black-overlay opacity at 80%, giving finer control at lower levels.

Show the current state or stop Shade:

```zsh
shade status
shade off
```

An opacity of `0` is equivalent to `shade off`. The CLI writes `~/.shade-opacity` atomically, restarts only the matching Shade executable, verifies that the app started, and restores the previous configuration if startup fails.

If the app is stored elsewhere, override automatic discovery:

```zsh
SHADE_APP=/path/to/Shade.app shade 60
```

Shade reads the configuration when it starts and whenever the display arrangement changes.

## How it works

Shade creates one borderless AppKit window per display at the screen-saver window level. Each window joins all Spaces, supports full-screen auxiliary presentation, ignores mouse events, and is excluded from normal window cycling.

It does not modify system brightness, Night Shift, color profiles, gamma tables, or display firmware. Because it uses an overlay, screenshots and screen recordings may include the dimming layer.

## Privacy

Shade is fully local, performs no networking, collects no analytics, and stores only the value you place in `~/.shade-opacity`.

## Development

Run the macOS smoke checks:

```zsh
./tests/smoke.zsh
```

They validate Swift compilation, installation, the application bundle, plist metadata, code signing, supported architecture, CLI status/start behavior, atomic opacity configuration, and repository hygiene.

## Author

Created by [Steffen Wöll](https://steffenwoell.github.io), 2026.

## License

MIT License.
