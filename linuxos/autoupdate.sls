{% if grains.get('os_family', '') == 'RedHat' %}
{% if grains.get('osmajorrelease', '') == 7 %}
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
{% elif grains.get('osmajorrelease', '') == 8 %}
{# https://fedoraproject.org/wiki/AutoUpdates - maybe? dnf-automatic? #}
{% endif %}
{% elif grains.get('os_family', '') == 'Debian' %}
unattended-upgrades:
    pkg.installed

/etc/apt/apt.conf.d/20auto-upgrades:
    file.managed:
        - source: salt://linuxos/files/20auto-upgrades
        - user: root
        - group: root
        - mode: 0644
        - require:
            - pkg: unattended-upgrades

/etc/apt/apt.conf.d/50unattended-upgrades:
    file.managed:
        - source: salt://linuxos/files/50unattended-upgrades.jinja
        - template: jinja
        - user: root
        - group: root
        - mode: 0644
        - require:
            - pkg: unattended-upgrades
{% endif %}
