iperf3:
  pkg.installed

iperf3user:
  user.present:
    - shell: /usr/sbin/nologin

iperf3-service-file:
  file.managed:
    - name: /etc/systemd/system/iperf3.service
    - source: salt://iperf3/files/iperf3.service
    - user: root
    - group: root
    - mode: 644
    - require:
        - pkg: iperf3
        - user: iperf3user

start-iperf3-ervice:
  service.running:
    - name: iperf3
    - enable: True
    - require:
      - file: /etc/systemd/system/iperf3.service
      - pkg: iperf3
    - watch:
      - file: /etc/systemd/system/iperf3.service