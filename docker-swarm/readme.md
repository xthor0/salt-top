Instructions for using docker-swarm salt state files
====================================================

## hardware specifications
Unfortunately I couldn't find a lot of hard-and-fast data about this online, so I based it on what's currently deployed to production.

Currently, all Docker hosts run 2 CPUs and 8GB RAM. This documentation will be updated to include salt-cloud deployment methodology.

## docker architecture overview
You can consult the official Docker documentation here:

https://docs.docker.com/engine/swarm/admin_guide/#distribute-manager-nodes

Every environment should have at least 7 nodes to maintain a quorum. 1 master, 2 managers, 4 workers.

When expanding environments horizontally, 2 nodes should be added to keep an odd number for quorum maintenance.

## Set up your pillar data
The only minion that needs pillar data is the first Docker node in the environment. Here's how to lay out your pillar top.sls

base:
    'G@roles:docker-swarm and G@docker-role:master and G@pxt:ben':
        - match: compound
        - docker-swarm-master  

and here is what the contents of docker-swarm-master.sls looks like:

docker-swarm:
    lookup:
        netif: enp0s8

# set up state top.sls for highstate
NOTE: this needs to be updated, this is just for my local Vagrant environment, will look different once it hits the VMware environment.
base:
    'docker-swarm*':
        - docker-swarm

## Set up your grain data
Next, you'll want to configure the grains appropriately. Configure the node you want to be a master:

salt docker-swarm1 grains.append roles docker-swarm
salt docker-swarm1 grains.setval docker-role master
salt docker-swarm1 grains.setval pxt <pxtname>

Configure your manager nodes:

salt 'docker-swarm[2-3]' grains.append roles docker-swarm
salt 'docker-swarm[2-3]' grains.setval docker-role manager
salt 'docker-swarm[2-3]' grains.setval pxt <pxtname>

Finally, configure each of the worker nodes:

salt 'docker-swarm[4-7]' grains.append roles docker-swarm
salt 'docker-swarm[4-7]' grains.setval docker-role worker
salt 'docker-swarm[4-7]' grains.setval pxt <pxtname>

## deploy the master node
salt -C 'G@pxt:<name> and G@roles:docker-swarm and G@docker-role:master' state.highstate

## deploy remaining nodes
salt -C 'G@pxt:<name> and G@roles:docker-swarm and G@docker-role:manager' state.highstate
salt -C 'G@pxt:<name> and G@roles:docker-swarm and G@docker-role:worker' state.highstate

# validate
salt -C 'G@pxt:<name> and G@roles:docker-swarm and G@docker-role:master' cmd.run 'docker node ls'

you will see output like this:

docker-swarm1:
    ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
    k2aan2vylqyhpmbvmszxh1o11 *   docker-swarm1       Ready               Active              Leader              18.03.1-ce
    xpodtzxfqb08t398ehbaawzjh     docker-swarm2       Ready               Active              Reachable           18.03.1-ce
    9qde8eh5ql1ecxmm3imoywfiz     docker-swarm3       Ready               Active                                  18.03.1-ce
    asqj13stz47sezm0yzffvl0yr     docker-swarm4       Ready               Active                                  18.03.1-ce
    cmwth9y5ric5mcppcgmbiigp8     docker-swarm5       Ready               Active                                  18.03.1-ce
