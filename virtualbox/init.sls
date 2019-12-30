# we need to manage in a repo
virtualbox-yum-repo:
    pkgrepo.managed:
        - humanname: VirtualBox
        - baseurl: http://download.virtualbox.org/virtualbox/rpm/el/$releasever/$basearch
        - gpgcheck: 1
        - repo_gpgcheck: 1
        - gpgkey: https://www.virtualbox.org/download/oracle_vbox.asc

# install the right packages
virtualbox-centos-deps:
    pkg.installed:
        - pkgs:
            - kernel-devel
            - kernel-headers
            - gcc
            - make
            - perl
            - git
            - mtools
            - qemu-img

# now, install VirtualBox...
vbox6inst:
    pkg.installed:
        - name: VirtualBox-6.1
        - require:
            - virtualbox-yum-repo

# install vboxmanage bash completion
# get updates from https://raw.githubusercontent.com/gryf/vboxmanage-bash-completion/master/VBoxManage
/etc/bash_completion.d/VBoxManage:
  file.managed:
    - source: salt://virtualbox/files/VBoxManage
    - user: root
    - group: root
    - mode: 664

# install extpack - to do
