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

nrpe-config-file:
  file.managed:
    - name: /etc/nagios/nrpe.cfg
    - source: salt://nrpe/files/nrpe.cfg.jinja
    - user: root
    - group: root
    - mode: 755
    - template: jinja
    - require:
        - pkg: nrpe
    - require:
        - nagios-server-ip

# we need the name of the nrpe service - which varies by OS type
{% if grains.get('os_family', '') == 'RedHat' %}
{% set nrpe_service = "nrpe" %}
{% elif grains.get('os_family', '') == 'Debian' %}
{% set nrpe_service = "nagios-nrpe-server" %}
{% endif %}

{{ nrpe_service }}:
  service.running:
    - enable: True
    - watch:
      - nrpe-config-file
