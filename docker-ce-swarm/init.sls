# get role & pxt
{% set roles = salt['grains.get']('roles', []) %}
{% if "swarm-master" in roles %}
{% set dockerrole = 'swarm-master' %}
{% elif "swarm-manager" in roles %}
{% set dockerrole = 'swarm-manager' %}
{% elif "swarm-worker" in roles %}
{% set dockerrole = 'swarm-worker' %}
{% endif %}
{% set PXT=salt['grains.get']('pxt') %}
{% set ENV=salt['grains.get']('env') %}

# docker-ce MUST be installed for swarm to function correctly
# but, only install keepalived for master/manager nodes
{% if dockerrole == 'swarm-master' or dockerrole == 'swarm-manager' %}
include:
    - docker-ce
    - .keepalived
{% else %}
include:
    - docker-ce
{% endif %}

# evaluate role and set up accordingly
{% if dockerrole == 'swarm-master' %}

# grab pillar data
{% set overrides = salt['pillar.get']('docker-swarm:lookup', {}) %}
{% set netif = salt['pillar.get']('docker-swarm:lookup:netif', {}) %}
{% set manager_token = salt['pillar.get']('docker-swarm:lookup:manager_token', {}) %}

# get the IP address of the master to build the init command
{% set ip = grains['ip4_interfaces'][netif][0] %}

# I used to have a service restart statement here that watched for the update to swarm.conf, and then restarted the minion
# but there's a bug in Salt older than one of the 2017 releases (I think) that makes a restart of the minion fail to return properly
# to the master (resulting in an error saying 'no connection' during the highstate).
#
# so, instead, a reactor job had to be created.
#
# because we don't have the reactor gitfs-backed, I'm going to show what that reactor job does here.
#
# in /etc/salt/master.d/reactor.conf, this event is configured:
  #  - 'custom/docker-ce-swarm/new-master':
  #   - /srv/salt/reactor/docker-new-master.sls
# and the contents of that sls file:

{# 
docker_new_master:
  local.cmd.run:
    - tgt: {{ data['id'] }}
      - arg:
        - 'sleep 5 && systemctl restart salt-minion && salt-call mine.update'

Also - and THIS IS IMPORTANT - secure this mine call! You'll need this in /etc/salt/master.d/mine_calls.conf. Obviously changes based on your minion IDs.

mine_get:
  swarm-manager-*:
    - swarm-master*:
      - manager_token
      - worker_token

#}

# we must also manage in a config file so that the salt mine functions properly
/etc/salt/minion.d/swarm.conf:
  file.managed:
    - source: salt://docker-ce-swarm/files/swarm.conf
    - template: jinja
    - require:
      - pkg: install-docker-ce-packages

# put an event on the bus that will fire a reactor on the master
event-new-master-fire:
  event:
    - name: custom/docker-ce-swarm/new-master
    - wait
    - watch:
      - file: /etc/salt/minion.d/swarm.conf
    - order: last

# build commands for swarm (executed at end of state)
{% set swarm_init_cmd = 'docker swarm init --advertise-addr ' ~ ip %}
{% set swarm_unless_cmd = 'docker swarm join-token worker -q' %}

{% elif dockerrole == 'swarm-manager' %}

# previously, we got the token from the mine, but this is not secure
{% set join_token = salt['mine.get']('G@env:'~ENV~ ' and G@pxt:'~PXT~ ' and G@roles:docker-ce-swarm and G@roles:swarm-master', 'manager_token', expr_form='compound').items()[0][1] %}
{% set join_ip = salt['mine.get']('G@env:'~ENV~ ' and G@pxt:'~PXT~ ' and G@roles:docker-ce-swarm and G@roles:swarm-master', 'manager_ip', expr_form='compound').items()[0][1] %}

# build commands
{% set swarm_init_cmd = 'docker swarm join --token ' ~ join_token ~ ' ' ~ join_ip  %}
{% set swarm_unless_cmd = 'docker swarm join-token manager -q' %}

{% elif dockerrole == 'swarm-worker' %}

# set join token and IP address from mine
{% set join_token = salt['mine.get']('G@env:'~ENV~ ' and G@pxt:'~PXT~ ' and G@roles:docker-ce-swarm and G@roles:swarm-master', 'worker_token', expr_form='compound').items()[0][1] %}
{% set join_ip = salt['mine.get']('G@env:'~ENV~ ' and G@pxt:'~PXT~ ' and G@roles:docker-ce-swarm and G@roles:swarm-master', 'manager_ip', expr_form='compound').items()[0][1] %}

# build commands
{% set swarm_init_cmd = 'docker swarm join --token ' ~ join_token ~ ' ' ~ join_ip  %}
## this might be a hack. workers can't do anything with the swarm, by design. but if this file exists we're already a worker.
{% set swarm_unless_cmd = 'test -f /var/lib/docker/swarm/worker/tasks.db' %}

{% endif %}

# run the previously generated swarm commands
docker-swarm-cmd:
    cmd.run:
        - name: {{ swarm_init_cmd }}
        - unless: {{ swarm_unless_cmd }}
        - require:
            - pkg: install-docker-ce-packages

# if this is a master or manager node, drain connections so that the ONLY role is that of a manager
# 2018.07.24 - commented because, in the case of Traefik, we have to run it on a manager or master node
{#
{% if dockerrole != 'swarm-worker' %}

docker-drain-cmd:
    cmd.run:
      - name: docker node update --availability drain {{ salt['grains.get']('id') }}
      - unless: docker node inspect {{ salt['grains.get']('id') }} | grep -q Availability.*drain
      - require:
        - pkg: install-docker-ce-packages

{% endif %}
#}

# if a master, we do the following:
  # restart salt-master to make sure that the swarm mine is accessible
  # add a traefik container for reverse proxy
  # spin up a stack for traefik
{% if dockerrole == 'swarm-master' %}

add-traefik-swarm-network:
    cmd.run:
      - name: docker network create --driver overlay traefik-net
      - unless: docker network ls | grep -q traefik-net
      - require:
        - pkg: install-docker-ce-packages

add-traefik-stack:
  cmd.run:
    - name: docker service create -q --name traefik --publish 80:""80 --publish 8080:""8080 --constraint=node.role==manager --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock --network traefik-net traefik --docker --docker.swarmMode --docker.watch --api
    - unless: docker service ls -f name=traefik | grep -q traefik
    - require:
        - pkg: install-docker-ce-packages

{% endif %}
