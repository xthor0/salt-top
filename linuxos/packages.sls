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
{% endif %}

# ubuntu stuff
{% if grains.get('os', '') == 'Ubuntu' %}
base-install-pkgs:
  pkg.installed:
    - pkgs:
      - screen
      - vim
{% endif %}

{% if grains.get('os', '') == 'Raspbian' %}
base-install-pkgs:
  pkg.installed:
    - pkgs:
      - screen
      - vim
{% endif %}
