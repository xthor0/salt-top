{% import_yaml "linuxos/defaults.yml" as defaults %}
{% set autoupdates = salt['pillar.get']('autoupdates', defaults, merge=True) %}

unattended-upgrades-pkgs:
    pkg.installed:
        - pkgs:
            - unattended-upgrades

/etc/apt/apt.conf.d/20auto-upgrades:
    file.managed:
        - source: salt://linuxos/files/20auto-upgrades
        - user: root
        - group: root
        - mode: 0644
        - require:
            - pkg: unattended-upgrades-pkgs

/etc/apt/apt.conf.d/50unattended-upgrades:
    file.managed:
        - source: salt://linuxos/files/50unattended-upgrades.jinja
        - template: jinja
        - user: root
        - group: root
        - mode: 0644
        - context:
            autoupdates: {{ autoupdates }}
        - require:
            - pkg: unattended-upgrades-pkgs

unattended-upgrades-service:
  service.running:
    - name: unattended-upgrades
    - enable: true
    - require:
        - pkg: unattended-upgrades-pkgs
    - watch:
        - file: /etc/apt/apt.conf.d/20auto-upgrades
        - file: /etc/apt/apt.conf.d/50unattended-upgrades

create-timerd-dirs:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - names:
        - /etc/systemd/system/apt-daily.timer.d
        - /etc/systemd/system/apt-daily-upgrade.timer.d

restart-systemd-daemon:
    module.run: 
        - name: service.systemctl_reload
        - onchanges:
            - file: /etc/systemd/system/apt-daily.timer.d/override.conf
            - file: /etc/systemd/system/apt-daily-upgrade.timer.d/override.conf

restart-apt-daily-timer:
    service.running:
        - name: apt-daily.timer
        - restart: True
        - watch:
            - file: /etc/systemd/system/apt-daily.timer.d/override.conf
        - require:
            - file: /etc/systemd/system/apt-daily.timer.d/override.conf

restart-apt-daily-upgrade-timer:
    service.running:
        - name: apt-daily-upgrade.timer
        - enable: True
        - restart: True
        - watch:
            - file: /etc/systemd/system/apt-daily-upgrade.timer.d/override.conf
        - require:
            - file: /etc/systemd/system/apt-daily-upgrade.timer.d/override.conf

/etc/systemd/system/apt-daily-upgrade.timer.d/override.conf:
    file.managed:
        - source: salt://linuxos/files/apt-daily-upgrade-override.conf.jinja
        - template: jinja
        - user: root
        - group: root
        - mode: 644
        - context:
            autoupdates: {{ autoupdates }}
        - require:
            - create-timerd-dirs

/etc/systemd/system/apt-daily.timer.d/override.conf:
    file.managed:
        - source: salt://linuxos/files/apt-daily-timer-override.conf.jinja
        - template: jinja
        - user: root
        - group: root
        - mode: 644
        - context:
            autoupdates: {{ autoupdates }}
        - require:
            - create-timerd-dirs
