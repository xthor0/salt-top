# docker-ce MUST be installed for swarm to function correctly
include:
    - docker-ce

# we must also manage in a config file so that the salt mine functions properly:
/etc/salt/minion.d/swarm.conf:
  file.managed:
    - source: salt://docker-swarm/files/swarm.conf
    - template: jinja
    - require:
      - pkg: install-docker-ce-packages

# do we have to restart the salt minion after placing this file? I'd assume so...