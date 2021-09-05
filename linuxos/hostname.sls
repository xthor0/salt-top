{%- set fqdn = grains['id'] %}
{%- if grains['os_family'] == 'Debian' %}
  {% set hostname = fqdn.split('.')[0] %}
{%- else %}
  {%- set hostname = fqdn %}
{% endif %}

{%- if grains['os_family'] == 'RedHat' %}
hostsfile-etc-sysconfig-network:
  cmd.run:
    - name: echo -e "NETWORKING=yes\nHOSTNAME={{ hostname }}\n" > /etc/sysconfig/network
    - unless: test -f /etc/sysconfig/network
  file.replace:
    - name: /etc/sysconfig/network
    - pattern: HOSTNAME=localhost.localdomain
    - repl: HOSTNAME={{ hostname }}
{% endif %}

hostsfile-set-fqdn:
  cmd.run:
    {% if grains["init"] == "systemd" %}
    - name: hostnamectl set-hostname {{ hostname }}
    {% else %}
    - name: hostname {{ hostname }}
    {% endif %}
    - unless: test "{{ hostname }}" = "$(hostname)"

127.0.1.1:
  host.only:
    - hostnames:
      - {{ hostname }}