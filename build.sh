#!/usr/bin/bash
#
# Functions file for obarun-build package
#
# Authors:
# Eric Vidal <eric@obarun.org>
#
# Copyright (C) 2016-2017 Eric Vidal <eric@obarun.org>
#
# "THE BEERWARE LICENSE" (Revision 42):
# <eric@obarun.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Eric Vidal http://obarun.org
#
# This script is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 

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

usage(){
	cat << EOF
	
${bold}Usage: ${0} [General options] [Sub options] name

e.g obarun-build Create create container
    obarun-build C c container
    obarun-build B b cups
    obarun-build M container
    obarun-build M network${reset}
    
${bold}General options :${reset}
    C, Create : create a container
    B, Build : build a package onto a container
    M, Manage : open an interactive shell to manage a named container

${bold}Sub options :${reset}
    for Create :
        c, create : create a container
    for Build :
        b, build : build a package onto a container
        s, snap : build a package onto a snapshot container
        r, remake : build a package onto an archived container
    for Manage :
        n, network : manage the bridge
EOF
	exit 0
}

# ${1} name of the container to create
# ${@} arguments to pass. Can be empty
create(){

	local file named
	local -a file_list _args
	
	mapfile -t file_list < <(ls --group-directories-first ${TEMPLATES}/*)
	
	named="${1}"
	_args=( "${@}" )
	_args=( "${_args[@]:1}" )

	# check if container directory exist
	# if yes then exit container exit
	check_dir "${TARGET}/${named}"
	if (( ! $? )); then
		out_info "Container already exist, do you want overwrite it? [y|n] :"
		reply_answer
		if (( $? )); then
			die " Exiting"
		else
			delete_container "${TARGET}" "${named}"
		fi
	fi
	
	# create the templates directory on $TARGET
	out_action "Create ${TARGET}/${named}/${WORKCONF}"
	mkdir -p "${TARGET}/${named}/${WORKCONF}" || die " Impossible to create directory ${TARGET}/${named}/${WORKCONF}" "clean_install"
	
	# copy configuration file to $TARGET
	for file in "${file_list[@]}"; do
		file=${file##*/}
		out_action "Copy ${file} templates file to ${TARGET}/${named}/${WORKCONF}"
		cp "${TEMPLATES}/${file}" "${TARGET}/${named}/${WORKCONF}" || die " Impossible to copy ${file}" "clean_install"
	done
	
	# now we have to correct place to find configuration file to create and configure the container
	# so, exporting the good one
	export named="${named}"

	check_var(){
		echo create_conf :: "${create_conf}"
		echo named :: "${named}"
		echo WORKDIR :: "${WORKDIR}"
		echo WORKCONF :: "${WORKCONF}"
	}
	#check_var
	lxc_command_parse "create" "${named}" -t "${TARGET}/${named}/${WORKCONF}/create" "${_args[@]}" || die " Impossible to create the container"
	
}

# ${1} name of the container
# ${2} inner variable
# ${@} arguments to pass. Can be empty
build(){
	local named
	local -a _args
	named="${1}"
	snap="${2}" #0 for not
	target="${TARGET}"
	workdir="${WORKDIR}/rootfs"
	
	_args=( "${@}" )
	_args=( "${_args[@]:2}" )
	
	clean_build(){
		lxc_command_parse "stop" "${named}-${named_version}" -k
		out_action "Would you like to destroy the container? [y|n]"
		reply_answer
		if (( ! $? )); then
			lxc_command_parse "destroy" "${named}-${named_version}"
			rm -rf "${target}/${named}-${named_version}"
		fi
		out_valid "Restore your shell options"
		shellopts_restore
	}
	
	# check if sources variables is set
	if [[ -z "${SOURCES}" ]]; then
		die "Aborting : SOURCES variables on /etc/obarun/build.conf is not set" "clean_build"
	fi
	
	# be sure that $named exist on $SOURCES directory
	check_dir "${SOURCES}/${named}"
	if (( $? )); then
		die "${named} do not exist on ${SOURCES} directory" "clean_build"
	fi
	
	# be sure that a PKGBUILD file exit on $SOURCES/$named
	search_in_dir "${SOURCES}" "${named}" "PKGBUILD"
	if (( $? )); then
		die " Aborting : a PKGBUILD file must at least exist into ${SOURCES} directory" "clean_build"
	fi
	
	# retrieve pkgver and pkgrel to implemente them onto the name
	# sanitize the pkgver pkgrel first
	unset pkgver pkgrel
	
	source "${SOURCES}/${named}/PKGBUILD"
	
	_pkgver="$pkgver"
	_pkgrel="$pkgrel"
	named_version="${_pkgver}-${_pkgrel}"
	
	# be sure that the named container doesn't exist
	lxc-ls | grep "${named}-${named_version}" &>/dev/null
	if (( ! $? )); then
		die " Container already exist, please choose another name"
	fi
	
	# snap is used?
	if (( "${snap}" ));then
		if [[ -z "${MAIN_SNAP}" ]];then
			die " The main container in build.conf is not set, please define it" "clean_install"
		fi
		#check if main container exist
		check_dir "${target}/${MAIN_SNAP}"
		if (( $? )); then
			die " ${MAIN_SNAP} do not exist, please create it" "clean_build"
		fi
		
		# now we are sure to use snap
		# change TARGET variable to LXC_CONF and workdir to delta0 directory
		target="${LXC_CONF}"
		workdir="delta0"
		
		#update the main container
		out_action "Would you like upgrade the ${SNAP_CONT} container? [y|n]"
		reply_answer
		if (( ! $? )); then
			lxc_command_parse "start" "${MAIN_SNAP}" || die " Aborting : impossible to start the container ${MAIN_SNAP}" "clean_build"
			
			# assigning the host interface to the bridge cause a losing connection on the host
			# so disable it and reassigne it solve this issue
			ip link set "${HOST_INTERFACE}" nomaster "${BRIDGE_INTERFACE}"
			ip link set "${HOST_INTERFACE}" master "${BRIDGE_INTERFACE}"
			
			lxc_command_parse "attach" "${MAIN_SNAP}" -- bash -c 'pacman -Syu' || out_info "WARNING : impossible to upgrade ${MAIN_SNAP} container" 
			lxc_command_parse "attach" "${MAIN_SNAP}" -- bash -c 'poweroff'
			sleep 2 # be sure that the container is stopped, if not lxc-copy fail
		fi
		lxc_command_parse "copy" "${MAIN_SNAP}" -N "${named}-${named_version}" -B overlay -s || die " Aborting : impossible to start the container ${named}-${named_version}" "clean_build"
	else
		# create the container
		create "${named}-${named_version}" "${_args[@]}"
	fi

	# start the container
	lxc_command_parse "start" "${named}-${named_version}" || die " Aborting : impossible to start the container ${named}-${named_version}" "clean_build"
			
	# assigning the host interface to the bridge cause a losing connection on the host
	# so disable it and reassigne it solve this issue
	ip link set "${HOST_INTERFACE}" nomaster "${BRIDGE_INTERFACE}"
	ip link set "${HOST_INTERFACE}" master "${BRIDGE_INTERFACE}"
		
	# copy $SOURCES/$named files onto the container
	lxc_command_parse "attach" "${named}-${named_version}" --clear-env -v named="${named}-${named_version}" -v newuser="${NEWUSER}" -v build_dest_files="${BUILD_DEST_FILES}"\
		-- bash -c 'su "${newuser}"  -c "mkdir -p ${build_dest_files}"' || die " Impossible to create ${BUILD_DEST_FILES} directory" "clean_build"
	
	#mkdir -p -m1777 "${TARGET}/${named}-${named_version}/${WORKDIR}/rootfs/${BUILD_DEST_FILES}" || die "peut pas copied"
	cp -ra "${SOURCES}/${named}" "${target}/${named}-${named_version}/${workdir}/${BUILD_DEST_FILES}/${named}-${named_version}" || die " Impossible to copy file from ${SOURCES}/${named}-${named_version}" "clean_build"
		
	# give a good permissions at the tmp/$named onto the container
	lxc_command_parse "attach" "${named}-${named_version}" --clear-env -v named="${named}-${named_version}" -v newuser="${NEWUSER}"\
		-- bash -c 'echo "${newuser}" "ALL=(ALL)" NOPASSWD: ALL >> /etc/sudoers'
	lxc_command_parse "attach" "${named}-${named_version}" --clear-env -v named="${named}-${named_version}" -v newuser="${NEWUSER}" -v build_dest_files="${BUILD_DEST_FILES}"\
		-- bash -c 'chown -R "${newuser}":users "${build_dest_files}/${named}"'
	
	# build the package
	lxc_command_parse "attach" "${named}-${named_version}" --clear-env -v named="${named}-${named_version}" -v newuser="${NEWUSER}" -v build_dest_files="${BUILD_DEST_FILES}"\
		-- bash -c 'cd "${build_dest_files}/${named}"; su "${newuser}"  -c "updpkgsums; makepkg -Cfs --noconfirm"' || die " Something wrong happen at building the package" "clean_build"
	
	# copy the resulting package on the right place
	check_dir "${SAVE_PKG}/${named}/${named_version}"
	if (( $? )); then
		mkdir -p "${SAVE_PKG}/${named}/${named_version}"
	fi
	cp -f "${target}/${named}-${named_version}/${workdir}/${BUILD_DEST_FILES}/${named}-${named_version}"/*.pkg.tar.xz "${SAVE_PKG}/${named}/${named_version}" || out_info "WARNING : the resulting package can be copied to ${SAVE_PKG}/${named}/${named_version}"
	chown -R "${OWNER}":users "${SAVE_PKG}/${named}/${named_version}"
	
	# stop the container
	lxc_command_parse "stop" "${named}-${named_version}" -k || die " Impossible to stop the container" "clean_build"
	
	out_action "Would you like to destroy the container? [y|n]"
	reply_answer
	if (( ! $? )); then
		lxc_command_parse "destroy" "${named}-${named_version}" && rm -rf "${target}/${named}-${named_version}"
	fi
}

remake(){
	out_error "Features not implemented"
}



