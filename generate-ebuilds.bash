#!/bin/bash
# Generate a set of ebuilds installing systemd services for packages.

generate_ebuild() {
	local f svc=${1} rev=${2}
	shift 2

	cat <<_EOF_
# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# \$Header: $

EAPI=4

inherit systemd

DESCRIPTION="Systemd units for ${svc}"
HOMEPAGE=""
SRC_URI=""

LICENSE="as-is"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

S=\${WORKDIR}

src_install() {
_EOF_

	for f; do
		echo '	systemd_newunit "${FILESDIR}"/'${f}.${rev} ${f}
	done

	echo '}'
}

main() {
	set -ex

	local src=${1} dest=${2}

	if [[ ! ${src} || ! ${dest} ]]; then
		echo "Usage: ${0} <source> <destination>"
		exit 1
	fi

	local destroot=${dest}/systemd-units

	local dir
	for dir in ${src}/*:*; do
		local dn=${dir##*/}
		local bn=${dn#*:}
		local pkg=${dn/://}

		local rev=$(git --work-tree="${dir}" rev-list HEAD -- "${dir}" | wc -l)
		(( rev-- ))

		local files=( "${dir}"/* )
		local pv=${bn}-${rev}
		local filesdir="${destroot}"/${bn}/files

		mkdir -p "${filesdir}"
		local f
		for f in "${files[@]}"; do
			cp "${f}" "${filesdir}"/${f##*/}.${rev}
		done
		generate_ebuild ${pkg} ${rev} "${files[@]##*/}" > "${destroot}"/${bn}/${pv}.ebuild
	done
}

main "${@}"
