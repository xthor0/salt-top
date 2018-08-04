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

##### development
dev:
  'G@kernel:linux and G@env:dev':
    - match: compound
    - linuxos
  'G@kernel:linux and G@roles:docker-ce-swarm and G@env:dev':
    - match: compound
    - docker-ce-swarm

##### TODO: we need a way to target a feature branch...
