#!/bin/bash
# Usage:
#
#   with-temp-gopath.sh PACKAGE CMD [ARG ...]
#
# Sets up a temporary directory as $GOPATH; symlinks . to $GOPATH/src/PACKAGE;
# then invokes CMD [ARG ...] from that symlink.
#
# (Many Go tools insist on being run from the appropriate source directory
# within $GOPATH/src.)
set -e

PACKAGE=${1:?no PACKAGE specified}
shift

if [[ $# -eq 0 ]]; then
  echo "No CMD specified" >&2
  exit 64  # EX_USAGE from sysexits.h
fi

TEMP_GOPATH=
cleanup() {
  if [[ -n "$TEMP_GOPATH" && -d "$TEMP_GOPATH" ]]; then
    rm -rf "$GOPATH"
  fi
}
trap cleanup EXIT
TEMP_GOPATH=$(mktemp -d)
GOPATH="${TEMP_GOPATH}${GOPATH:+:$GOPATH}"
export GOPATH

GOPATH_SRCDIR="$TEMP_GOPATH/src/$PACKAGE"
SRCDIR=$(readlink -f "$PWD")
mkdir -p "$(dirname "$GOPATH_SRCDIR")"
ln -s "$SRCDIR" "$GOPATH_SRCDIR"

cd "$GOPATH_SRCDIR"
echo "Running '$*' in $GOPATH_SRCDIR" >&2
"$@"
