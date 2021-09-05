# we need some repos configured
include:
  - mariadb
  - .repo
  - .database

{% if grains['os_family'] == 'Debian' %}
  {% set apache_package = 'apache2' %}
{% elif grains['os_family'] == 'Rocky' %}
  {% set apache_package = 'httpd' %}
{% elif grains['os_family'] == 'RedHat' %}
  {% set apache_package = 'httpd' %}
{% endif %}

# ensure python mysql dependency is present
python36-mysql:
  pkg.installed:
    - require_in:
      - service: mariadb

# install all the other goodies
install-icinga2-pkgs:
  pkg.installed:
    - pkgs:
      - icinga2
      - icinga2-ido-mysql
      - icingaweb2
      - icingacli
      - {{ apache_package }}
      - mod_ssl
      - nagios-plugins-http
      - nagios-plugins-ping
      - nagios-plugins-fping
      - nagios-plugins-load
      - nagios-plugins-disk
      - nagios-plugins-users
      - nagios-plugins-procs
      - nagios-plugins-swap
      - nagios-plugins-ssh
      - nagios-plugins-nrpe
      - mailx
      - postfix

# install selinux package for RHEL OS and families
# this doesn't work for Rocky. Need an 'and'?
{% if grains.get('os', '') == 'CentOS' %}
install-icingaweb2-selinux:
  pkg.installed:
    - pkgs:
      - icingaweb2-selinux

# fix date.timezone in php.ini
/etc/opt/rh/rh-php71/php.ini:
  file.replace:
    - pattern: '^;date.timezone =$'
    - repl: 'date.timezone = "America/Denver"'
    - require:
      - pkg: install-icinga2-pkgs

# start php-fpm service
rh-php71-php-fpm.service:
  service.running:
    - enable: True
    - require:
      - pkg: install-icinga2-pkgs
    - watch:
      - file: /etc/opt/rh/rh-php71/php.ini

# if we want the local Icingaweb2 instance to be able to control itself, this boolean is required
httpd_can_network_connect:
  selinux.boolean:
    - value: True
    - persist: True
{% endif %}

# turn on MTA
postfix.service:
  service.running:
    - enable: True

# generate self-signed SSL certificate
{% if salt['pillar.get']('ssl:C') %}
generate-self-signed-ssl:
  cmd.run:
    - name: openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj "/C={{ salt['pillar.get']('ssl:C') }}/ST={{ salt['pillar.get']('ssl:ST') }}/L={{ salt['pillar.get']('ssl:L') }}/O={{ salt['pillar.get']('ssl:O') }}/CN={{ salt['grains.get']('id') }}" -keyout /etc/pki/tls/private/localhost.key -out /etc/pki/tls/certs/localhost.crt
    - unless: openssl x509 -noout -subject -in /etc/pki/tls/certs/localhost.crt | grep -q {{ salt['grains.get']('id') }}
{% endif %}

# manage in a redirect for default website
http-redirect-index:
  file.managed:
    - name: /var/www/html/index.html
    - source: salt://icinga2/files/index.html
    - template: jinja

# start httpd
httpd.service:
  service.running:
    - enable: True
    - require:
      - pkg: install-icinga2-pkgs
    {% if salt['pillar.get']('ssl:C') %}
    - watch:
      - cmd: generate-self-signed-ssl
    {% endif %}

# start icinga2 service
icinga2.service:
  service.running:
    - enable: True
    - require:
      - pkg: install-icinga2-pkgs
    - watch:
      - cmd: enable-icinga2-feature-idomysql
      - cmd: enable-icinga2-feature-command

# todo: when I'm not sick of this, should probably come from
# pillar and foreach feature in pillar :)
# enable ido-mysql
enable-icinga2-feature-idomysql:
  cmd.run:
    - name: icinga2 feature enable ido-mysql
    - unless: test -f /etc/icinga2/features-enabled/ido-mysql.conf
    - require:
      - file: ido-mysql-conf-file
    - watch:
      - file: ido-mysql-conf-file

# enable command feature
enable-icinga2-feature-command:
  cmd.run:
    - name: icinga2 feature enable command
    - unless: test -f /etc/icinga2/features-enabled/command.conf

icinga2-api-setup:
  cmd.run:
    - name: icinga2 api setup
    - unless: test -f /etc/icinga2/features-enabled/api.conf

icinga2-create-setup-token:
  cmd.run:
    - name: icingacli setup token create
    - unless: test -f /var/lib/icinga2/icinga2.state

# manage in all the files we need
/etc/icinga2/conf.d/commands.conf:
  file.managed:
    - source: salt://icinga2/files/commands.conf
    - user: icinga
    - group: icinga
    - mode: 640
    - after:
      - install-icinga2-pkgs
    - require_in:
      - icinga2.service
    - watch_in:
      - icinga2.service

/etc/icinga2/conf.d/notifications.conf:
  file.managed:
    - source: salt://icinga2/files/notifications.conf
    - user: icinga
    - group: icinga
    - mode: 640
    - after:
      - install-icinga2-pkgs
    - require_in:
      - icinga2.service
    - watch_in:
      - icinga2.service

/etc/icinga2/conf.d/templates.conf:
  file.managed:
    - source: salt://icinga2/files/templates.conf
    - user: icinga
    - group: icinga
    - mode: 640
    - after:
      - install-icinga2-pkgs
    - require_in:
      - icinga2.service
    - watch_in:
      - icinga2.service

/etc/icinga2/conf.d/users.conf:
  file.managed:
    - source: salt://icinga2/files/users.conf.jinja
    - user: icinga
    - group: icinga
    - template: jinja
    - mode: 640
    - after:
      - install-icinga2-pkgs
    - require_in:
      - icinga2.service
    - watch_in:
      - icinga2.service

/etc/icinga2/conf.d/hosts.conf:
  file.managed:
    - source: salt://icinga2/files/hosts.conf.jinja
    - user: icinga
    - group: icinga
    - template: jinja
    - mode: 640
    - after:
      - install-icinga2-pkgs
    - require_in:
      - icinga2.service
    - watch_in:
      - icinga2.service

/etc/icinga2/conf.d/api-users.conf:
  file.managed:
    - source: salt://icinga2/files/api-users.conf.jinja
    - user: icinga
    - group: icinga
    - template: jinja
    - mode: 640
    - after:
      - install-icinga2-pkgs
    - require_in:
      - icinga2.service
    - watch_in:
      - icinga2.service

/etc/icinga2/conf.d/services.conf:
  file.managed:
    - source: salt://icinga2/files/services.conf
    - user: icinga
    - group: icinga
    - template: jinja
    - mode: 640
    - after:
      - install-icinga2-pkgs
    - require_in:
      - icinga2.service
    - watch_in:
      - icinga2.service

/etc/icingaweb2/modules/monitoring/commandtransports.ini:
  file.managed:
    - source: salt://icinga2/files/commandtransports.ini.jinja
    - user: apache
    - group: icingaweb2
    - template: jinja
    - mode: 660
    - after:
      - install-icinga2-pkgs
      - icinga2-api-setup
    - require_in:
      - icinga2.service
    - watch_in:
      - icinga2.service

/etc/icinga2/scripts/notify_by_pushover.sh:
  file.managed:
    - source: salt://icinga2/files/notify_by_pushover.sh
    - user: icinga
    - group: icinga
    - mode: 750
