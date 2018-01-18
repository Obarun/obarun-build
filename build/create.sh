#!@BINDIR@/bash
# Copyright (c) 2015-2018 Eric Vidal <eric@obarun.org>
# All rights reserved.
# 
# This file is part of Obarun. It is subject to the license terms in
# the LICENSE file found in the top-level directory of this
# distribution and at https://github.com/Obarun/obarun-build/LICENSE
# This file may not be copied, modified, propagated, or distributed
# except according to the terms contained in the LICENSE file.


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
	lxc_command_parse "create" "${named}" -t "${TARGET}/${named}/${WORKCONF}/create" "${_args[@]}" || die " Impossible to create the container" "clean_install"
	
}
