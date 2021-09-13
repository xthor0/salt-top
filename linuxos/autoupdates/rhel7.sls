{% import_yaml "linuxos/defaults.yml" as defaults %}
{% set autoupdates = salt['pillar.get']('autoupdates', defaults, merge=True) %}

install-yum-cron:
    pkg.installed:
        - name: yum-cron

yum-cron-config-file:
    file.managed:
        - name: /etc/yum/yum-cron.conf
        - source: salt://linuxos/files/etc/yum/yum-cron.conf.jinja
        - template: jinja
        - user: root
        - group: root
        - mode: 644
        - context:
            random_sleep: {{ autoupdates.random_sleep }}
        - require:
            - install-yum-cron

/etc/cron.daily/0yum-daily.cron:
    file.managed:
        - contents: |
            # This file intentionally disabled by SaltStack. Local modifications will be lost!

/etc/cron.d/yum-cron:
    file.managed:
        - contents: |
            # This file intentionally disabled by SaltStack. Local modifications will be lost!
            {{ autoupdates.update_time_crontab }} root test -f /var/lock/subsys/yum-cron && exec /usr/sbin/yum-cron

/etc/cron.d/yum-reboot:
    file.managed:
        - contents: |
            # This file intentionally disabled by SaltStack. Local modifications will be lost!
            {{ autoupdates.reboot_time_crontab }} root /usr/bin/needs-restarting -r 2>&1 logger -t yum-reboot; if test ${PIPESTATUS[0]} -eq 1; then logger -t yum-reboot rebooting now; reboot; fi

enable-yum-cron-service:
    service.running:
        - name: yum-cron
        - enable: True
        - require:
            - install-yum-cron
            - yum-cron-config-file
        - watch:
            - file: /etc/yum/yum-cron.conf