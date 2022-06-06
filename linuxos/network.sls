{% if grains['os_family'] in [ 'RedHat', 'Rocky' ] %}
kill-firewalld-service:
  service.dead:
    - name: firewalld
    - enable: False
{% if grains.get('osmajorrelease', '') == 8 %}
{# this is a hack, but the nftable states don't seem to let me delete a table? #}
{# this only shows up on hosts built from the installer ISO #}
{# this doesn't work: 

delete-nft-ip-firewalld:
  nftables.delete:
    - family: ip
    - table: firewalld

#}
delete-nft-ip-firewalld:
  cmd.run:
    - name: nft delete table ip firewalld
    - unless: nft list tables | grep -qv '^table ip firewalld'

delete-nft-ip6-firewalld:
  cmd.run:
    - name: nft delete table ip6 firewalld
    - unless: nft list tables | grep -qv '^table ip6 firewalld'

delete-nft-inet-firewalld:
  cmd.run:
    - name: nft delete table inet firewalld
    - unless: nft list tables | grep -qv '^table inet firewalld'
{% endif %}
{% endif %}
