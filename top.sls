##### production
prod:
  'G@kernel:linux and G@env:prod':
    - match: compound
    - linuxos
  'G@kernel:linux and G@roles:docker-ce-swarm and G@env:prod':
    - match: compound
    - docker-ce-swarm
  'nagios.american-ins.com':
    - icinga2
  'G@kernel:linux and G@roles:jumpbox and G@env:prod':
    - fail2ban

##### development
dev:
  'G@kernel:linux and G@env:dev':
    - match: compound
    - linuxos
  'G@kernel:linux and G@roles:docker-ce-swarm and G@env:dev':
    - match: compound
    - docker-ce-swarm
  'G@env:dev and G@roles:apcupsd':
    - match: compound
    - apcupsd
  'G@env:dev and G@roles:virtualbox':
    - match: compound
    - virtualbox
  'G@env:dev and G@roles:icinga2':
    - match: compound
    - icinga2

##### TODO: we need a way to target a feature branch...
