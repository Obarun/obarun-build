#!@BINDIR@/bash
# Copyright (c) 2015-2017 Eric Vidal <eric@obarun.org>
# All rights reserved.
# 
# This file is part of Obarun. It is subject to the license terms in
# the LICENSE file found in the top-level directory of this
# distribution and at https://github.com/Obarun/obarun-build/LICENSE
# This file may not be copied, modified, propagated, or distributed
# except according to the terms contained in the LICENSE file.

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


manage_network_help(){
	printf "%-15s %-15s\n" "create" "create the bridge and start it" >&1
	printf "%-15s %-15s\n" "destroy" "destroy the bridge" >&1
	printf "%-15s %-15s\n" "start" "active the bridge" >&1
	printf "%-15s %-15s\n" "stop" "disactive the bridge" >&1
	printf "%-15s %-15s\n" "show" "show network" >&1
}
