{# set the latest version as a variable #}
{%- set vbox_latest = salt.cmd.run('curl -s http://download.virtualbox.org/virtualbox/LATEST-STABLE.TXT') %}
{%- set extpack = "Oracle_VM_VirtualBox_Extension_Pack-" ~ vbox_latest ~ ".vbox-extpack" %}

{# these ain't working #}
{%- set extpack_sha256_cmd = 'curl -s http://download.virtualbox.org/virtualbox/' ~ vbox_latest ~ '/SHA256SUMS | grep ' ~ extpack ~ ' | cut -d " " -f 1' %}
{%- set extpack_sha256 = salt.cmd.shell(extpack_sha256_cmd) %}

# debugging output to show in render
# vbox_latest --> {{ vbox_latest }}
# extpack --> {{ extpack }}
# extpack_sha256_cmd --> {{ extpack_sha256_cmd }}
# extpack_sha256 --> {{ extpack_sha256 }}

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
            - elfutils-libelf-devel

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

# set up virtualbox
run_vbox_config:
  cmd.run:
    - name: /sbin/vboxconfig
    - unless: lsmod | grep -q vboxdrv
    - require:
        - pkg: vbox6inst

# install extpack
download_virtualbox_extpack:
  cmd.run:
    - name: 'wget http://download.virtualbox.org/virtualbox/{{ vbox_latest }}/{{ extpack }} -O /srv/{{ extpack }}'
    - creates: /srv/{{ extpack }}

install_virtualbox_extpack:
  cmd.run:
    - name: VBoxManage extpack install --accept-license={{ extpack_sha256 }} /srv/{{ extpack }}
    - unless: /usr/bin/vboxmanage list extpacks | grep -q 'Extension Packs.*1'
    - require:
      - cmd: download_virtualbox_extpack

