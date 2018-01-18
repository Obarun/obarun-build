#!@BINDIR@/bash
# Copyright (c) 2015-2018 Eric Vidal <eric@obarun.org>
# All rights reserved.
# 
# This file is part of Obarun. It is subject to the license terms in
# the LICENSE file found in the top-level directory of this
# distribution and at https://github.com/Obarun/obarun-build/LICENSE
# This file may not be copied, modified, propagated, or distributed
# except according to the terms contained in the LICENSE file.

# ${1} name of the container
clean_install(){
	
	#local named="${1}"
	out_action "Cleaning up"
	
	kill_process "haveged dirmngr gpg-agent"
	
	if [[ -n "${named}" ]]; then
		if [[ -d "${TARGET}/${named}" ]]; then
			mount_umount "${TARGET}/${named}/${WORKDIR}/rootfs" "umount"
			out_action "Would you like to destroy the container ${named}? [y|n]"
			reply_answer
			if (( ! $? )); then
				delete_container "${TARGET}" "${named}" 2&>/dev/null
			fi
		fi
	fi
	if [[ -f /run/lxc/network_up ]];then
		out_action "Shutting down the container network"
		/usr/lib/lxc/lxc-net stop
	fi
	
	out_valid "Restore your shell options"
	shellopts_restore
	
	exit
}

# ${1} command to pass
# ${2} arguments to pass. Can be empty
# functions return 0 on success, 1 on other case
lxc_command_parse(){
	local command loop_ ret
	local -a parse_opt rest_opt
	
	command="${1}"
	parse_opt=( "${@}" )

	
	# check if lxc-${command} exist
	check_lxc_command "${command}"

	if (( ! $? )); then
		if [[ "${command}" == @(ls|autostart|checkconfig|top|usernsexec) ]]; then
			rest_opt=( "${parse_opt[@]:1}" )
			"lxc-${command}" "${rest_opt[@]}" || return 1 #die " Aborting command : lxc-${command} ${parse_opt[@]:1}"
		else
			if [[ -z "${parse_opt[1]}" ]]; then
				out_error "name must not be empty"
				return 1
			fi
			# if the container was not stopped before exiting of it
			# the command stop may take time, just warm them
			if [[ "${command}" == "stop" ]]; then
				out_notvalid "Trying to shutdown ${named}, this may take time..."
			fi
			rest_opt=( "${parse_opt[@]:2}" )
			"lxc-${command}" -n "${parse_opt[1]}" "${rest_opt[@]}" || return 1 #die " Aborting command : lxc-${command} -n ${parse_opt[1]} ${rest_opt[@]}"
		fi
	else
		die " lxc-${command} doesn't exist" "clean_install"
	fi
		
	return 0
}

# ${1} command to check
# return 0 on success,1 for fail
check_lxc_command(){
	local loop_ command ret
	command="${1}"

	for loop_ in $(ls /bin/|grep lxc-|sed 's:*::'); do
		if [[ lxc-"${command}" == "${loop_}" ]]; then
			return 0
		fi
	done
	
	return 1
		
	unset ret loop_ command
}

# ${1} path to the container
# ${2} name of the container
delete_container(){
	local _named _path stats
	
	_path="${1}"
	_named="${2}"
	
	check_dir "${LXC_CONF}/${_named}"
	if (( ! $? )); then
		stat=$(lxc_command_parse "info" "${_named}" "-s" | awk -F':' '{ print $2 }' | sed 's: ::g' )
		if [[ "${stat}" == "RUNNING" ]];then
			lxc_command_parse "stop" "${_named}" "-k"
		fi
		lxc_command_parse "destroy" "${_named}"
	fi
	
	rm -rf "${_path}/${_named}" || die " Impossible to remove ${TARGET}/${named}"
	
	unset _named _path
}
	
