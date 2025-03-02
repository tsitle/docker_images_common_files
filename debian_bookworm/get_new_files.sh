#!/bin/bash

#
# by TS, Feb 2020, Mar 2025
#

VAR_MYNAME="$(basename "$0")"

# ----------------------------------------------------------

function md5sum_poly() {
	case "$OSTYPE" in
		linux*) md5sum "$1" ;;
		darwin*) md5 -r "$1" | sed -e 's/ /  /' ;;
		*) echo "Error: Unknown OSTYPE '$OSTYPE'" >>/dev/stderr; echo -n "$1" ;;
	esac
}

function sha256sum_poly() {
	case "$OSTYPE" in
		linux*) sha256sum "$1" ;;
		darwin*) shasum -a 256 "$1" ;;
		*) echo "Error: Unknown OSTYPE '$OSTYPE'" >>/dev/stderr; echo -n "$1" ;;
	esac
}

# @param string $1 Filename
function _getRemoteFile() {
	[ -z "$LVAR_GITHUB_BASE" ] && return 1
	[ -z "$1" ] && return 1
	if [ ! -f "tmpdown/$1" ]; then
		local TMP_DN="$(dirname "$1")"
		if [ "$TMP_DN" != "." -a "$TMP_DN" != "./" -a "$TMP_DN" != "/" ]; then
			[ ! -d "tmpdown/$TMP_DN" ] && {
				mkdir "tmpdown/$TMP_DN" || return 1
			}
		fi

		echo -e "\nDownloading file '$1'...\n"
		curl -L \
				-o "tmpdown/$1" \
				"${LVAR_GITHUB_BASE}/$1" || return 1
	fi
	return 0
}

# ----------------------------------------------------------

#LVAR_DEBIAN_RELEASE="stretch"
#LVAR_DEBIAN_VERSION="9.13"
#LVAR_DEBIAN_RELEASE="buster"
#LVAR_DEBIAN_VERSION="10.5"
#LVAR_DEBIAN_RELEASE="bullseye"
#LVAR_DEBIAN_VERSION="11.2"
LVAR_DEBIAN_RELEASE="bookworm"
LVAR_DEBIAN_VERSION="12.9"

[ ! -d tmpdown ] && mkdir tmpdown

for LVAR_DEBIAN_DIST in amd64 arm32v7 arm64v8; do
	LVAR_GITHUB_BASE="https://raw.githubusercontent.com/debuerreotype/docker-debian-artifacts/dist-$LVAR_DEBIAN_DIST/$LVAR_DEBIAN_RELEASE/oci/blobs"
	echo -e "\n - src: '$LVAR_GITHUB_BASE'"
	_getRemoteFile rootfs.tar.gz || break
	TMP_FN_OUT="rootfs-debian_${LVAR_DEBIAN_RELEASE}_${LVAR_DEBIAN_VERSION}-${LVAR_DEBIAN_DIST}.tar.gz"
	mv "tmpdown/rootfs.tar.gz" "$TMP_FN_OUT" || break
	md5sum_poly "$TMP_FN_OUT" > "$TMP_FN_OUT.md5" || break
done

rmdir tmpdown
