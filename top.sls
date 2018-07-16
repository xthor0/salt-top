##### production
prod:
  'G@kernel:linux and G@env:prod':
    - match: compound
    - states.linuxos

##### development
dev:
  'G@kernel:linux and G@env:dev':
    - match: compound
    - states.linuxos
  'G@kernel:linux and G@roles:docker-swarm':
    - match: compound
    - states.docker-swarm

##### TODO: we need a way to target a feature branch...
