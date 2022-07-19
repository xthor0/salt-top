{% set roles = salt['grains.get']('roles', []) %}
include:
{% if "firewall" not in roles %}
  - .network
{% endif %}
  - .ssh
  - .packages
  - .users
  - .autoupdate
