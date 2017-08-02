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


clean_install(){
	
	out_action "Cleaning up"
	
	kill_process "haveged dirmngr gpg-agent"
	
	if [[ -n "${named}" ]]; then
		if [[ -d "${TARGET}/${named}" ]]; then
			mount_umount "${TARGET}/${named}/${WORKDIR}/rootfs" "umount"
			out_action "Would you like to destroy the container? [y|n]"
			reply_answer
			if (( ! $? )); then
				delete_container "${TARGET}" "${named}"
			fi
		fi
	fi
	if ip link show type bridge | grep ${BRIDGE_INTERFACE} &>/dev/null; then
		out_action "Would you like to destroy the bridge interface? [y|n]"
		reply_answer
		if (( ! $? )); then
			network_destroy
		fi
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
