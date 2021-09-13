{% if grains.get('os_family', '') == 'RedHat' %}
{% if grains.get('osmajorrelease', '') == 7 %}
{% set include = 'autoupdates.rhel7' %}
{% elif grains.get('osmajorrelease', '') == 8 %}
{% set include = 'autoupdates.rhel8' %}
{% endif %}
{% elif grains.get('os_family', '') == 'Debian' %}
{% set include = 'autoupdates.debian' %}
{% endif %}

include:
    - linuxos.{{ include }}