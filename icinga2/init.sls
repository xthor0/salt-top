# we need some repos configured
include:
    - mariadb
    - .repo
    - .database

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
        - unless: icingacli setup token show

# bug that needs fixing
# selinux will prevent access to command file - can't click 'check now'

# this is 

{#
 
# cat icingaweb2fix.te

module icingaweb2fix 1.0;

require {
	type var_run_t;
	type httpd_t;
	class fifo_file { getattr open };
}

/usr/bin/make -f /usr/share/selinux/devel/Makefile icingaweb2fix.pp
/usr/sbin/semodule -i icingaweb2fix.pp

I'll have to test this.

#}

# here's how I did this manually!

{#
rpm -ivh https://packages.icinga.com/epel/icinga-rpm-release-7-latest.noarch.rpm
yum install epel-release
yum install icinga2 mariadb-server mariadb icinga2-ido-mysql httpd mod_ssl centos-release-scl nagios-plugins\*
yum install icingaweb2-selinux icingaweb2 icingacli

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/pki/tls/private/localhost.key -out /etc/pki/tls/certs/localhost.crt
-- I think Salt can do this easier - this asks questions...

edit /etc/opt/rh/rh-php71/php.ini: date.timezone = "America/Denver"

systemctl start rh-php71-php-fpm.service
systemctl enable rh-php71-php-fpm.service

systemctl enable icinga2
systemctl start icinga2
systemctl enable mariadb
systemctl start mariadb

systemctl enable httpd
systemctl start httpd

icinga2 feature enable command
icinga2 feature enable ido-mysql

mysql_secure_installation

# mysql -u root -p

CREATE DATABASE icinga;
CREATE DATABASE icingaweb2;

GRANT ALL ON icinga.* TO 'icinga'@'localhost' IDENTIFIED BY 'cut3p@ss';
GRANT ALL ON icinga.* TO 'icingaweb2'@'localhost' IDENTIFIED BY 'cut3p@ss';

quit

mysql -u root -p icinga < /usr/share/icinga2-ido-mysql/schema/mysql.sql

The package provides a new configuration file that is installed in /etc/icinga2/features-available/ido-mysql.conf. You can update the database credentials in this file.
vim /etc/icinga2/features-enabled/ido-mysql.conf - change user/password

icinga2 feature enable ido-mysql
# said it was already enabled, so... maybe we don't need this

systemctl restart icinga2

icingacli setup config directory --group icingaweb2;
icingacli setup token create;
-- now paste the token here when prompted: https://localhost:8443/icingaweb2/setup



#}
