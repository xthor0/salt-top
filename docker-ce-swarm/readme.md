Instructions for using docker-ce-swarm salt state files
====================================================

## Hardware Specifications
Unfortunately I couldn't find a lot of hard-and-fast data about this online, so... 2 CPU cores and 8GB RAM is a good start. I imagine a lot of that will depend on the applications running on this swarm.

## Docker Architecture Overview
You can consult the official Docker documentation here:

https://docs.docker.com/engine/swarm/admin_guide/#distribute-manager-nodes

Every environment should have at least 5 nodes to maintain a quorum, and you should always maintain an odd number.

At a minimum, you'll need 1 master, 1 manager, and 3 workers.

When expanding environments horizontally, 2 nodes should be added to keep an odd number for quorum maintenance.

## Set Up Your Pillar Data
Please remember a couple of things during setup.

- First, the examples below are for building a docker swarm based on Docker CE for a particular product team (PXT). The nomenclature is based on the company I work for, and you may need to change it accordingly to meet your needs.
- Second, don't hesitate to get help if you need it. If the pillar data isn't set up right, you're going to get weird errors that won't necessarily scream "Hey, your pillar data is wrong!"

Only your master and first manager need pillar data. All the workers pull their necessary configuration data from the Salt mine.

Add this to your pillar's top.sls file:

~~~
base:
    'G@roles:docker-ce-swarm and G@pxt:gear and G@env:dev':
      - match: compound
      - docker-swarm/gear-docker-ce-swarm
~~~

Then you'll need to create the referenced gear-docker-ce-swarm in your pillar root:

~~~
docker-swarm:
  lookup:
    netif: enp0s3
    routerid: 58
    {% set roles = salt['grains.get']('roles', []) %}
    {% if "swarm-master" in roles %}
    vrrp_prio: 100
    {% elif "swarm-manager" in roles %}
    vrrp_prio: 99
    {% endif %}
    vrrp_pass: SuperSecretVRRPPasswordGoesHere
    vip: 192.168.221.15
~~~

A couple of notes about these values:

- the 'netif' value needs to be the actual interface name on the system. Every distribution does this differently, and several RedHat-based distros recently changed this. Check the value after using salt-cloud to spin up the minion you're going to make the master by running this command:
~~~
salt minionid grains.item ip4_interfaces
~~~
- for the 'vip' value, make sure you select an IP address on the same VLAN as your network interface
- use a password generator for 'vrrp_pass' - pwgen on MacOS (brew install pwgen), for example
- vrrp_pass MUST match or keepalived won't be set up correctly. That means that if the master goes down, the virtual IP address won't move to the manager node, and your docker swarm will be unreachable.
- notice that vrrp_prio has a higher value for the master than the manager - that tells keepalived that the master is the preference, but the manager can take over if needed.
- routerid is recommended to be unique across all other keepalived instances.

## Configure states/top.sls for Highstate
~~~
dev:
  < ... scroll to end of dev stanza ... >
  ### docker-ce-swarm for gear pxt
  'G@roles:docker-ce-swarm and G@pxt:gear and G@env:dev':
    - match: compound
    - linux-system/hostname
    - linux-system/timezone
    - linux-system/iptables-disable
    - ntp.ng
    - docker-ce-swarm
~~~

Don't forget to commit & push top.sls back to the master branch.

## Set Up Grain Data
Next, you'll want to configure the grains appropriately. Since this is how we're targeting highstate and pillar data with grains, this is important.

Remember the notes you made earlier with the minion ID's that salt-cloud built? You'll need them now.

Set the main role grain, as well as the PXT, across the entire swarm. Your naming scheme may be different, but since ours are all random, here's what it looks like:

~~~
salt -L 8463b7fcb024,d2c5ab276b1d,8f71b0b907ee,7dffc38d5dc4,74a204b355c4 grains.append roles docker-ce-swarm
salt -L 8463b7fcb024,d2c5ab276b1d,8f71b0b907ee,7dffc38d5dc4,74a204b355c4 grains.setval pxt gear
~~~

Also note that if you're testing this (i.e., in vagrant, but really anywhere other than a salt master with salt-cloud configured to deploy minions with salt-cloud using appropriate grains), you'll also need to set the env grain appropriately:

~~~
salt -L 8463b7fcb024,d2c5ab276b1d,8f71b0b907ee,7dffc38d5dc4,74a204b355c4 grains.setval env dev
~~~

Pick a minion to be swarm master:

~~~
salt 8463b7fcb024 grains.append roles swarm-master
~~~

Next, pick a minion to be swarm manager:

~~~
salt d2c5ab276b1d grains.append roles swarm-manager
~~~

Finally, configure each of the worker nodes:

~~~
salt -L 8f71b0b907ee,7dffc38d5dc4,74a204b355c4 grains.append roles swarm-worker
~~~

## verify pillar data
~~~
salt -C 'G@pxt:gear and G@roles:docker-ce-swarm and G@roles:swarm-master and G@env:dev' pillar.items
~~~

If after running this command you see the keepalived and docker items you put in the pillar file, congrats! It's working as expected.

## deploy the master node
~~~
salt -C 'G@pxt:gear and G@roles:docker-ce-swarm and G@roles:swarm-master and G@env:dev' state.highstate
~~~

## Check the mine
~~~
salt -C 'G@env:prod and G@roles:swarm-manager and G@pxt:gear' mine.get 'G@env:dev and G@roles:swarm-master and G@pxt:gear' manager_ip expr_form=compound
~~~

If you see output like this:

~~~

~~~

The mine is working. If you don't see an IP address, you need to fix your mine calls.

## Deploy Manager Nodes
~~~
salt -C 'G@pxt:gear and G@roles:docker-ce-swarm and G@roles:swarm-manager and G@dev:dev' state.highstate
~~~

## Deploy Worker Nodes
~~~
salt -C 'G@pxt:gear and G@roles:docker-ce-swarm and G@roles:swarm-worker and G@env:dev' state.highstate
~~~

# Validate Deployment
~~~
salt -C 'G@pxt:gear and G@roles:docker-ce-swarm and G@roles:swarm-master and G@env:dev' cmd.run 'docker node ls'
~~~

You will see output like this:

~~~
m-7a4b57105eb4.localdev:
    ID                            HOSTNAME                  STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
    uhysl8rqy5taeequ8uuykrm67 *   m-7a4b57105eb4.localdev   Ready               Active              Leader              18.06.0-ce
    lpzzq4b3lmuml943rnmn8ai64     m-7d6b6394b038.localdev   Ready               Active                                  18.06.0-ce
    lapqw1x9v6gzsmbfmjl8v4um4     m-8b103504d842.localdev   Ready               Active                                  18.06.0-ce
    sgx6v5patsul7cb9uedubbdnh     m-2382de833121.localdev   Ready               Active                                  18.06.0-ce
    al04l2n53wn045apejzbj6drp     m-b91c5fdef91f.localdev   Ready               Active              Reachable           18.06.0-ce
~~~

You'll also want to make sure Traefik is running:

~~~
salt -C 'G@pxt:gear and G@roles:docker-ce-swarm and G@roles:swarm-master and G@env:dev' cmd.run 'docker service ls'
~~~

Here is the expected output:

~~~
m-7a4b57105eb4.localdev:
    ID                  NAME                MODE                REPLICAS            IMAGE               PORTS
    vvtfz0h8ecz4        traefik             replicated          1/1                 traefik:latest      *:80->80/tcp, *:8080->8080/tcp
~~~
