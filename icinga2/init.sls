# set up some variables depending on our OS
# defaults built for debian and derivitives
{% set phpini = '/etc/php/7.4/apache2/php.ini' %}
{% set apache_user = 'www-data' %}
{% set apache_service = 'apache2' %}
{% set icinga_local_user = 'nagios' %}
{% if grains['os_family'] in [ 'RedHat', 'Rocky' ] %}
{% set apache_user = 'apache' %}
{% set apache_service = 'httpd' %}
{% set icinga_local_user = 'icinga' %}
{% if grains.get('osmajorrelease', '') == 7 %}
{% set phpini = '/etc/opt/rh/rh-php71/php.ini' %}
{% else %}
{% set phpini = '/etc/php.ini' %}
{% endif %}
{% endif %}

# we need some repos configured
include:
  - .repo
  - .database

install-icinga2-pkgs:
  pkg.installed:
    - pkgs:
{% if grains['os_family'] == 'Debian' %}
      - icinga2
      - icinga2-ido-mysql
      - icingaweb2
      - icingacli
      - apache2
      - monitoring-plugins
      - nagios-nrpe-plugin
      - vim-icinga2
      - vim-addon-manager
      - bsd-mailx
      - postfix
{% elif grains['os_family'] in [ 'RedHat', 'Rocky' ] %}
      - icinga2
      - icinga2-ido-mysql
      - icingaweb2
      - icingaweb2-selinux
      - icingacli
      - httpd
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
{% endif %}
    - require:
      - pkgrepo: icinga-stable-release

{% if grains['os_family'] in [ 'RedHat', 'Rocky' ] %}
{% if grains.get('osmajorrelease', '') == 7 %}
# start php-fpm service
rh-php71-php-fpm.service:
  service.running:
    - enable: True
    - require:
      - pkg: install-icinga2-pkgs
    - watch:
      - file: {{ phpini }}
{% endif %}

# if we want the local Icingaweb2 instance to be able to control itself, this boolean is required
httpd_can_network_connect:
  selinux.boolean:
    - value: True
    - persist: True
{% endif %}

# fix date.timezone in php.ini
{{ phpini }}:
  file.replace:
    - pattern: '^;date.timezone =$'
    - repl: 'date.timezone = "America/Denver"'
    - require:
      - pkg: install-icinga2-pkgs

# turn on MTA
postfix.service:
  service.running:
    - enable: True

# manage in a redirect for default website
http-redirect-index:
  file.managed:
    - name: /var/www/html/index.html
    - source: salt://icinga2/files/index.html
    - template: jinja

# start web service
{{ apache_service }}.service:
  service.running:
    - enable: True
    - require:
      - pkg: install-icinga2-pkgs
    - watch:
      - file: {{ phpini }}

# start icinga2 service
icinga2.service:
  service.running:
    - enable: True
    - require:
      - pkg: install-icinga2-pkgs
    - watch:
      - cmd: enable-icinga2-feature-idomysql
      - cmd: enable-icinga2-feature-command

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

# manage in all the files we need
/etc/icinga2/conf.d/commands.conf:
  file.managed:
    - source: salt://icinga2/files/commands.conf.jinja
    - user: {{ icinga_local_user }}
    - group: {{ icinga_local_user }}
    - mode: 640
    - template: jinja
    - after:
      - install-icinga2-pkgs
    - require_in:
      - icinga2.service
    - watch_in:
      - icinga2.service

/etc/icinga2/conf.d/notifications.conf:
  file.managed:
    - source: salt://icinga2/files/notifications.conf
    - user: {{ icinga_local_user }}
    - group: {{ icinga_local_user }}
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
    - user: {{ icinga_local_user }}
    - group: {{ icinga_local_user }}
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
    - user: {{ icinga_local_user }}
    - group: {{ icinga_local_user }}
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
    - user: {{ icinga_local_user }}
    - group: {{ icinga_local_user }}
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
    - user: {{ icinga_local_user }}
    - group: {{ icinga_local_user }}
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
    - user: {{ icinga_local_user }}
    - group: {{ icinga_local_user }}
    - template: jinja
    - mode: 640
    - after:
      - install-icinga2-pkgs
    - require_in:
      - icinga2.service
    - watch_in:
      - icinga2.service

/etc/icinga2/conf.d/apt.conf:
  file.managed:
    - source: salt://icinga2/files/apt.conf
    - user: {{ icinga_local_user }}
    - group: {{ icinga_local_user }}
    - mode: 640
    - after:
      - install-icinga2-pkgs
    - require_in:
      - icinga2.service
    - watch_in:
      - icinga2.service

/etc/icinga2/scripts/notify_by_pushover.sh:
  file.managed:
    - source: salt://icinga2/files/notify_by_pushover.sh
    - user: {{ icinga_local_user }}
    - group: {{ icinga_local_user }}
    - mode: 750

{% if grains['os_family'] == 'Debian' %}
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
{% endif %}

# Configure automatically Icinga web, avoiding the use of the php wizard
icinga2web-autoconfigure:
  file.recurse:
    - name: /etc/icingaweb2/
    - source: salt://icinga2/files/etc.icingaweb2/
    - template: jinja
    - makedirs: True
    - user: {{ apache_user }}
    - group: icingaweb2
    - dir_mode: 750
    - file_mode: 644
    - before:
      - file: /etc/icingaweb2/modules/monitoring/commandtransports.ini
    - watch_in:
      - {{ apache_service }}.service

/etc/icingaweb2/modules/monitoring/commandtransports.ini:
  file.managed:
    - source: salt://icinga2/files/commandtransports.ini.jinja
    - user: {{ apache_user }}
    - group: icingaweb2
    - template: jinja
    - mode: 660
    - after:
      - install-icinga2-pkgs
      - icinga2-api-setup
      - /etc/icingaweb2/modules/monitoring
    - watch_in:
      - {{ apache_service }}.service

icinga2web-autoconfigure-finalize:
  file.symlink:
    - name: /etc/icingaweb2/enabledModules/monitoring
    - target: /usr/share/icingaweb2/modules/monitoring
    - makedirs: True
    - user: {{ apache_user }}
    - group: icingaweb2
    - watch_in:
      - {{ apache_service }}.service

# manage in ido-mysql.conf
ido-mysql-conf-file:
    file.managed:
        - source: salt://icinga2/files/ido-mysql.conf
        - name: /etc/icinga2/features-available/ido-mysql.conf
        - template: jinja
        - user: {{ icinga_local_user }}
        - group: {{ icinga_local_user }}
        - mode: 640
        - require:
            - pkg: install-icinga2-pkgs
        - watch_in:
            - icinga2.service