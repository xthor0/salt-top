# install packages plus bash-completion files for Docker CE

# only works on CentOS 7 right now :)
{% if grains.get('os', '') == 'CentOS' and grains.get('osmajorrelease', '') == 7 %}

docker-ce-repo:
    pkgrepo.managed:
        - humanname: Docker CE Stable - $basearch
        - baseurl: https://download.docker.com/linux/centos/7/$basearch/stable
        - gpgcheck: 1
        - gpgkey: https://download.docker.com/linux/centos/gpg
        - failovermethod: priority

install-docker-ce-packages:
    pkg.installed:
        - pkgs:
            - docker-ce
            - bash-completion
            - bash-completion-extras
    require:
        - pkgrepo: docker-ce-repo

{#

2018.08.03 - I got sick of the frequent hash changes, so we just download this with curl. Done.

# I need to build a defaults file and import it - this hash changes a LOT and it should be controlled from a pillar value
install-bash-completion-docker:
    file.managed:
        - source: https://raw.githubusercontent.com/docker/docker-ce/master/components/cli/contrib/completion/bash/docker
        - source_hash: 767a9de833ec8b292a368c628f3d560ae89eaaea0fc672d251e97c053b2fa268
        - name: /etc/bash_completion.d/docker.sh
        - mode: 644
        - user: root
        - group: root

#}

# this is probably not good security. An alternative is updating the hash in the pillar, like I indicated above. I'm lazy, though.
install-bash-completion-docker:
  cmd.run:
    - name: curl -s -L https://raw.githubusercontent.com/docker/docker-ce/master/components/cli/contrib/completion/bash/docker -o /etc/bash_completion.d/docker.sh
    - unless: curl -s -L https://raw.githubusercontent.com/docker/docker-ce/master/components/cli/contrib/completion/bash/docker -o /tmp/docker.sh && cmp -s /etc/bash_completion.d/docker.sh /tmp/docker.sh; retval=$?; if test $retval -eq 0 && rm -f /tmp/docker.sh; exit $retval

# apparently /etc/docker isn't created till the service runs once, so let's make it now
/etc/docker:
    file.directory:
        - mode: 755
        - user: root

# the default network (172.17.0.0/16) conflicts with some of CHG's networks - so we change it
# TODO: this really just ADDS a default network, it doesn't disable the old one, it still has an interface on the box!
/etc/docker/daemon.json:
    file.managed:
        - source: salt://docker-ce/files/daemon.json
        - user: root
        - mode: 644

run-docker-services:
    service.running:
        - name: docker
        - enable: True
        - watch:
            - file: /etc/docker/daemon.json
    require:
        - pkgrepo: docker-ce-repo
        - pkg: install-docker-ce-packages
        - file: /etc/docker/daemon.json

{% endif %}
