{% if grains['os_family'] in [ 'RedHat', 'Rocky' ] %}
kill-firewalld-service:
  service.dead:
    - name: firewalld
    - enable: False
{% if grains.get('osmajorrelease', '') == 8 %}
delete-nft-ip-firewalld:
  nftables.delete:
    - family: ip
    - table: firewalld

delete-nft-ip6-firewalld:
  nftables.delete:
    - family: ip6
    - table: firewalld

delete-nft-inet-firewalld:
  nftables.delete:
    - family: inet
    - table: firewalld
{% endif %}
{% endif %}
