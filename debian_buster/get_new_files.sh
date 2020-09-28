#!/bin/bash

#
# by TS, Feb 2020
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
# @param bool $2 (Optional) Output error on SHA256.err404? Default=true
function _getRemoteFile() {
	[ -z "$LVAR_GITHUB_BASE" ] && return 1
	[ -z "$1" ] && return 1
	if [ ! -f "tmpdown/$1" -o ! -f "tmpdown/$1.sha256" ]; then
		local TMP_DN="$(dirname "$1")"
		if [ "$TMP_DN" != "." -a "$TMP_DN" != "./" -a "$TMP_DN" != "/" ]; then
			[ ! -d "tmpdown/$TMP_DN" ] && {
				mkdir "tmpdown/$TMP_DN" || return 1
			}
		fi
		if [ ! -f "tmpdown/$1.sha256" ]; then
			echo -e "\nDownloading file '$1.sha256'...\n"
			curl -L \
					-o "tmpdown/$1.sha256" \
					"${LVAR_GITHUB_BASE}/$1.sha256" || return 1
		fi

		local TMP_SHA256EXP="$(cat "tmpdown/$1.sha256" | cut -f1 -d\ )"
		if [ -z "$TMP_SHA256EXP" ]; then
			echo "Could not get expected SHA256. Aborting." >>/dev/stderr
			rm "tmpdown/$1.sha256"
			return 1
		fi
		if [ "$TMP_SHA256EXP" = "404:" ]; then
			[ "$2" != "false" ] && echo "Could not download SHA256 file (Err 404). Aborting." >>/dev/stderr
			rm "tmpdown/$1.sha256"
			return 2
		fi

		echo -e "\nDownloading file '$1'...\n"
		curl -L \
				-o "tmpdown/$1" \
				"${LVAR_GITHUB_BASE}/$1" || return 1
		local TMP_SHA256CUR="$(sha256sum_poly "tmpdown/$1" | cut -f1 -d\ )"
		if [ "$TMP_SHA256EXP" != "$TMP_SHA256CUR" ]; then
			echo -e "\nExpected SHA256 != current SHA256. Aborting." >>/dev/stderr
			echo "  '$TMP_SHA256EXP' != '$TMP_SHA256CUR'" >>/dev/stderr
			echo "Renaming file to '${1}-'" >>/dev/stderr
			mv "tmpdown/$1" "tmpdown/${1}-"
			return 1
		fi
		rm "tmpdown/$1.sha256"
	fi
	return 0
}

# ----------------------------------------------------------

#LVAR_DEBIAN_RELEASE="stretch"
#LVAR_DEBIAN_VERSION="9.13"
LVAR_DEBIAN_RELEASE="buster"
LVAR_DEBIAN_VERSION="10.5"

[ ! -d tmpdown ] && mkdir tmpdown

for LVAR_DEBIAN_DIST in amd64 arm32v7 arm64v8 i386; do
	LVAR_GITHUB_BASE="https://raw.githubusercontent.com/debuerreotype/docker-debian-artifacts/dist-$LVAR_DEBIAN_DIST/$LVAR_DEBIAN_RELEASE"
	echo -e "\n - src: '$LVAR_GITHUB_BASE'"
	_getRemoteFile rootfs.tar.xz || break
	TMP_FN_OUT="rootfs-debian_${LVAR_DEBIAN_RELEASE}_${LVAR_DEBIAN_VERSION}-${LVAR_DEBIAN_DIST}.tar.xz"
	mv "tmpdown/rootfs.tar.xz" "$TMP_FN_OUT" || break
	md5sum_poly "$TMP_FN_OUT" > "$TMP_FN_OUT.md5" || break
done

rmdir tmpdown
