# set some variables that vary by OS type
{% if grains['os_family'] in [ 'RedHat', 'Rocky' ] %}
{% set nrpe_service = "nrpe" %}
{% set plugin_dir = "/usr/lib64/nagios/plugins" %}
{% elif grains.get('os_family', '') == 'Debian' %}
{% set nrpe_service = "nagios-nrpe-server" %}
{% set plugin_dir = "/usr/lib/nagios/plugins" %}
{% endif %}

nrpe-packages:
  pkg.installed:
    - pkgs:
{% if grains['os_family'] in [ 'RedHat', 'Rocky' ] %}
      - nrpe
      - nagios-plugins-nrpe
      - nagios-plugins-disk
      - nagios-plugins-load
      - nagios-plugins-swap
      - nagios-plugins-uptime
      - nagios-plugins-ups
      - nagios-plugins-procs
      - nagios-plugins-users
      - perl
{% elif grains.get('os_family', '') == 'Debian' %}
      - nagios-nrpe-server
      - nagios-plugins-contrib
      - monitoring-plugins-basic
{% endif %}

nrpe-config-file:
  file.managed:
    - name: /etc/nagios/nrpe.cfg
    - source: salt://nrpe/files/nrpe.cfg.jinja
    - user: root
    - group: root
    - mode: 755
    - template: jinja
    - require:
        - pkg: nrpe-packages

check_mem_plugin:
  file.managed:
    - name: {{ plugin_dir }}/check_mem.pl
    - source: salt://icinga2/files/check_mem.pl
    - user: root
    - group: root
    - mode: 755

# we need the name of the nrpe service - which varies by OS type
{{ nrpe_service }}:
  service.running:
    - enable: True
    - watch:
      - nrpe-config-file
