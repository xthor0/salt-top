{% import_yaml "linuxos/defaults.yml" as defaults %}
{% set autoupdates = salt['pillar.get']('autoupdates', defaults, merge=True) %}

install-yum-cron:
    pkg.installed:
        - pkgs:
            - yum-cron
            - postfix
            - mailx

yum-cron-config-file:
    file.managed:
        - name: /etc/yum/yum-cron.conf
        - source: salt://linuxos/files/etc/yum/yum-cron.conf.jinja
        - template: jinja
        - user: root
        - group: root
        - mode: 644
        - require:
            - install-yum-cron

enable-mta-service:
    service.running:
        - name: postfix
        - enable: True
        - require:
            - install-yum-cron

enable-yum-cron-service:
    service.running:
        - name: yum-cron
        - enable: True
        - require:
            - install-yum-cron
            - yum-cron-config-file
