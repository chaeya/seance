#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
build_script="$repo_root/scripts/build-deb.sh"

if [ ! -x "$build_script" ]; then
    printf '%s\n' "missing build script: $build_script" >&2
    exit 1
fi

sudo_cmd() {
    echo "exitem08" | sudo -S "$@"
}

tmpdir=$(mktemp -d)
cleanup() {
    sudo_cmd dpkg -r seance >/dev/null 2>&1 || true
    rm -rf "$tmpdir"
}
trap cleanup EXIT INT TERM

deb_path=$("$build_script" --output-dir "$tmpdir")

if [ ! -f "$deb_path" ]; then
    printf '%s\n' "package not created: $deb_path" >&2
    exit 1
fi

sudo_cmd dpkg -i "$deb_path"

seance --help >/dev/null
seance ctl help >/dev/null
