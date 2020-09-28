#!/bin/bash

#
# by TS, Sep 2020
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
	[ -z "$LVAR_CANONICAL_BASE" ] && return 1
	[ -z "$1" ] && return 1
	if [ ! -f "tmpdown/$1" -o ! -f "tmpdown/$1.sha256" ]; then
		local TMP_DN="$(dirname "$1")"
		if [ "$TMP_DN" != "." -a "$TMP_DN" != "./" -a "$TMP_DN" != "/" ]; then
			[ ! -d "tmpdown/$TMP_DN" ] && {
				mkdir "tmpdown/$TMP_DN" || return 1
			}
		fi
		if [ ! -f "tmpdown/$1.sha256" ]; then
			if [ -z "$LVAR_SHASUMS" ]; then
				echo -e "\nDownloading file 'SHA256SUMS'...\n"
				curl -L \
						-o "tmpdown/all.sha256" \
						"${LVAR_CANONICAL_BASE}/SHA256SUMS" || return 1
				export LVAR_SHASUMS="$(cat "tmpdown/all.sha256")"
				rm "tmpdown/all.sha256"
			fi
			echo "$LVAR_SHASUMS" | grep -q -e " *$1$" || {
				echo "Could not find original SHA256 for file. Aborting." >>/dev/stderr
				return 1
			}
			echo "$LVAR_SHASUMS" | grep -e " *$1$" > "tmpdown/$1.sha256" || return 1
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
				"${LVAR_CANONICAL_BASE}/$1" || return 1
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

LVAR_UBUNTU_RELEASE="bionic"
LVAR_UBUNTU_VERSION="18.04.5"

LVAR_SHASUMS=""

[ ! -d tmpdown ] && mkdir tmpdown

for LVAR_UBUNTU_DIST in amd64 armhf arm64 i386; do
	LVAR_CANONICAL_BASE="https://partner-images.canonical.com/core/$LVAR_UBUNTU_RELEASE/current"
	echo -e "\n - src: [$LVAR_UBUNTU_DIST] '$LVAR_CANONICAL_BASE'"
	TMP_FN_INP="ubuntu-$LVAR_UBUNTU_RELEASE-core-cloudimg-$LVAR_UBUNTU_DIST-root.tar.gz"
	_getRemoteFile "$TMP_FN_INP" || break
	TMP_FN_OUT="ubuntu-$LVAR_UBUNTU_RELEASE-$LVAR_UBUNTU_VERSION-core-cloudimg-$LVAR_UBUNTU_DIST-root.tgz"
	mv "tmpdown/$TMP_FN_INP" "$TMP_FN_OUT" || break
	md5sum_poly "$TMP_FN_OUT" > "$TMP_FN_OUT.md5" || break
done

rmdir tmpdown
