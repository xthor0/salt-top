# mysql -u root -p icinga < /usr/share/icinga2-ido-mysql/schema/mysql.sql
icinga2-ido-load:
  cmd.run:
    - name: mysql -u root -p{{ salt['pillar.get']('mariadb:master_user:password') }} icinga < /usr/share/icinga2-ido-mysql/schema/mysql.sql
    - require:
        - pkg: install-icinga2-pkgs
        - mysql_database: mariadb_database_icinga
    - unless:
        - echo "show tables;" | mysql -u root -p{{ salt['pillar.get']('mariadb:master_user:password') }} icinga | grep -q icinga_

# manage in ido-mysql.conf
ido-mysql-conf-file:
    file.managed:
        - source: salt://icinga2/files/ido-mysql.conf
        - name: /etc/icinga2/features-available/ido-mysql.conf
        - template: jinja
        - user: icinga
        - group: icinga
        - mode: 640
        - require:
            - pkg: install-icinga2-pkgs
