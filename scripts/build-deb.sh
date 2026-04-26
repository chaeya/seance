#!/bin/sh
set -eu

usage() {
    cat <<'EOF'
Usage: scripts/build-deb.sh [--output-dir DIR]

Build a Debian package for seance and print the resulting .deb path.
EOF
}

output_dir=

while [ $# -gt 0 ]; do
    case "$1" in
        --output-dir)
            shift
            [ $# -gt 0 ] || {
                printf '%s\n' "missing value for --output-dir" >&2
                exit 1
            }
            output_dir=$1
            ;;
        --output-dir=*)
            output_dir=${1#*=}
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf '%s\n' "unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
    shift
done

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

command -v zig >/dev/null 2>&1 || {
    printf '%s\n' "zig is required on PATH" >&2
    exit 1
}
command -v dpkg-deb >/dev/null 2>&1 || {
    printf '%s\n' "dpkg-deb is required on PATH" >&2
    exit 1
}

if [ -z "${output_dir:-}" ]; then
    output_dir=$(mktemp -d)
fi

mkdir -p "$output_dir"

base_version=$(awk -F'"' '/\.version =/ { print $2; exit }' "$repo_root/build.zig.zon")
[ -n "$base_version" ] || {
    printf '%s\n' "failed to read version from build.zig.zon" >&2
    exit 1
}

git_rev=unknown
dirty=
if git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git_rev=$(git -C "$repo_root" rev-parse --short=8 HEAD)
    if [ -n "$(git -C "$repo_root" status --porcelain)" ]; then
        dirty=.dirty
    fi
fi

version="${base_version}+git.${git_rev}${dirty}"
architecture=$(dpkg --print-architecture 2>/dev/null || true)
if [ -z "$architecture" ]; then
    case "$(uname -m)" in
        x86_64) architecture=amd64 ;;
        aarch64|arm64) architecture=arm64 ;;
        *)
            printf '%s\n' "unsupported architecture: $(uname -m)" >&2
            exit 1
            ;;
    esac
fi

staging=$(mktemp -d)
cleanup() {
    rm -rf "$staging"
}
trap cleanup EXIT INT TERM HUP

mkdir -p "$staging/DEBIAN"

zig build -p "$staging/usr" -Doptimize=ReleaseSafe -Dstrip=true

cat >"$staging/DEBIAN/control" <<EOF
Package: seance
Version: $version
Section: x11
Priority: optional
Architecture: $architecture
Maintainer: Séance Packagers <no-reply@localhost>
Depends: libadwaita-1-0, libappstream5, libcanberra0t64 | libcanberra0, libegl1, libepoxy0, libfontconfig1, libfreetype6, libgdk-pixbuf-2.0-0, libgio-2.0-0, libglib2.0-0, libgl1, libgraphene-1.0-0, libgtk-4-1, libharfbuzz0b, libjpeg-turbo8 | libjpeg62-turbo | libjpeg8, libnotify4, libonig5, libpango-1.0-0, libpng16-16, libwayland-client0, libx11-6, libxdamage1, libxfixes3, libxkbcommon0, libvulkan1, zlib1g
Description: Scrolling terminal multiplexer for AI coding agents
 Séance is a GTK4 terminal multiplexer for Linux with sidebar tracking,
 workspace management, and a Unix-socket CLI.
EOF

pkg_path="$output_dir/seance_${version}_${architecture}.deb"
dpkg-deb --build --root-owner-group "$staging" "$pkg_path" >/dev/null

printf '%s\n' "$pkg_path"
