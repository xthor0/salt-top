# we need some pkg.installeds here, but I haven't come up with that list yet
# for now, just salt-minion and the repo it comes from

# centos systems
{% if grains.get('os', '') == 'CentOS' %}
salt-latest:
  pkgrepo.managed:
    - humanname: SaltStack Latest Release Channel for RHEL/Centos $releasever
    - baseurl: https://repo.saltstack.com/yum/redhat/7/$basearch/latest
    - gpgcheck: 1
    - gpgkey: file:///etc/pki/rpm-gpg/saltstack-signing-key
    - failovermethod: priority

/etc/pki/rpm-gpg/saltstack-signing-key:
  file.managed:
    - source: salt://linuxos/files/etc/pki/rpm-gpg/saltstack-signing-key
    - user: root
    - group: root
    - mode: 644
{% endif %}

{% if grains.get('os_family', '') == 'Debian' %}
salt-latest:
  pkgrepo.absent:
    - ppa: saltstack/salt
{% endif %}

install-salt-minion-pkg:
  pkg.installed:
    - name: salt-minion
    - require: 
      - pkgrepo: salt-latest

/etc/salt/minion:
  file.managed:
    - source: salt://linuxos/files/etc/salt/minion
    - user: root
    - group: root
    - mode: 600

salt-minion-service:
  service.running:
    - name: salt-minion
    - enable: True
    - watch:
      - file: /etc/salt/minion
