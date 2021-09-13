ubiquiti_pkgreop_deps:
    pkg.installed:
        - pkgs:
            - ca-certificates
            - apt-transport-https
        - require_in:
            - ubiquiti_unifi_repo

unifi_pkg_deps:
    pkg.installed:
        - name: openjdk-8-jre-headless
        - require_in:
            - unifi_pkg_install

ubiquiti_unifi_repo:
  pkgrepo.managed:
    - name: deb http://www.ubnt.com/downloads/unifi/debian stable ubiquiti
    - keyid: 06E85760C0A52C50
    - keyserver: keyserver.ubuntu.com
    - require_in:
      - ubiquiti_install

unifi_pkg_install:
    pkg.installed:
        - name: unifi

unifi-service-up-and-running:
  service.running:
    - name: unifi
    - enable: True
