# centos stuff
{% if grains.get('os', '') == 'CentOS' %}
base-install-pkgs:
  pkg.installed:
    - pkgs:
      - bind-utils
      - dmidecode
      - epel-release
      - lsof
      - nano
      - net-tools
      - rsync
      - screen
      - sysstat
      - vim-enhanced
      - wget
      - yum-plugin-versionlock
      - rpm-cron
      - policycoreutils-python
      - man-db
      - nmap-ncat
      - procps-ng
      - util-linux
      - bash-completion

epel-install-pkgs:
  pkg.installed:
    - fromrepo: epel
    - pkgs:
      - bash-completion-extras
      - ncdu
      - htop
{% endif %}

# debian family OS class
{% if grains.get('os_family', '') == 'Debian' %}
base-install-pkgs:
  pkg.installed:
    - pkgs:
      - screen
      - vim
      - htop
      - bash-completion
{% endif %}