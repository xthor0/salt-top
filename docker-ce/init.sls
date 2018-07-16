# install packages plus bash-completion files for Docker CE

# only works on CentOS 7 right now :)
{% if grains.get('os', '') == 'CentOS' and grains.get('osmajorrelease', '') == '7' %}

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

install-bash-completion-docker:
    file.managed:
        - source: https://raw.githubusercontent.com/docker/docker-ce/master/components/cli/contrib/completion/bash/docker
        - source_hash: 1815000058cb44c4f87373a72d5abef328c95e1729a3f0be178371467fab110b
        - name: /etc/bash_completion.d/docker.sh
        - mode: 644
        - user: root
        - group: root

# apparently /etc/docker isn't created till the service runs once, so let's make it now
/etc/docker:
    file.directory:
        - mode: 755
        - user: root

# the default network (172.17.0.0/16) conflicts with some of CHG's networks - so we change it
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
