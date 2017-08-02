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

network_destroy(){
	ip link set "${HOST_INTERFACE}" nomaster
	ip link set "${BRIDGE_INTERFACE}" down
	ip link delete "${BRIDGE_INTERFACE}" type bridge
	ip route add default via "${ROUTER_ADDR}"
}

network_create(){
	
	sysctl net.ipv4.ip_forward=1 &>/dev/null

	# check if the bridge exist
	# if not, create it
	ip link show type bridge | grep ${BRIDGE_INTERFACE} &>/dev/null
	if (( $? )); then
		ip link add name "${BRIDGE_INTERFACE}" address 00:16:3e:$(openssl rand -hex 3| sed 's/\(..\)/\1:/g; s/.$//') type bridge
		ip link set "${BRIDGE_INTERFACE}" up
		ip addr add "${BRIDGE_ADDR}" dev "${BRIDGE_INTERFACE}" 
		ip link set "${HOST_INTERFACE}" master "${BRIDGE_INTERFACE}"
	fi
	if [[ -f /etc/iptables/iptables.rules ]];then
		if ! $(grep -q "POSTROUTING -o ${HOST_INTERFACE} -j" /etc/iptables/iptables.rules 2>/dev/null); then
		
			iptables -t nat -A POSTROUTING -o "${HOST_INTERFACE}" -j MASQUERADE
			iptables-save > /etc/iptables/iptables.rules
			
			out_info "-t nat -A POSTROUTING -o "${HOST_INTERFACE}" -j MASQUERADE" 
			out_info "was added to your /etc/iptables/iptables.rules"
		fi
	fi
	
}
network_show(){
	ip link show
}
network_start(){
	ip link set "${HOST_INTERFACE}" master "${BRIDGE_INTERFACE}"
}

network_stop(){
	ip link set "${HOST_INTERFACE}" nomaster
}
