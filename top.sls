##### production
prod:
  'G@kernel:linux and G@env:prod':
    - match: compound
    - linuxos
    - nrpe
  'G@kernel:linux and G@roles:jumpbox and G@env:prod':
    - fail2ban
  'G@env:prod and G@roles:apcupsd':
    - match: compound
    - apcupsd

##### development
dev:
  'G@kernel:linux and G@env:dev':
    - match: compound
    - linuxos
    - nrpe
  'G@env:dev and G@roles:icinga2':
    - match: compound
    - icinga2