#!/bin/zsh

emulate -LR zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

repo_dir="${0:A:h:h}"
app_bundle="$repo_dir/Shade.app"
executable="$app_bundle/Contents/MacOS/Shade"
cli="$repo_dir/bin/shade"
module_cache="${CLANG_MODULE_CACHE_PATH:-${TMPDIR:-/tmp}/shade-module-cache}"
fixture_dir="$(mktemp -d "${TMPDIR:-/tmp}/shade-tests.XXXXXX")"
installed_app_directory="$fixture_dir/Applications"
installed_cli_directory="$fixture_dir/bin"
opacity_file="$fixture_dir/opacity"
running_marker="$fixture_dir/running"
ps_stub="$fixture_dir/ps-stub"
open_stub="$fixture_dir/open-stub"

cleanup() {
    rm -rf -- "$fixture_dir"
}
trap cleanup EXIT

export CLANG_MODULE_CACHE_PATH="$module_cache"

zsh -n "$repo_dir/build.zsh"
zsh -n "$repo_dir/install.zsh"
zsh -n "$cli"
plutil -lint "$repo_dir/Info.plist"
swiftc -typecheck "$repo_dir/Sources/Shade.swift" -framework AppKit
SHADE_INSTALL_APP_DIR="$installed_app_directory" \
    BIN="$installed_cli_directory" \
    "$repo_dir/install.zsh"

installed_app="$installed_app_directory/Shade.app"
installed_executable="$installed_app/Contents/MacOS/Shade"
installed_cli="$installed_cli_directory/shade"

[[ -x "$executable" ]]
[[ -x "$installed_executable" && -x "$installed_cli" ]]
plutil -lint "$app_bundle/Contents/Info.plist"
[[ "$(plutil -extract CFBundleIdentifier raw "$app_bundle/Contents/Info.plist")" == 'com.steffen.shade' ]]
[[ "$(plutil -extract CFBundleShortVersionString raw "$app_bundle/Contents/Info.plist")" == '1.1' ]]
xattr -cr "$app_bundle" 2>/dev/null || true
codesign --verify --deep --strict --verbose=2 "$app_bundle"
codesign --verify --deep --strict --verbose=2 "$installed_app"
file_output="$(file "$executable")"
grep -q 'Mach-O 64-bit executable' <<<"$file_output"

build_help="$($repo_dir/build.zsh --help)"
grep -q 'Build the Shade macOS application' <<<"$build_help"
if "$repo_dir/build.zsh" --unknown >/dev/null 2>&1; then
    print -u2 -- 'Error: unknown build option unexpectedly succeeded.'
    exit 1
fi

cat >"$ps_stub" <<'EOF'
#!/bin/zsh
if [[ -f "$SHADE_TEST_RUNNING_MARKER" ]]; then
    print -- "424242 $EUID $SHADE_TEST_EXECUTABLE"
fi
EOF

cat >"$open_stub" <<'EOF'
#!/bin/zsh
touch "$SHADE_TEST_RUNNING_MARKER"
EOF
chmod 755 "$ps_stub" "$open_stub"

common_environment=(
    SHADE_APP="$installed_app"
    SHADE_EXECUTABLE="$installed_executable"
    SHADE_OPACITY_FILE="$opacity_file"
    SHADE_PS_BIN="$ps_stub"
    SHADE_OPEN_BIN="$open_stub"
    SHADE_TEST_RUNNING_MARKER="$running_marker"
    SHADE_TEST_EXECUTABLE="$installed_executable"
)

cli_help="$(env "${common_environment[@]}" "$installed_cli" --help)"
grep -q 'Control the Shade screen dimmer' <<<"$cli_help"
status_off="$(env "${common_environment[@]}" "$installed_cli" status)"
grep -q 'Shade:    off' <<<"$status_off"
start_output="$(env "${common_environment[@]}" "$installed_cli" 40)"
grep -q 'Opacity:   40%' <<<"$start_output"
[[ "$(<"$opacity_file")" == 40 ]]
status_on="$(env "${common_environment[@]}" "$installed_cli" status)"
grep -q 'Shade:    on' <<<"$status_on"

if env "${common_environment[@]}" "$installed_cli" 101 >/dev/null 2>&1; then
    print -u2 -- 'Error: invalid opacity unexpectedly succeeded.'
    exit 1
fi
[[ "$(<"$opacity_file")" == 40 ]]

if grep -R -n -E '/Users/[^/[:space:]]+' "$repo_dir" \
    --exclude='smoke.zsh' --exclude-dir='Shade.app' --exclude-dir='_misc'; then
    print -u2 -- 'Error: repository contains a user-specific absolute path.'
    exit 1
fi

print -- 'All Shade smoke checks passed.'
