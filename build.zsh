#!/bin/zsh

emulate -LR zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

readonly project_dir="${0:A:h}"
readonly app_name="Shade"
readonly source_file="$project_dir/Sources/Shade.swift"
readonly info_plist="$project_dir/Info.plist"
readonly icon_file="$project_dir/Resources/Shade.icns"
readonly app_bundle="$project_dir/$app_name.app"
readonly sign_identity="${APPLE_SIGN_IDENTITY:--}"
readonly minimum_macos="13.0"
readonly architecture="$(uname -m)"
readonly build_root="$(mktemp -d "${TMPDIR:-/tmp}/shade-build.XXXXXX")"
readonly temporary_bundle="$build_root/$app_name.app"
readonly temporary_contents="$temporary_bundle/Contents"
readonly temporary_macos="$temporary_contents/MacOS"
readonly temporary_resources="$temporary_contents/Resources"
readonly previous_bundle="$build_root/previous.app"

cleanup() {
    rm -rf -- "$build_root"
}
trap cleanup EXIT

show_help() {
    cat <<'EOF'
NAME
    build.zsh - Build the Shade macOS application

SYNOPSIS
    ./build.zsh
    ./build.zsh --help

ENVIRONMENT
    APPLE_SIGN_IDENTITY    Signing identity; defaults to ad-hoc signing (-)
EOF
}

case "${1:-}" in
    "") ;;
    -h|--help|help)
        show_help
        exit 0
        ;;
    *)
        print -u2 -- "Error: Unknown option: $1"
        exit 2
        ;;
esac

(( $# <= 1 )) || {
    print -u2 -- 'Error: Too many arguments.'
    exit 2
}

[[ "$architecture" == arm64 || "$architecture" == x86_64 ]] || {
    print -u2 -- "Error: Unsupported architecture: $architecture"
    exit 1
}

for required_file in "$source_file" "$info_plist"; do
    [[ -f "$required_file" ]] || {
        print -u2 -- "Error: Required file not found: $required_file"
        exit 1
    }
done

for required_command in swiftc plutil codesign; do
    command -v "$required_command" >/dev/null 2>&1 || {
        print -u2 -- "Error: Required command not found: $required_command"
        exit 1
    }
done

version="$(plutil -extract CFBundleShortVersionString raw "$info_plist")"
codename="$(plutil -extract ShadeCodename raw "$info_plist")"
print -- "Building $app_name $version \"$codename\" for $architecture..."

mkdir -p "$temporary_macos" "$temporary_resources"
cp -X "$info_plist" "$temporary_contents/Info.plist"
[[ ! -f "$icon_file" ]] || cp -X "$icon_file" "$temporary_resources/Shade.icns"

swiftc \
    "$source_file" \
    -O \
    -whole-module-optimization \
    -target "$architecture-apple-macosx$minimum_macos" \
    -framework AppKit \
    -o "$temporary_macos/$app_name"

chmod 755 "$temporary_macos/$app_name"
plutil -lint "$temporary_contents/Info.plist"
xattr -cr "$temporary_bundle" 2>/dev/null || true

codesign \
    --force \
    --deep \
    --options runtime \
    --sign "$sign_identity" \
    "$temporary_bundle"
codesign --verify --deep --strict --verbose=2 "$temporary_bundle"

if [[ -e "$app_bundle" ]]; then
    mv -- "$app_bundle" "$previous_bundle"
fi

if ! mv -- "$temporary_bundle" "$app_bundle"; then
    [[ ! -e "$previous_bundle" ]] || mv -- "$previous_bundle" "$app_bundle"
    print -u2 -- 'Error: Could not replace the previous application bundle.'
    exit 1
fi

# Finder may attach non-code metadata while the verified bundle is moved.
# Removing it does not alter signed bundle contents.
xattr -cr "$app_bundle" 2>/dev/null || true
codesign --verify --deep --strict --verbose=2 "$app_bundle"

print -- "Built: $app_bundle"
print -- "Signing identity: $sign_identity"
