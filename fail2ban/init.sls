install-fail2ban-pkg:
  pkg.installed:
    - name: fail2ban

fail2ban-jail-conf:
  file.managed:
    - name: /etc/fail2ban/jail.local
    - source: salt://fail2ban/files/jail.local
    - user: root
    - group: root
    - mode: 644
    - require:
      - install-fail2ban-pkg

fail2ban-service:
  service.running:
    - name: apcupsd
    - enable: True
    - require:
      - install-fail2ban-pkg
      - fail2ban-jail-conf
    - watch:
      - fail2ban-jail-conf
