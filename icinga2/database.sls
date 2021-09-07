# install mariadb
install-mariadb-icinga2:
    pkg.installed:
        - pkgs:
{% if grains['os_family'] == 'Debian' %}
            - mariadb-server
            - mariadb-client
            - python3-mysqldb
{% elif grains['os_family'] in [ 'RedHat', 'Rocky' ] %}
            - mariadb-server
            - mariadb
            - python3-mysql

mariadb.service:
    service.running:
        - enable: True
    watch:
        - file: /etc/my.cnf.d/mariadb-server.cnf

/etc/my.cnf.d/mariadb-server.cnf:
    file.managed:
        - source: salt://icinga2/files/mariadb-server.cnf
        - mode: 0644
        - user: root
        - group: root
{% endif %}

# add icinga user to database from pillar info
icinga2_db_user:
    mysql_user.present:
        - host: localhost
        - name: {{ salt['pillar.get']('icinga2:database:username') }}
        - password: {{ salt['pillar.get']('icinga2:database:password') }}
        - allow_passwordless: True

# grant icinga2 user to icinga2 db
icinga2_user_grant_icinga2:
    mysql_grants.present:
        - grant: all privileges
        - database: {{ salt['pillar.get']('icinga2:database:icinga2_db_name') }}.*
        - user: {{ salt['pillar.get']('icinga2:database:username') }}
        - host: localhost
        - allow_passwordless: True

# grant icinga2 user to icingaweb2 db
icinga2_user_grant_icingaweb2:
    mysql_grants.present:
        - grant: all privileges
        - database: {{ salt['pillar.get']('icinga2:database:icingaweb2_db_name') }}.*
        - user: {{ salt['pillar.get']('icinga2:database:username') }}
        - host: localhost
        - allow_passwordless: True

# create icinga2 db
{{ salt['pillar.get']('icinga2:database:icinga2_db_name') }}_create_db:
    mysql_database.present:
        - name: {{ salt['pillar.get']('icinga2:database:icinga2_db_name') }}

# create icingaweb2 db
{{ salt['pillar.get']('icinga2:database:icingaweb2_db_name') }}_create_db:
    mysql_database.present:
        - name: {{ salt['pillar.get']('icinga2:database:icingaweb2_db_name') }}

# load icinga2 database from schema file
icinga2-ido-load:
  cmd.run:
    - name: mysql {{ salt['pillar.get']('icinga2:database:icinga2_db_name') }} < /usr/share/icinga2-ido-mysql/schema/mysql.sql
    - require:
        - pkg: install-icinga2-pkgs
        - pkg: install-mariadb-icinga2
        - mysql_database: {{ salt['pillar.get']('icinga2:database:icinga2_db_name') }}_create_db
    - unless:
        - echo "show tables;" | mysql {{ salt['pillar.get']('icinga2:database:icinga2_db_name') }} | grep -q icinga_

# load icingaweb2 database from schema file
# why, icinga, why did you have to change the location of this file depending on packaging?
{% if grains['os_family'] == 'Debian' %}
{% set icingaweb2_schema_file = '/usr/share/icingaweb2/etc/schema/mysql.schema.sql' %}
{% elif grains['os_family'] in [ 'RedHat', 'Rocky' ] %}
{% set icingaweb2_schema_file = '/usr/share/doc/icingaweb2/schema/mysql.schema.sql' %}
{% endif %}

icingaweb2-schema-load:
  cmd.run:
    - name: mysql {{ salt['pillar.get']('icinga2:database:icingaweb2_db_name') }} < {{ icingaweb2_schema_file }}
    - require:
        - pkg: install-icinga2-pkgs
        - pkg: install-mariadb-icinga2
        - mysql_database: {{ salt['pillar.get']('icinga2:database:icingaweb2_db_name') }}_create_db
    - unless:
        - echo "show tables;" | mysql {{ salt['pillar.get']('icinga2:database:icingaweb2_db_name') }} | grep -q icingaweb_

# load admin user with password of 'changeme' - but only do this once, if there are no users in table
icingaweb2-sql-file-user:
    file.managed:
        - name: /root/icingaweb2_default_admin_user.sql
        - mode: 0600
        - user: root
        - group: root
        - contents: |
            /* thanks for being stupid, bash - sigh. otherwise I coulda done this with mysql -e. */
            INSERT INTO `icingaweb_user` (name, active, password_hash) VALUES ('{{ salt['pillar.get']('icinga2:icingaweb2:username') }}', 1, '{{ salt['pillar.get']('icinga2:icingaweb2:hashed_password') }}');
            INSERT INTO `icingaweb_group` (name) VALUES ('Administrators');
            INSERT INTO `icingaweb_group_membership` (group_id,username) VALUES (1,'admin');
            INSERT INTO `icingaweb_user_preference` (username,section,name,value) VALUES ('{{ salt['pillar.get']('icinga2:icingaweb2:username') }}','icingaweb','auto_refresh','1'),('{{ salt['pillar.get']('icinga2:icingaweb2:username') }}','icingaweb','show_application_state_messages','system'),('{{ salt['pillar.get']('icinga2:icingaweb2:username') }}','icingaweb','show_benchmark','0'),('{{ salt['pillar.get']('icinga2:icingaweb2:username') }}','icingaweb','show_stacktraces','1'),('{{ salt['pillar.get']('icinga2:icingaweb2:username') }}','icingaweb','theme','solarized-dark');

icingaweb2-user-load:
  cmd.run:
    - name: mysql {{ salt['pillar.get']('icinga2:database:icingaweb2_db_name') }} < /root/icingaweb2_default_admin_user.sql
    - require:
        - pkg: install-icinga2-pkgs
        - pkg: install-mariadb-icinga2
        - file: icingaweb2-sql-file-user
        - mysql_database: {{ salt['pillar.get']('icinga2:database:icingaweb2_db_name') }}_create_db
        - cmd: icingaweb2-schema-load
    - unless:
        - mysql -e "SELECT name from {{ salt['pillar.get']('icinga2:database:icingaweb2_db_name') }}.icingaweb_user WHERE name = '{{ salt['pillar.get']('icinga2:icingaweb2:username') }}'" --silent --raw | grep -q {{ salt['pillar.get']('icinga2:icingaweb2:username') }}
