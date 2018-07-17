##### production
prod:
  'G@kernel:linux and G@env:prod':
    - match: compound
    - linuxos

##### development
dev:
  'G@kernel:linux and G@env:dev':
    - match: compound
    - linuxos
  'G@kernel:linux and G@roles:docker-swarm':
    - match: compound
    - docker-swarm

##### TODO: we need a way to target a feature branch...
