/swapfile:
  cmd.run:
    - name: |
        [ -f /swapfile ] || dd if=/dev/zero of=/swapfile bs=1M count=1G
        chmod 0600 /swapfile
        mkswap /swapfile
        swapon -a
    - unless:
      - file /swapfile 2>&1 | grep -q "Linux/i386 swap"
  mount.swap:
    - persist: true

configure_swappiness:
  file.managed:
    - name: /etc/sysctl.conf
    - contents: |
      vm.swappiness = 10

