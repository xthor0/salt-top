{% if grains.get('os', '') == 'CentOS' %}
firewalld:
  service.dead
{% endif %}
