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

##### TODO: we need a way to target a feature branch...
