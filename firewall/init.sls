install-firewall-pkgs:
    pkg.installed:
        - pkgs:
            - bind-utils
            - iptraf-ng
            - tcpdump
            - dhcp-server
            - nftables

# enable ipv4 forwarding
net.ipv4.ip_forward:
    sysctl:
        - present
        - value: 1

# enable ipv6 all forwarding
net.ipv6.conf.all.forwarding:
    sysctl:
        - present
        - value: 1

net.ipv4.conf.default.rp_filter:
    sysctl:
        - present
        - value: 1

net.ipv4.conf.all.rp_filter:
    sysctl:
        - present
        - value: 1

net.ipv4.tcp_syncookies:
    sysctl:
        - present
        - value: 1

net.ipv4.icmp_echo_ignore_broadcasts:
    sysctl:
        - present
        - value: 1

net.ipv4.all.accept_source_route:
    sysctl:
        - present
        - value: 0


net.ipv4.tcp_syncookies:
    sysctl:
        - present
        - value: 1

net.ipv4.conf.all.accept_redirects:
    sysctl:
        - present
        - value: 0

net.ipv4.default.accept_redirects:
    sysctl:
        - present
        - value: 0

# DHCP server config
# I think I'm sticking with opnsense, I'll come back to this later