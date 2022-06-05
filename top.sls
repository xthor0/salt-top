##### production
prod:
  'G@kernel:linux and G@env:prod':
    - match: compound
    - linuxos
    - nrpe
  'G@env:prod and G@roles:icinga2':
    - match: compound
    - icinga2
  'G@kernel:linux and G@roles:jumpbox and G@env:prod':
    - match: compound
    - fail2ban
  'G@env:prod and G@roles:apcupsd':
    - match: compound
    - apcupsd
  'G@env:prod and G@roles:libvirt':
    - match: compound
    - libvirt
  'G@env:prod and G@roles:unifi':
    - match: compound
    - unifi

##### development
dev:
  'G@kernel:linux and G@env:dev':
    - match: compound
    - linuxos
    - nrpe
  'G@env:dev and G@roles:icinga2':
    - match: compound
    - icinga2
  'G@env:dev and G@roles:apcupsd':
    - match: compound
    - apcupsd
  'G@env:dev and G@roles:libvirt':
    - match: compound
    - libvirt
  'G@env:dev and G@roles:ciweb':
    - match: compound
    - ciweb
  'G@env:dev and G@roles:iperf3':
    - match: compound
    - iperf3
