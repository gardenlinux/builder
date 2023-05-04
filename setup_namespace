#!/usr/bin/env bash

set -eufo pipefail

if [ "${1-}" = --second-stage ]; then
	shift
	mount -t tmpfs none /tmp
	"$@"
else
	unshare --map-root-user --map-users auto --map-groups auto --mount "$0" --second-stage "$@"
fi
