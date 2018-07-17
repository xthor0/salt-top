root:
  user:
    - present
    - name: root
    - password: $6$Pu56_5Bn$a.336eHCjQbysWlHhlGW.5v.y71Su/KnlxJZAcgjj3VntsuC95f3Lli/hLEnccV5WajbUSj6mO4vSltKFc/ma0
    - enforce_password: True

add-xthor-user:
  user:
    - present
    - name: xthor
    - home: /home/xthor
    - shell: /bin/bash
    - groups:
{% if grains.get('os', '') == 'CentOS' %}
        - wheel
{% elif grains.get('os', '') == 'Ubuntu' %}
        - adm
        - sudo
{% endif %}
    - password: $6$qHxZmptuNTsdQB9O$OMldY1PUiACWc7JrgNU0jxfe27V0f1a.cT.DOEMuYQxMJwZv8nP9LpfWJrRsh2XflH7/pkzSZm2z9LL9kKkvB1
    - enforce_password: True

xthor sshkeys:
  ssh_auth.present:
    - user: xthor
    - source: salt://linuxos/files/home/xthor/.ssh/authorized_keys
    - config: /home/xthor/.ssh/authorized_keys
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
{% if grains.get('os', '') == 'CentOS' %}
    - name: /var/db/sudo/lectured/xthor
{% elif grains.get('os', '') == 'Ubuntu' %}
    - name: /home/xthor/.sudo_as_admin_successful
    - user: xthor
    - group: xthor
{% endif %}
    - require:
      - user: xthor
