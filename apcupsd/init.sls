install-apcupsd-pkgs:
    pkg.installed:
        - pkgs:
            - apcupsd
            - curl

apccontrol-file:
    file.managed:
        - name: /etc/apcupsd/apccontrol
        - source: salt://apcupsd/files/apccontrol.jinja
        - user: root
        - group: root
        - mode: 750
        - template: jinja
        - require:
            - install-apcupsd-pkgs

apcupsd-conf-file:
    file.managed:
        - name: /etc/apcupsd/apcupsd.conf
        - source: salt://apcupsd/files/apcupsd_conf.jinja
        - user: root
        - group: root
        - mode: 750
        - template: jinja
        - require:
            - install-apcupsd-pkgs

onbattery-file:
    file.managed:
        - name: /etc/apcupsd/onbattery
        - source: salt://apcupsd/files/onbattery.jinja
        - user: root
        - group: root
        - mode: 750
        - template: jinja
        - require:
            - install-apcupsd-pkgs

offbattery-file:
    file.managed:
        - name: /etc/apcupsd/offbattery
        - source: salt://apcupsd/files/offbattery.jinja
        - user: root
        - group: root
        - mode: 750
        - template: jinja
        - require:
            - install-apcupsd-pkgs

apcupsd-service:
    service.running:
        - name: apcupsd
        - enable: True
        - require:
            - install-apcupsd-pkgs
            - apccontrol-file
            - apcupsd-conf-file
            - onbattery-file
            - offbattery-file
            - offbattery-file
        - watch:
            - apcupsd-conf-file
