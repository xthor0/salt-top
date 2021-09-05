# we need some repos configured
include:
  - mariadb
  - .repo
  - .database

# TODO: come back and fix this for CentOS/Rocky. It won't work right now.
# Gotta build a map or something, to install the right stuff. Because the package
# names are COMPLETELY different for CentOS vs Debian.

{% if grains['os_family'] == 'Debian' %}
  {% set apache_package = 'apache2' %}
  {% set nagios_plugins_package = 'apache2' %}
{% elif grains['os_family'] == 'Rocky' %}
  {% set apache_package = 'httpd' %}
{% elif grains['os_family'] == 'RedHat' %}
  {% set apache_package = 'httpd' %}
{% endif %}

# install all the other goodies
install-icinga2-pkgs:
  pkg.installed:
    - pkgs:
      - icinga2
      - icinga2-ido-mysql
      - icingaweb2
      - icingacli
      - apache2
      - monitoring-plugins
      - vim-icinga2
      - vim-addon-manager
      - bsd-mailx
      - postfix

# enable Vim addon
{% if grains['os_family'] == 'Debian' %}
{# vim-addon-manager -w install icinga2 #}
{% endif %}

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
# TODO: fix for CentOS, too
# Debian generates a snakeoil cert, so mebbe we don't need this.
{% if salt['pillar.get']('ssl:C') %}
generate-self-signed-ssl:
  cmd.run:
    - name: openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj "/C={{ salt['pillar.get']('ssl:C') }}/ST={{ salt['pillar.get']('ssl:ST') }}/L={{ salt['pillar.get']('ssl:L') }}/O={{ salt['pillar.get']('ssl:O') }}/CN={{ salt['grains.get']('id') }}" -keyout /etc/ssl/private/localhost.key -out /etc/ssl/certs/localhost.crt
    - unless: openssl x509 -noout -subject -in /etc/ssl/certs/localhost.crt | grep -q {{ salt['grains.get']('id') }}
{% endif %}

# manage in a redirect for default website
http-redirect-index:
  file.managed:
    - name: /var/www/html/index.html
    - source: salt://icinga2/files/index.html
    - template: jinja

# start web service
# TODO: fix for CentOS?
apache2.service:
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
    - user: nagios
    - group: nagios
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
    - user: nagios
    - group: nagios
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
    - user: nagios
    - group: nagios
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
    - user: nagios
    - group: nagios
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
    - user: nagios
    - group: nagios
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
    - user: nagios
    - group: nagios
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
    - user: nagios
    - group: nagios
    - template: jinja
    - mode: 640
    - after:
      - install-icinga2-pkgs
    - require_in:
      - icinga2.service
    - watch_in:
      - icinga2.service

/etc/icingaweb2/modules/monitoring:
  file.directory:
    - user: www-data
    - group: icingaweb2
    - dir_mode: 770
    - before:
      - /etc/icingaweb2/modules/monitoring/commandtransports.ini

/etc/icingaweb2/modules/monitoring/commandtransports.ini:
  file.managed:
    - source: salt://icinga2/files/commandtransports.ini.jinja
    - user: www-data
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
    - user: nagios
    - group: nagios
    - mode: 750

Enable apache ssl module:
  apache_module.enabled:
    - name: ssl
    - watch_in:
      - apache2.service

Enable apache default-ssl site:
  apache_site.enabled:
    - name: default-ssl
    - watch_in:
      - apache2.service

# Configure automatically Icinga web, avoiding the use of the php wizard
icinga2web-autoconfigure:
  file.recurse:
    - name: /etc/icingaweb2/
    - source: salt://icinga2/files/etc.icingaweb2/
    - template: jinja
    - makedirs: True
    - user: www-data
    - group: icingaweb2
    - dir_mode: 750
    - file_mode: 644

icinga2web-autoconfigure-finalize:
  file.symlink:
    - name: /etc/icingaweb2/enabledModules/monitoring
    - target: /etc/icingaweb2/modules/monitoring
    - makedirs: True
    - user: www-data
    - group: icingaweb2
