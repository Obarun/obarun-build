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
	if ! cp -f "${target}/${base_named}-${base_named_version}/${workdir}/${BUILD_DEST_FILES}/${_named}-${_named_version}"/*.pkg.tar.xz "${SAVE_PKG}/${_named}/${_named_version}";then
		out_info "WARNING : the resulting package can be copied to ${SAVE_PKG}/${_named}/${_named_version}"
		return 1
	fi
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
make_pkgconf(){
	local _makedest="${1}" _newuser="${2}" dest="${3}" _named="${4}"
	exec 3>&1 1>"${_makedest}"/makedest.sh
cat <<EOF
#!/usr/bin/bash
trap "exit 1" INT TERM KILL
echo "${_newuser} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
chown -R ${_newuser}:users ${dest}
pacman -Sy || exit 1
cd ${dest}/${_named}
su ${_newuser} -c "updpkgsums" || exit 1
su ${_newuser} -c "makepkg -Cfis --noconfirm --nosign" || exit 1
#for i in \$(ls |grep ".pkg.tar.xz"|grep -v ".sig");do 
#pacman -U \$i --noconfirm;
#done
EOF
	exec 1>&3 3>&-
	chmod +x "${_makedest}"/makedest.sh
	unset _newuser dest _named
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
	if(( ${#_args} )); then
		for tidy_loop in "${_args[@]}"; do
			check_source "${tidy_loop}"
			if (( $? )); then
				die "${tidy_loop} do not exist on ${SOURCES} directory" "clean_install"
			fi
		done
	else
		check_source "${named}"
		if (( $? )); then
			die "${named} do not exist on ${SOURCES} directory" "clean_install"
		fi
	fi
	
	# be sure that a PKGBUILD file exit on $SOURCES/$named
	if(( ${#_args} )); then
		for tidy_loop in "${_args[@]}"; do
			check_pkgbuild "${tidy_loop}"
			if (( $? )); then
				die "Unable to find PKGBUILD for ${tidy_loop}" "clean_install"
			fi
		done
	else
		check_pkgbuild "${named}"
		if (( $? )); then
			die "Unable to find PKGBUILD for ${named}" "clean_install"
		fi
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
		out_action "Would you like to upgrade the ${SNAP_CONT} container? [y|n]"
		reply_answer
		if (( ! $? )); then
			lxc_command_parse "execute" "${MAIN_SNAP}" -P "${WORKLXC}" -f "${target}"/"${MAIN_SNAP}"/config -- pacman -Syyu --noconfirm || die "Unable to upgrade ${MAIN_SNAP} container" "clean_build" 
		fi
		lxc_command_parse "copy" "${MAIN_SNAP}" -N "${named}-${named_version}" -P "${target}" -B overlay -s || die " Unable to copy the container ${named}-${named_version}" "clean_build"
	else
		# create the container
		create "${named}-${named_version}"
	fi
	
	mkdir -p -m 0755 "${target}/${named}-${named_version}/${workdir}/${BUILD_DEST_FILES}/"
	cp -a "${SOURCES}/${named}" "${target}/${named}-${named_version}/${workdir}/${BUILD_DEST_FILES}/${named}-${named_version}" || die " Unable to copy file from ${SOURCES}/${named}" "clean_build"

	if(( ${#_args} )); then
		for tidy_loop in "${_args[@]}"; do
			set_pkgver_rel "${tidy_loop}" named_versionlist 
			cp -a "${SOURCES}/${tidy_loop}" "${target}/${named}-${named_version}/${workdir}/${BUILD_DEST_FILES}/${tidy_loop}-${named_versionlist}" || die " Unable to copy file from ${SOURCES}/${tidy_loop}" "clean_build"
		done
	fi
	
	#build the package
	make_pkgconf "${target}/${named}-${named_version}/${workdir}/${BUILD_DEST_FILES}" "${NEWUSER}" "${BUILD_DEST_FILES}" "${named}-${named_version}"
	lxc_command_parse "start" "${named}-${named_version}" -P "${WORKLXC}" || die " Aborting : impossible to start the container ${named}-${named_version}" "clean_build"
	lxc_command_parse "attach" "${named}-${named_version}" -P "${WORKLXC}" -v build_dest_files="${BUILD_DEST_FILES}" -- bash -c '"${build_dest_files}"/makedest.sh' || die "Unable to build package ${named}-${named_version}" "clean_build"
	
	# copy the resulting package on the right place
	if  ! save_pkg "${named}" "${named_version}" "${named}" "${named_version}"; then
		die "Unable to save compiled package" "clean_build"
	fi
	
	# install and build the list of package
	if(( ${#_args} )); then
		for tidy_loop in "${_args[@]}"; do
			set_pkgver_rel "${tidy_loop}" named_versionlist 
			#build the package
			make_pkgconf "${target}/${named}-${named_version}/${workdir}/${BUILD_DEST_FILES}"	"${NEWUSER}" "${BUILD_DEST_FILES}" "${tidy_loop}-${named_versionlist}"
			lxc_command_parse "attach" "${named}-${named_version}" -P "${WORKLXC}" -v build_dest_files="${BUILD_DEST_FILES}" -- bash -c '"${build_dest_files}"/makedest.sh' || die "Unable to build package ${tidy_loop}-${named_versionlist}" "clean_build"
			#save it
			if ! save_pkg "${named}" "${named_version}" "${tidy_loop}" "${named_versionlist}"; then
				die "Unable to save package" "clean_build"
			fi
		done
	fi

	# stop the container
	if ! lxc_command_parse "stop" "${named}-${named_version}" -P "${WORKLXC}" -k; then
		die " Impossible to stop the container" "clean_build"
	fi
	out_action "Would you like to destroy the container? [y|n]"
	reply_answer
	if (( ! $? )); then
		lxc_command_parse "destroy" "${named}-${named_version}" -P "${WORKLXC}" && rm -rf "${target}/${named}-${named_version}"
	fi
}
