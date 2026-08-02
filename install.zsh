#!/bin/zsh

emulate -LR zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

readonly repo_dir="${0:A:h}"
readonly source_app="$repo_dir/Shade.app"
readonly source_cli="$repo_dir/bin/shade"
readonly app_directory="${SHADE_INSTALL_APP_DIR:-$HOME/Applications}"
readonly cli_directory="${BIN:-$HOME/bin}"
readonly destination_app="$app_directory/Shade.app"
readonly destination_cli="$cli_directory/shade"
readonly install_root="$(mktemp -d "${TMPDIR:-/tmp}/shade-install.XXXXXX")"
readonly temporary_app="$install_root/Shade.app"

cleanup() {
    rm -rf -- "$install_root"
}
trap cleanup EXIT

[[ "$OSTYPE" == darwin* ]] || {
    print -u2 -- 'Error: Shade can only be installed on macOS.'
    exit 1
}

[[ -x "$source_cli" ]] || {
    print -u2 -- "Error: CLI not found: $source_cli"
    exit 1
}

"$repo_dir/build.zsh"
xattr -cr "$source_app" 2>/dev/null || true
codesign --verify --deep --strict --verbose=2 "$source_app"

mkdir -p "$app_directory" "$cli_directory"
ditto --noextattr --noqtn "$source_app" "$temporary_app"
xattr -cr "$temporary_app" 2>/dev/null || true
codesign --verify --deep --strict --verbose=2 "$temporary_app"

if [[ -e "$destination_app" ]]; then
    timestamp="$(date '+%Y%m%d-%H%M%S')"
    backup_app="$app_directory/Shade.app.backup-$timestamp"
    mv -- "$destination_app" "$backup_app"
    print -- "Previous app backed up to: $backup_app"
fi

mv -- "$temporary_app" "$destination_app"
install -m 755 "$source_cli" "$destination_cli"

print -- "Installed app: $destination_app"
print -- "Installed CLI: $destination_cli"
print -- "Ensure $cli_directory is included in your PATH."
