#!/bin/bash
## what's the default interface on this system?
netdev=$(ip route | grep ^default | awk '{ print $5 }')

# sanity check - we should be running this on a libvirt host
rpm -qa | grep -q libvirt
if [ $? -ne 0 ]; then
    echo "Error: This machine doesn't have libvirt installed. Exiting."
    exit 255
fi

current_ip=$(ip addr show ${netdev} | grep -w inet | awk '{ print $2 }')
gateway=$(ip route | grep ^default | awk '{ print $3 }')
dns=$(grep nameserver /etc/resolv.conf | awk '{ print $2 }')

## set up the primary br0 for default vlan
nmcli c delete $(nmcli -t -f UUID con)
nmcli c add type bridge ifname br0 autoconnect yes con-name br0 stp off
nmcli c modify br0 ipv4.addresses ${current_ip} ipv4.gateway ${gateway} ipv4.dns ${dns} ipv4.method manual
nmcli c add type bridge-slave autoconnect yes con-name ${netdev} ifname ${netdev} master br0
nmcli con up ${netdev}

sleep 1

# don't know why I had to do this AGAIN, but...
# nmcli c mod br0 ipv4.method manual
nmcli c up br0

# individual vlan setup
for vlan in 50 51 52 53 54 55; do
nmcli c add type bridge ifname br-vlan${vlan} autoconnect yes con-name br-vlan${vlan} stp off
nmcli c modify br-vlan${vlan} ipv4.method disabled ipv6.method ignore
nmcli con up br-vlan${vlan}
nmcli c add type vlan autoconnect yes con-name vlan${vlan} dev ${netdev} id ${vlan} master br-vlan${vlan} slave-type bridge
done

