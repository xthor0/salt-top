/swapfile:
  cmd.run:
    - name: |
        [ -f /swapfile ] || dd if=/dev/zero of=/swapfile bs=1M count=1024
        chmod 0600 /swapfile
        mkswap /swapfile
        swapon -a
    - unless:
      - test $(swapon --show | wc -l) -ge 2
  mount.swap:
    - persist: true

configure_swappiness:
  file.managed:
    - name: /etc/sysctl.d/10-swappiness.conf
    - contents:
      - vm.swappiness = 10

