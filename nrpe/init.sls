nrpe-packages:
  pkg.installed:
    - pkgs:
{% if grains.get('os_family', '') == 'RedHat' %}
      - nrpe
      - nagios-plugins-nrpe
      - nagios-plugins-disk
      - nagios-plugins-load
      - nagios-plugins-swap
      - nagios-plugins-uptime
      - nagios-plugins-ups
{% elif grains.get('os_family', '') == 'Debian' %}
      - nagios-nrpe-server
      - nagios-plugins-contrib
{% endif %}

nagios-server-ip:
  grains.present:
    - value: 10.200.99.16
    - require_in:
      - nrpe-config-file

nrpe-config-file:
  file.managed:
    - name: /etc/nagios/nrpe.cfg
    - source: salt://nrpe/files/nrpe.cfg.jinja
    - user: root
    - group: root
    - mode: 755
    - template: jinja
    - require_in:
        - pkg: nrpe

nrpe:
  service.running:
    - enable: true
    - watch:
      - nrpe-config-file
