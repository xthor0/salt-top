install-nginx-packages:
    pkg.installed:
        - pkgs:
            - nginx-full
            - nodejs

enable-nginx-service:
    service.running:
        - name: nginx
        - enable: True
        - require:
            - pkg: install-nginx-packages
        - watch:
            - file: /usr/share/nginx/html/custom_404.html
            - file: /etc/nginx/sites-enabled/www.example.com

# custom 404 page
/usr/share/nginx/html/custom_404.html:
    file.managed:
        - mode: 644
        - user: root
        - group: root
        - contents: |
            <h1 style='color:red'>Error 404: Not Found</h1>
            <p>Sorry, dude. Can't find that file. Are you sure you typed in the correct URL?</p>
        - require:
            - pkg: install-nginx-packages

# nginx vhost conf file
/etc/nginx/sites-enabled/www.example.com:
    file.managed:
        - source: salt://wtw-nginx/files/www.example.com
        - mode: 644
        - user: root
        - group: root
        - require:
            - pkg: install-nginx-packages

# back-end nodejs web service
/srv/backend.js:
    file.managed:
        - source: salt://wtw-nginx/files/backend.js
        - mode: 644
        - user: root
        - group: root

# systemd service for the backend web service
/etc/systemd/system/backendweb.service:
  file.managed:
    - source: salt://wtw-nginx/files/simpleweb.service
    - name: 
    - template: jinja
    - require:
      - pkg: install-nginx-packages
      - file: /srv/backend.js

start-backend-webservice:
  service.running:
    - name: backendweb
    - enable: True
    - require:
      - file: /etc/systemd/system/backendweb.service
      - pkg: install-nginx-packages
    - watch:
      - file: /etc/systemd/system/backendweb.service
      - file: /srv/backend.js

# firewall
nginx:
  iptables.append:
    - table: filter
    - chain: INPUT
    - jump: ACCEPT
    - match:
        - state
        - comment
    - comment: "Allow HTTP"
    - connstate: NEW
    - dport: 3200
    - protocol: tcp
    - sport: 1025:65535
    - save: True
