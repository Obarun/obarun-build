#!@BINDIR@/bash
# Copyright (c) 2015-2018 Eric Vidal <eric@obarun.org>
# All rights reserved.
# 
# This file is part of Obarun. It is subject to the license terms in
# the LICENSE file found in the top-level directory of this
# distribution and at https://github.com/Obarun/obarun-build/LICENSE
# This file may not be copied, modified, propagated, or distributed
# except according to the terms contained in the LICENSE file.

# ${1} name of the container to manage.
# ${2} come from switch or not : 0 for not
# this is avoid to display the first menu
manage(){
	local ans ans_command ans_full parse_ans named _sw sw empty_named pick container_exist ret
	local -a container_list
	named="${1}"
	container_list=( $(lxc-ls -P "${WORKLXC}" -1 2>/dev/null) )
	
	
	check_existing_container(){
			select pick in "${container_list[@]}"; do
				case "$pick" in
					*)if check_elements "$pick" "${container_list[@]}"; then
						named="${pick}"
						break
					else 
						out_notvalid "Invalid number, retry :"
					fi
				esac
			done
	}
	
	if [[ -z "${named}" ]]; then
		out_info "name must not be empty"
		if [[ -n "${container_list[@]}" ]]; then
			out_info "please pick one on the following list"
			check_existing_container
		else
			die
		fi
	else
		for container_exist in "${container_list[@]}"; do
			if [[ "${named}" == "${container_exist}" ]]; then
				ret=0
				break
			else
				ret=1
			fi
		done
		if (( $ret )); then
			out_info "${named} doesn't exist"
			out_info "please pick one on the following list"
			check_existing_container
		fi
		unset ret
	fi
	
	# check if network is started
	#if [[ ! -f /run/lxc/network_up ]]; then
	#	out_notvalid "The Network bridge is not created"
	#	out_notvalid "As root you can create it with this command:"
	#	out_notvalid "/usr/lib/lxc/lxc-net start"
	#fi
	# create bridge if it not exist yet
	if [[ ! -f /run/lxc/network_up ]]; then
		out_notvalid "The Network bridge is not running"
		out_notvalid "Starting it..."
		/usr/lib/lxc/lxc-net start
	fi
	
	_sw="${2}"
	
	# display or not the following line
	if [[ "${_sw}" == 0 ]] || [[ -z "${_sw}" ]]; then
		printf "\n" >&1
		printf " Type help to see option\n" >&1
		printf " Type quit for exit\n" >&1
	fi
	
	while true; do
		out_void
		
		read -ep "Manage ${named} > " ans 
		
		parse_ans=( ${ans[@]} )
		ans_command=( ${parse_ans[0]} )
		ans_full=( ${parse_ans[@]:1} )
		
		check_var(){
			echo ans="${ans[@]}"
			echo parse_ans="${parse_ans[@]}"
			echo ans_command="${ans_command}"
			echo ans_full="${ans_full[@]}"
		}
		#check_var
		
		case "${ans_command}" in
			switch)
				named="${parse_ans[1]}"
				sw=1
				break
				;;
			help)
				manage_help
				;;
			quit) 
				exit
				;;
			*)
				# check if lxc-${command} exist
				check_lxc_command "${ans_command}"
							
				if (( $? )); then
					printf " Incorrect command, try help\n" >&1
				else
					if [[ "${ans_command}" == @(ls|autostart|checkconfig|top|usernsexec) ]]; then
						# eval here can be dangerous, need to find a turn around
						eval lxc-"${ans_command}" -P "${WORKLXC}" "${ans_full[@]}"
						(( ! $? )) || out_info "Warning : the command failed, see above"
					else
						# eval here can be dangerous, need to find a turn around
						eval lxc-"${ans_command}" -n "${named}" -P "${WORKLXC}" "${ans_full[@]}"
						# don't stop the script if the command fail, but warm it
						(( ! $? )) || out_info "Warning : the command failed, see above"
					fi
				fi
		esac
	done
	if (( $sw )); then
		manage "${named}" "1"
	fi
}
