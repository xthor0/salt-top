keepalived.install:
  pkg.installed:
    - name: keepalived

psmisc.insall:
  pkg.installed:
    - name: psmisc

keepalived.conf:
  file.managed:
    - name: /etc/keepalived/keepalived.conf
    - source: salt://docker-ce-swarm/files/keepalived.master.jinja 
    - template: jinja
    - user: root
    - group: root
    - mode: 644

keepalived.service:
  service.running:
    - name: keepalived
    - enable: True
    - reload: True
    - require:
      - pkg: keepalived
    - watch:
      - file: /etc/keepalived/keepalived.conf

logrotate_conf:
  file.managed:
    - name: /etc/logrotate.conf
    - source: salt://docker-ce-swarm/files/logrotate_conf.jinja 
    - template: jinja
    - user: root
    - group: root
    - mode: 644
