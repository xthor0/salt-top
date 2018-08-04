Instructions for using docker-ce-swarm salt state files
====================================================

## Hardware Specifications
Unfortunately I couldn't find a lot of hard-and-fast data about this online, so I based it on what's currently deployed to production.

Currently, all Docker hosts run 2 CPUs and 8GB RAM. So, if you wanted to deploy a swarm of these servers in dev, here's how to do it:

- Run this command 5 times:
<code>
sudo /home/bebrown/build_server.pl -p dc1-centos7-dev-t2-medium
</code>
- MAKE A NOTE of the name of the minion each time this command is run, you'll need the IDs later.
- You may need to choose a different profile for production than what I have chosen for dev.
- If you don't want to use the script I wrote, you can do this with regular ol' salt-cloud:
<code>
for i in $(seq 1 5); do rnd=`date | md5sum | cut -c 1-12`; echo -e "\n\nAttempting to deploy: ${rnd}\n\n"; salt-cloud -p dc1-centos7-dev-t2-medium; read "Press Enter after making a node of the name of the new minion"; done
</code>
- If salt-cloud is used manually, you'll have to add a 2nd 100GB disk and add it to the LVM configuration (which is outside the scope of this document).

## Docker Architecture Overview
You can consult the official Docker documentation here:

https://docs.docker.com/engine/swarm/admin_guide/#distribute-manager-nodes

Every environment should have at least 5 nodes to maintain a quorum, and you should always maintain an odd number.

At a minimum, you'll need 1 master, 1 manager, and 3 workers.

When expanding environments horizontally, 2 nodes should be added to keep an odd number for quorum maintenance.

## Set Up Your Pillar Data
Please remember a couple of things during setup.

- First, the examples below are for building a dev docker-ce swarm for Gear. The lane and PXT you are deploying for MAY be different - change the names accordingly.
- Second, don't hesitate to get help if you need it. If the pillar data isn't set up right, you're going to get weird errors that won't necessarily scream "Hey, your pillar data is wrong!"

Only your master and first manager need pillar data. All the workers pull their necessary configuration data from the Salt mine, using data on the master.

Add this to your pillar's top.sls file:

<code>
dev:
    < ... go to the end of the dev stanza in top.sls ... >
    'G@roles:docker-ce-swarm and G@pxt:gear and G@env:dev':
      - match: compound
      - docker-swarm/gear-docker-ce-swarm

</code>

Then, create a file in the directory where you've checked out your pillar data, for example: /Users/bebrown/git/chg-pillar/dev/gear-docker-ce-swarm-master.sls

<code>
docker-swarm:
  lookup:
    netif: enp0s3
    routerid: 58
    {% set roles = salt['grains.get']('roles', []) %}
    {% if "swarm-master" in roles %}
    vrrp_prio: 100
    {% elif "swarm-manager" in roles %}
    vrrp_prio: 101
    {% endif %}
    vrrp_pass: SuperSecretVRRPPasswordGoesHere
    vip: 192.168.221.15
    master_ip: pastelater
    manager_token: pastelater
    worker_token: pastelater
</code>

A couple of notes about these values:

- the 'netif' value needs to be the actual interface name on the system. Every distribution does this differently, and several RedHat-based distros recently changed this. Check the value after using salt-cloud to spin up the minion you're going to make the master by running this command:
<code>
salt minionid grains.item ip4_interfaces
</code>
- for the 'vip' value, make sure you select an IP address from vlan 6, 7, or 8 and mark it appropriately here: https://itcentral.chgcompanies.com/confluence/display/ITOPS/IP+Address+Layout+at+C7+Bluffdale
- use a password generator for 'vrrp_pass' - pwgen on MacOS (brew install pwgen), for example
- vrrp_pass MUST match or keepalived won't be set up correctly. That means that if the master goes down, the virtual IP address won't move to the manager node, and your docker swarm will be unreachable.
- notice that vrrp_prio increments - that tells keepalived that the master is the preference, but the manager can take over if needed.
- routerid is recommended to be unique across all other keepalived instances. It's inelegant, but pretty easy to make sure that's the case by doing this:
<code>
$ pwd
/Users/bebrown/git/chg-salt/pillars
$ grep -ri routerid *
dev/keepalived/webservices.sls:routerid: 51
dev/keepalived/elk-haproxy.sls:routerid: 56
prod/keepalived/webservices.sls:routerid: 66
prod/keepalived/elk-haproxy.sls:routerid: 67
stage/keepalived/webservices.sls:routerid: 55
stage/keepalived/elk-haproxy.sls:routerid: 57
</code>

I'm sure you'll wonder why I didn't include the current keepalived state here, instead of writing my own. The simple answer is, it needs to be refactored, and I didn't want to do that as part of this sprint. Can't boil the ocean, man.

Before you proceed, you'll need to do the following:

- git add dev/docker-swarm/gear-docker-ce-swarm.sls
- git commit && git push
- log on to zero, become root
- cd /srv/pillars && git pull

## Configure states/top.sls for Highstate
<code>
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
</code>

Don't forget to commit & push top.sls back to the master branch.

## Set Up Grain Data
Next, you'll want to configure the grains appropriately. Since this is how we're targeting highstate and pillar data with grains, this is important.

Remember the notes you made earlier with the minion ID's that salt-cloud built? You'll need them now.

Set the main role grain, as well as the PXT, across the entire swarm:

<code>
salt -L 8463b7fcb024,d2c5ab276b1d,8f71b0b907ee,7dffc38d5dc4,74a204b355c4 grains.append roles docker-ce-swarm
</code>
<code>
salt -L 8463b7fcb024,d2c5ab276b1d,8f71b0b907ee,7dffc38d5dc4,74a204b355c4 grains.setval pxt gear
</code>

Pick a minion to be swarm master:

<code>
salt 8463b7fcb024 grains.append roles swarm-master
</code>

Next, pick a minion to be swarm manager:

<code>
salt d2c5ab276b1d grains.append roles swarm-manager
</code>

Finally, configure each of the worker nodes:

<code>
salt -L 8f71b0b907ee,7dffc38d5dc4,74a204b355c4 grains.append roles swarm-worker
</code>

## verify pillar data
<code>
salt -C 'G@pxt:gear and G@roles:docker-ce-swarm and G@roles:swarm-master and G@env:dev' pillar.items
</code>

If after running this command you see the keepalived and docker items you put in the pillar file, congrats! It's working as expected.

## deploy the master node
<code>
salt -C 'G@pxt:gear and G@roles:docker-ce-swarm and G@roles:swarm-master and G@env:dev' state.highstate
</code>

## Get tokens and IP addresses to populate pillar data
<code>
salt -C 'G@pxt:gear and G@env:dev and G@roles:docker-ce-swarm and G@roles:swarm-master' cmd.run 'docker swarm join-token manager -q'
</code>
</code>
salt -C 'G@pxt:gear and G@env:dev and G@roles:docker-ce-swarm and G@roles:swarm-master' cmd.run 'docker swarm join-token worker -q'
</code>
<code>
salt -C 'G@pxt:gear and G@roles:docker-ce-swarm and G@roles:swarm-master and G@env:dev' grains.item ipv4:0
</code>

Take the values returned (strings starting with SWMTKN) and paste them into the appropriate pillars. Don't mix up the manager and worker tokens in the pillar.

A note about the IP address... make sure that the value returned from ipv4:0 isn't the VIP, and also isn't one of the Docker IP addresses (starting with 172.17 or 172.19). I'm not 100% sure that Salt always returns the actual interface IP address first.

## Deploy Manager Nodes
<code>
salt -C 'G@pxt:gear and G@roles:docker-ce-swarm and G@roles:swarm-manager and G@dev:dev' state.highstate
</code>

## Deploy Worker Nodes
<code>
salt -C 'G@pxt:gear and G@roles:docker-ce-swarm and G@roles:swarm-worker and G@env:dev' state.highstate
</code>

# Validate Deployment
<code>
salt -C 'G@pxt:gear and G@roles:docker-ce-swarm and G@roles:swarm-master and G@env:dev' cmd.run 'docker node ls'
</code>

You will see output like this:

<code>
m-7a4b57105eb4.localdev:
    ID                            HOSTNAME                  STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
    uhysl8rqy5taeequ8uuykrm67 *   m-7a4b57105eb4.localdev   Ready               Active              Leader              18.06.0-ce
    lpzzq4b3lmuml943rnmn8ai64     m-7d6b6394b038.localdev   Ready               Active                                  18.06.0-ce
    lapqw1x9v6gzsmbfmjl8v4um4     m-8b103504d842.localdev   Ready               Active                                  18.06.0-ce
    sgx6v5patsul7cb9uedubbdnh     m-2382de833121.localdev   Ready               Active                                  18.06.0-ce
    al04l2n53wn045apejzbj6drp     m-b91c5fdef91f.localdev   Ready               Active              Reachable           18.06.0-ce
</code>

You'll also want to make sure Traefik is running:

<code>
salt -C 'G@pxt:gear and G@roles:docker-ce-swarm and G@roles:swarm-master and G@env:dev' cmd.run 'docker service ls'
</code>

Here is the expected output:

<code>
m-7a4b57105eb4.localdev:
    ID                  NAME                MODE                REPLICAS            IMAGE               PORTS
    vvtfz0h8ecz4        traefik             replicated          1/1                 traefik:latest      *:80->80/tcp, *:8080->8080/tcp
</code>
