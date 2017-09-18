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

# ${1} name of the container to manage.
# ${2} come from switch or not : 0 for not
# this is avoid to display the first menu
manage(){
	local ans ans_command ans_full parse_ans named _sw sw empty_named pick container_exist ret
	local -a container_list
	named="${1}"
	container_list=( $(lxc-ls -1 2>/dev/null) )
	
	
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
	
	_sw="${2}"
	
	# display or not the following line
	if [[ "${_sw}" == 0 ]] || [[ -z "${_sw}" ]]; then
		printf "\n" >&1
		printf " Type help to see option\n" >&1
		printf " Type quit for exit\n" >&1
	fi
	
	while true; do
		out_void
		
		read -p "Manage ${named} > " ans 
		
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
			network)
				manage_network
				;;
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
						eval lxc-"${ans_command}" "${ans_full[@]}"
						(( ! $? )) || out_info "Warning : the command failed, see above"
					else
						# eval here can be dangerous, need to find a turn around
						eval lxc-"${ans_command}" -n "${named}" "${ans_full[@]}"
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

manage_help(){
	
	printf "%-15s %-15s\n" "attach" "start a process inside a running container" >&1
	printf "%-15s %-15s\n" "autostart" "start/stop/kill auto-started containers" >&1
	printf "%-15s %-15s\n" "cgroup" "start a process inside a running container" >&1
	printf "%-15s %-15s\n" "checkconfig" "start a process inside a running container" >&1
	printf "%-15s %-15s\n" "checkpoint" "checkpoint a container" >&1
	printf "%-15s %-15s\n" "config" "query LXC system configuration" >&1
	printf "%-15s %-15s\n" "console" "launch a console for the specified container" >&1
	printf "%-15s %-15s\n" "copy" "copy an existing container" >&1
	printf "%-15s %-15s\n" "create" "creates a container" >&1
	printf "%-15s %-15s\n" "destroy" "destroy a container" >&1
	printf "%-15s %-15s\n" "device" "manage devices of running containers" >&1
	printf "%-15s %-15s\n" "execute" "run an application inside a container" >&1
	printf "%-15s %-15s\n" "freeze" "freeze all the container's processes" >&1
	printf "%-15s %-15s\n" "info" "query information about a container" >&1
	printf "%-15s %-15s\n" "ls" "list the containers existing on the system" >&1
	printf "%-15s %-15s\n" "monitor" "monitor the container state" >&1
	printf "%-15s %-15s\n" "network" "create/start/stop/destroy the bridge" >&1
	printf "%-15s %-15s\n" "quit" "exit from this menu" >&1
	printf "%-15s %-15s\n" "snapshot" "snapshot an existing container" >&1
	printf "%-15s %-15s\n" "start" "start a container" >&1
	printf "%-15s %-15s\n" "stop" "stop a container" >&1
	printf "%-15s %-15s\n" "switch" "manage the named container" >&1
	printf "%-15s %-15s\n" "top" "monitor container statistics" >&1
	printf "%-15s %-15s\n" "unfreeze" "thaw all the container's processes" >&1
	printf "%-15s %-15s\n" "unshare" "run a task in a new set of namespaces" >&1
	printf "%-15s %-15s\n" "usernsexec" "run a task as root in a new user namespace" >&1
	printf "%-15s %-15s\n" "wait" "wait for a specific container state" >&1
	printf "%-15s %-15s\n" "" >&1
	printf "%-15s %-15s\n" "" >&1
	printf "%-15s %-15s\n" "If you want more information about a command,"
	printf "%-15s %-15s\n" "type e.g start --help"
	
}

manage_network(){
	local ans
	
	printf "\n" >&1
	printf " Type help to see option to control the bridge\n" >&1
	printf " Type quit for exit\n" >&1
	printf "\n" >&1
	
	while true; do
		read -e -p "Manage network > " ans
		case "${ans}" in
			create)
				network_create
				;;
			start)
				network_start
				;;
			stop)
				network_stop
				;;
			destroy)
				network_destroy
				;;
			show)
				network_show
				;;
			help)
				manage_network_help
				;;
			quit)
				break
				;;
			*)
				printf " Incorrect command, try help\n" >&1
				;;
		esac
	done
}

manage_network_help(){
	printf "%-15s %-15s\n" "create" "create the bridge and start it" >&1
	printf "%-15s %-15s\n" "destroy" "destroy the bridge" >&1
	printf "%-15s %-15s\n" "start" "active the bridge" >&1
	printf "%-15s %-15s\n" "stop" "disactive the bridge" >&1
	printf "%-15s %-15s\n" "show" "show network" >&1
}
