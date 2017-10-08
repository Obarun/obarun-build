#!@BINDIR@/bash
# Copyright (c) 2015-2017 Eric Vidal <eric@obarun.org>
# All rights reserved.
# 
# This file is part of Obarun. It is subject to the license terms in
# the LICENSE file found in the top-level directory of this
# distribution and at https://github.com/Obarun/obarun-build/LICENSE
# This file may not be copied, modified, propagated, or distributed
# except according to the terms contained in the LICENSE file.

LIBRARY=${LIBRARY:-'/usr/lib/obarun'}
sourcing(){
	
	local list
	
	for list in ${LIBRARY}/build/*; do
		source "${list}"
	done
	
	unset list
}
sourcing

TEMPLATES="${TEMPLATES:-/usr/share/obarun/obarun-build/templates}"
WORKDIR="container"
WORKCONF="config"
LXC_CONF="/var/lib/lxc/"
BUILD_DEST_FILES="/home/${NEWUSER}/tmp"

parse_create(){
		
	if [[ -z "${arguments}" ]]; then
		out_error "Name must not be empty"
		usage
		exit 1
	fi
	
	case "${target}" in
		c|create)
			create "${arguments}" "${arguments_opts[@]}"
			;;
		*)
			usage
			exit 1
			;;
	esac

}

parse_build(){
		
	if [[ -z "${arguments}" ]]; then
		out_error "Name must not be empty"
		usage
		exit 1
	fi
	
	case "${target}" in
		b|build)
			build "${arguments}" 0 "${arguments_opts[@]}"
			;;
		r|remake)
			remake "${arguments}" 0 "${arguments_opts[@]}"
			;;
		s|snap)
			build "${arguments}" 1 "${arguments_opts[@]}"
			;;
		*)
			usage
			exit 1
			;;
	esac

}

parse_manage(){
		
	case "${target}" in
		n|network)	
			manage_network
			;;
		# Allow one character selection for other command
		*)	
			manage "${target}" #special case here, $target replace $arguments
			;;
	esac
	
}




