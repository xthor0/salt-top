{% import_yaml "linuxos/defaults.yml" as defaults %}
{% set autoupdates = salt['pillar.get']('autoupdates', defaults, merge=True) %}

dnf-automatic:
    pkg.installed

/etc/systemd/system/dnf-automatic-install.timer.d/override.conf:
    file.managed:
        - source: salt://linuxos/files/dnf-automatic-install-timer-override.conf.jinja
        - template: jinja
        - user: root
        - group: root
        - mode: 0644
        - context:
            autoupdates: {{ autoupdates }}
        - require:
            - pkg: dnf-automatic
            - create-dnf-automatic-install-timer-dir

create-dnf-automatic-install-timer-dir:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - names:
        - /etc/systemd/system/dnf-automatic-install.timer.d

restart-systemd-daemon:
    module.run: 
        - name: service.systemctl_reload
        - onchanges:
            - file: /etc/systemd/system/dnf-automatic-install.timer.d/override.conf

restart-dnf-automatic-install-timer:
    service.running:
        - name: dnf-automatic-install.timer
        - enable: True
        - restart: True
        - watch:
            - file: /etc/systemd/system/dnf-automatic-install.timer.d/override.conf
        - require:
            - file: /etc/systemd/system/dnf-automatic-install.timer.d/override.conf