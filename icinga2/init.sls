# we need some repos configured
include:
    - mariadb
    - .repo
    - .database

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
        - require:
            - install-icinga2-prereqs

# turn on MTA
postfix.service:
    service.running:
        - enable: True

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

# generate self-signed SSL certificate
{% if salt['pillar.get']('ssl:C') %}
generate-self-signed-ssl:
    cmd.run:
        - name: |
            openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
            -subj "/C={{ salt['pillar.get']('ssl:C') }}/ST={{ salt['pillar.get']('ssl:ST') }}/L={{ salt['pillar.get']('ssl:L') }}/O={{ salt['pillar.get']('ssl:O') }}/CN={{ salt['grains.get']('id') }}" \
            -keyout /etc/pki/tls/private/localhost.key \
            -out /etc/pki/tls/certs/localhost.crt
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
        - enable: Tru
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
        - unless: icinga2 feature list | grep -q '^Enabled.*ido-mysql'
        - require:
            - file: ido-mysql-conf-file
        - watch:
            - file: ido-mysql-conf-file

# enable command feature
enable-icinga2-feature-command:
    cmd.run:
        - name: icinga2 feature enable command
        - unless: icinga2 feature list | grep -q '^Enabled.*command'

icinga2-create-setup-token:
    cmd.run:
        - name: icingacli setup token create
        - unless: test -f /var/run/icinga2/cmd/icinga2.cmd

# manage in all the files we need
/etc/icinga2/conf.d/commands.conf:
  file.managed:
    - source: salt://icinga2/files/commands.conf
    - user: icinga
    - group: icinga
    - mode: 640
    - after:
      - install-icinga2-pkgs

/etc/icinga2/conf.d/notifications.conf:
  file.managed:
    - source: salt://icinga2/files/notifications.conf
    - user: icinga
    - group: icinga
    - mode: 640
    - after:
      - install-icinga2-pkgs

/etc/icinga2/conf.d/templates.conf:
  file.managed:
    - source: salt://icinga2/files/templates.conf
    - user: icinga
    - group: icinga
    - mode: 640
    - after:
      - install-icinga2-pkgs

/etc/icinga2/conf.d/users.conf:
  file.managed:
    - source: salt://icinga2/files/users.conf.jinja
    - user: icinga
    - group: icinga
    - template: jinja
    - mode: 640
    - after:
      - install-icinga2-pkgs

/etc/icinga2/conf.d/hosts.conf:
  file.managed:
    - source: salt://icinga2/files/hosts.conf.jinja
    - user: icinga
    - group: icinga
    - template: jinja
    - mode: 640
    - after:
      - install-icinga2-pkgs

/etc/icinga2/scripts/notify_by_pushover.sh:
  file.managed:
    - source: salt://icinga2/files/notify_by_pushover.sh
    - user: icinga
    - group: icinga
    - mode: 750


