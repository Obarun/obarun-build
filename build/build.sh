#!@BINDIR@/bash
# Copyright (c) 2015-2018 Eric Vidal <eric@obarun.org>
# All rights reserved.
# 
# This file is part of Obarun. It is subject to the license terms in
# the LICENSE file found in the top-level directory of this
# distribution and at https://github.com/Obarun/obarun-build/LICENSE
# This file may not be copied, modified, propagated, or distributed
# except according to the terms contained in the LICENSE file.


check_source(){
	local _named="${1}"
	check_dir "${SOURCES}/${_named}"
	if (( $? )); then
		die "${_named} do not exist on ${SOURCES} directory" "clean_install"
	fi
	unset _named
}
check_pkgbuild(){
	local _named="${1}"
	search_in_dir "${SOURCES}" "${_named}" "PKGBUILD"
	if (( $? )); then
		die " Aborting : a PKGBUILD file must at least exist into ${SOURCES} directory" "clean_install"
	fi
	unset _named
}
save_pkg(){
	local base_named="${1}" base_named_version="${2}" _named="${3}" _named_version="${4}"
	check_dir "${SAVE_PKG}/${_named}/${_named_version}"
	if (( $? )); then
		mkdir -p "${SAVE_PKG}/${_named}/${_named_version}"
	fi
	out_valid "Copy $(ls ${target}/${base_named}-${base_named_version}/${workdir}/${BUILD_DEST_FILES}/${_named}-${_named_version}|grep .pkg.tar.xz) to ${SAVE_PKG}/${_named}/${_named_version}" 
	cp -f "${target}/${base_named}-${base_named_version}/${workdir}/${BUILD_DEST_FILES}/${_named}-${_named_version}"/*.pkg.tar.xz "${SAVE_PKG}/${_named}/${_named_version}" || out_info "WARNING : the resulting package can be copied to ${SAVE_PKG}/${_named}/${_named_version}"
	chown -R "${OWNER}":users "${SAVE_PKG}/${_named}/${_named_version}"
	
	unset base_named base_named_version _named _named_version
}

# ${1} name of the container
# ${2} inner variable
# ${@} arguments to pass. Can be empty
set_pkgver_rel(){
	local _named="${1}" ver rel
	declare -n pnver="${2}" 
	
	# sanitize the pkgver pkgrel first
	unset pkgver pkgrel 
	
	source "${SOURCES}/${_named}/PKGBUILD"
	
	ver="${pkgver}"
	rel="${pkgrel}"
	pnver="${ver}-${rel}"
	
	unset _named  ver rel
}
build(){
	local named snap target workdir tidy_loop named_version named_versionlist
	local -a _args
	named="${1}"
	snap="${2}" #0 for not
	target="${TARGET}"
	workdir="${WORKDIR}/rootfs"
	
	
	_args=( "${@}" )
	_args=( "${_args[@]:2}" )

	clean_build(){
		named="${named}-${named_version}"
		lxc_command_parse "stop" "${named}" -k -P "${WORKLXC}"
		clean_install
	}
	
	# check if sources variables is set
	if [[ -z "${SOURCES}" ]]; then
		die "Aborting : SOURCES variables on /etc/obarun/build.conf is not set" "clean_install"
	fi
	
	# be sure that $named exist on $SOURCES directory
	check_source "${named}"
	if(( ${#_args} )); then
		for tidy_loop in "${_args[@]}"; do
			check_source "${tidy_loop}"
		done
	fi
	
	#check_dir "${SOURCES}/${named}"
	#if (( $? )); then
	#	die "${named} do not exist on ${SOURCES} directory" "clean_install"
	#fi
	
	# be sure that a PKGBUILD file exit on $SOURCES/$named
	check_pkgbuild "${named}"
	if(( ${#_args} )); then
		for tidy_loop in "${_args[@]}"; do
			check_pkgbuild "${tidy_loop}"
		done
	fi
	
	# retrieve pkgver and pkgrel to implemente them onto the name
	set_pkgver_rel "${named}" named_version 
			
	# be sure that the named container doesn't exist
	lxc-ls | grep "${named}-${named_version}" &>/dev/null
	if (( ! $? )); then
		die " Container already exist, please choose another name" "clean_install"
	fi
	# create bridge if it not exist yet
	if [[ ! -f /run/lxc/network_up ]]; then
		/usr/lib/lxc/lxc-net start
	fi
	# snap is used?
	if (( "${snap}" ));then
		if [[ -z "${MAIN_SNAP}" ]];then
			die " The main container in build.conf is not set, please define it" "clean_install"
		fi
		#check if main container exist
		check_dir "${target}/${MAIN_SNAP}"
		if (( $? )); then
			die " ${MAIN_SNAP} do not exist, please create it" "clean_install"
		fi
		
		# now we are sure to use snap
		# change TARGET variable to WORKLXC and workdir to delta0 directory
		target="${WORKLXC}"
		workdir="delta0"
		
		#update the main container
		out_action "Would you like upgrade the ${SNAP_CONT} container? [y|n]"
		reply_answer
		if (( ! $? )); then
			lxc_command_parse "start" "${MAIN_SNAP}" -P "${WORKLXC}" || die " Aborting : impossible to start the container ${MAIN_SNAP}" "clean_install"
			lxc_command_parse "attach" "${MAIN_SNAP}" -P "${WORKLXC}" -- bash -c 'pacman -Syyu' || out_info "WARNING : impossible to upgrade ${MAIN_SNAP} container" 
			lxc_command_parse "attach" "${MAIN_SNAP}" -P "${WORKLXC}" -- bash -c 'poweroff'
			while lxc_command_parse "info" "${MAIN_SNAP}" -P "${WORKLXC}" -s |grep RUNNING >/dev/null; do
				sleep 0.1
			done # be sure that the container is stopped, if not lxc-copy fail
		fi
		lxc_command_parse "copy" "${MAIN_SNAP}" -N "${named}-${named_version}" -P "${WORKLXC}" -B overlay -s || die " Aborting : impossible to start the container ${named}-${named_version}" "clean_build"
	else
		# create the container
		create "${named}-${named_version}"
	fi

	# start the container
	lxc_command_parse "start" "${named}-${named_version}" -P "${WORKLXC}" || die " Aborting : impossible to start the container ${named}-${named_version}" "clean_build"
			
	# copy $SOURCES/$named files onto the container
	lxc_command_parse "attach" "${named}-${named_version}" -P "${WORKLXC}" --clear-env -v named="${named}-${named_version}" -v newuser="${NEWUSER}" -v build_dest_files="${BUILD_DEST_FILES}" \
		-- bash -c 'su "${newuser}"  -c "mkdir -p ${build_dest_files}"' || die " Impossible to create ${BUILD_DEST_FILES} directory" "clean_build"
	
	cp -a "${SOURCES}/${named}" "${target}/${named}-${named_version}/${workdir}/${BUILD_DEST_FILES}/${named}-${named_version}" || die " Impossible to copy file from ${SOURCES}/${named}" "clean_build"
	if(( ${#_args} )); then
		for tidy_loop in "${_args[@]}"; do
			set_pkgver_rel "${tidy_loop}" named_versionlist 
			cp -a "${SOURCES}/${tidy_loop}" "${target}/${named}-${named_version}/${workdir}/${BUILD_DEST_FILES}/${tidy_loop}-${named_versionlist}" || die " Impossible to copy file from ${SOURCES}/${tidy_loop}" "clean_build"
		done
	fi
	# give a good permissions at the tmp/$named onto the container
	lxc_command_parse "attach" "${named}-${named_version}" -P "${WORKLXC}" --clear-env -v named="${named}-${named_version}" -v newuser="${NEWUSER}" \
		-- bash -c 'echo "${newuser}" "ALL=(ALL)" NOPASSWD: ALL >> /etc/sudoers'
	lxc_command_parse "attach" "${named}-${named_version}" -P "${WORKLXC}" --clear-env -v named="${named}-${named_version}" -v newuser="${NEWUSER}" -v build_dest_files="${BUILD_DEST_FILES}" \
		-- bash -c 'chown -R "${newuser}":users "${build_dest_files}/${named}"'
	if(( ${#_args} )); then
		for tidy_loop in "${_args[@]}"; do
			set_pkgver_rel "${tidy_loop}" named_versionlist 
			lxc_command_parse "attach" "${named}-${named_version}" -P "${WORKLXC}" --clear-env -v named="${tidy_loop}-${named_versionlist}" -v newuser="${NEWUSER}" -v build_dest_files="${BUILD_DEST_FILES}" \
				-- bash -c 'chown -R "${newuser}":users "${build_dest_files}/${named}"'
		done
	fi
	# by sure to use the last version of packages
	#lxc_command_parse "attach" "${named}-${named_version}" -P "${WORKLXC}" -- bash -c 'pacman -Syy'
	
	# build the package
	lxc_command_parse "attach" "${named}-${named_version}" -P "${WORKLXC}" --clear-env -v named="${named}-${named_version}" -v newuser="${NEWUSER}" -v build_dest_files="${BUILD_DEST_FILES}" \
		-- bash -c 'su "${newuser}"  -c "cd "${build_dest_files}/${named}" && updpkgsums && makepkg -Cfs --noconfirm"' || die " Unable to build the package" "clean_build"
	# copy the resulting package on the right place
	save_pkg "${named}" "${named_version}" "${named}" "${named_version}"
	
	# install and build the list of package
	if(( ${#_args} )); then
		lxc_command_parse "attach" "${named}-${named_version}" -P "${WORKLXC}" --clear-env -v named="${named}-${named_version}" -v newuser="${NEWUSER}" -v build_dest_files="${BUILD_DEST_FILES}" \
			-- bash -c 'cd "${build_dest_files}/${named}";for i in $(ls |grep ".pkg.tar.xz"|grep -v ".sig");do pacman -U $i --noconfirm;done' || die " Unable to install the package ${named}" "clean_build"
		for tidy_loop in "${_args[@]}"; do
			set_pkgver_rel "${tidy_loop}" named_versionlist 
			#build the package
			lxc_command_parse "attach" "${named}-${named_version}" -P "${WORKLXC}" --clear-env -v named="${tidy_loop}-${named_versionlist}" -v newuser="${NEWUSER}" -v build_dest_files="${BUILD_DEST_FILES}" \
				-- bash -c 'su "${newuser}"  -c "cd "${build_dest_files}/${named}" && updpkgsums && makepkg -Cfs --noconfirm"' || die " Unable to build the package ${tidy_loop}" "clean_build"
			#install the package
			lxc_command_parse "attach" "${named}-${named_version}" -P "${WORKLXC}" --clear-env -v named="${tidy_loop}-${named_versionlist}" -v newuser="${NEWUSER}" -v build_dest_files="${BUILD_DEST_FILES}" \
				-- bash -c 'cd "${build_dest_files}/${named}";for i in $(ls |grep ".pkg.tar.xz"|grep -v ".sig");do pacman -U $i --noconfirm;done' || die " Unable to install the package ${tidy_loop}" "clean_build"
			#save it
			save_pkg "${named}" "${named_version}" "${tidy_loop}" "${named_versionlist}"
		done
	fi

	# stop the container
	lxc_command_parse "stop" "${named}-${named_version}" -P "${WORKLXC}" -k || die " Impossible to stop the container" "clean_build"
	
	out_action "Would you like to destroy the container? [y|n]"
	reply_answer
	if (( ! $? )); then
		lxc_command_parse "destroy" "${named}-${named_version}" -P "${WORKLXC}" && rm -rf "${target}/${named}-${named_version}"
	fi
}

