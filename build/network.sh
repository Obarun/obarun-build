#!@BINDIR@/bash
# Copyright (c) 2015-2017 Eric Vidal <eric@obarun.org>
# All rights reserved.
# 
# This file is part of Obarun. It is subject to the license terms in
# the LICENSE file found in the top-level directory of this
# distribution and at https://github.com/Obarun/obarun-build/LICENSE
# This file may not be copied, modified, propagated, or distributed
# except according to the terms contained in the LICENSE file.

network_destroy(){
	ip link set "${BRIDGE_INTERFACE}" promisc off down
	ip link set "${HOST_INTERFACE}" nomaster
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
		ip link set "${BRIDGE_INTERFACE}" promisc on up
        ip addr flush dev "${BRIDGE_INTERFACE}" scope host &>/dev/null
        ip addr flush dev "${BRIDGE_INTERFACE}" scope site &>/dev/null
        ip addr flush dev "${BRIDGE_INTERFACE}" scope global &>/dev/null
        ip link set dev "${HOST_INTERFACE}" master "$BRIDGE_INTERFACE"
        bridge link set dev "${BRIDGE_INTERFACE}" state 3
		#ip link set "${BRIDGE_INTERFACE}" up
		#ip addr add "${BRIDGE_ADDR}" dev "${BRIDGE_INTERFACE}" 
		#ip link set "${HOST_INTERFACE}" master "${BRIDGE_INTERFACE}"
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
	ip link set "${BRIDGE_INTERFACE}" promisc off down
	ip link set "${HOST_INTERFACE}" nomaster
}
