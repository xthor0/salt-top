ciweb-packages:
  pkg.installed:
    - pkgs:
      - httpd
      - php
      - php-common

httpd:
  service.running:
    - enable: True
    - watch:
      - /etc/httpd/conf.d/override.conf

htaccess_file:
  file.managed:
    - name: /var/www/html/.htaccess
    - source: salt://ciweb/files/htaccess
    - user: root
    - group: root
    - mode: 644

index_php:
  file.managed:
    - name: /var/www/html/index.php
    - source: salt://ciweb/files/index.php
    - user: root
    - group: root
    - mode: 644

/etc/httpd/conf.d/override.conf:
  file.managed:
    - source: salt://ciweb/files/override.conf
    - user: root
    - group: root
    - mode: 644
