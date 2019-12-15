/etc/ssh/sshd_config:
  file.managed:
    - source: salt://linuxos/files/etc/ssh/sshd_config
    - user: root
    - group: root
    - mode: 640

sshd:
  service.running:
    - enable: True
    - require:
        - /etc/ssh/sshd_config
    - watch:
        - /etc/ssh/sshd_config
