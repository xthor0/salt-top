root:
  user:
    - present
    - name: root
    - password: {{ salt['pillar.get']('shadow:root', {}) }}
    - enforce_password: True

add-xthor-user:
  user:
    - present
    - name: xthor
    - home: /home/xthor
    - shell: /bin/bash
    - groups:
{% if grains.get('os_family', '') == 'RedHat' %}
        - wheel
{% elif grains.get('os_family', '') == 'Debian' %}
        - adm
        - sudo
{% endif %}
    - password: {{ salt['pillar.get']('shadow:xthor', {}) }}
    - enforce_password: True

# some of the Arm images I use (raspbian, cubox Debian) come with default users I'd like to remove
remove-pi-user:
  user:
    - absent
    - name: pi
    - purge: True

remove-debian-user:
  user:
    - absent
    - name: debian
    - purge: True

# Amazon AMIs for CentOS come with a default user, too
remove-centos-user:
  user:
    - name: centos
    - absent
    - purge: True

xthor sshkeys:
  ssh_auth.manage:
    - user: xthor
    - enc: ecdsa-sha2-nistp256
    - config: /home/xthor/.ssh/authorized_keys
    - ssh_keys:
      - AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJ4OwD4MqSuGlqmJsMY6SCEY7Js4n1rS+altYALKSqN/XOlxEGXOkyrfrlgZ99jaj7IDYeVYbDZN4fMUlTYjWGA= caaro@secretive.caaro.local
      - AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBM0iPdemESmJ/Dgs/Xg1apaSVl8x27IP7FJcwRZa9BKQ6nNjFMhVVLNpvXfeAV8iq09k86/o0McXpR3T/Li2Kmk= hala@secretive.hala.local
    - require:
      - user: xthor

# add a managed file for .bashrc...
/home/xthor/.bashrc:
  file.managed:
    - source: salt://linuxos/files/home/xthor/.bashrc
    - template: jinja
    - user: xthor
    - group: xthor
    - mode: 644
    - require:
      - user: xthor

# nobody wants to see default messages about sudo
# ok, well, I don't :)
stfu-sudo-file:
  file.managed:
{% if grains.get('os_family', '') == 'RedHat' %}
    - name: /var/db/sudo/lectured/xthor
{% elif grains.get('os_family', '') == 'Rocky' %}
    - name: /var/db/sudo/lectured/xthor
{% elif grains.get('os_family', '') == 'Debian' %}
    - name: /home/xthor/.sudo_as_admin_successful
    - user: xthor
    - group: xthor
{% endif %}
    - contents: ''
    - contents_newline: False
    - require:
      - user: xthor

# if we're set up for tmux, drop in config required for those apps
{% if "tmux" in salt['grains.get']('roles', []) %}
/home/xthor/.tmux.conf:
  file.managed:
    - source: salt://linuxos/files/home/xthor/.tmux.conf
    - template: jinja
    - user: xthor
    - group: xthor
    - mode: 644
    - require:
      - user: xthor
{% endif %}

# if we're set up for screen, drop in .screenrc
{% if "screen" in salt['grains.get']('roles', []) %}
/home/xthor/.screenrc:
  file.managed:
    - source: salt://linuxos/files/home/xthor/.screenrc
    - user: xthor
    - group: xthor
    - mode: 644
    - require:
      - user: xthor
{% endif %}

/home/xthor/.bash_profile:
  file.managed:
    - source: salt://linuxos/files/home/xthor/.bash_profile
    - template: jinja
    - user: xthor
    - group: xthor
    - mode: 644
    - require:
      - user: xthor
