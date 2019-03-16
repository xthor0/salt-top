{% if grains.get('os', '') == 'CentOS' %}
kill-firewalld-service:
  service.dead:
    - name: firewalld
    - enable: False
{% endif %}
