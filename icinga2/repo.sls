# Install repo for icinga2
{% if grains.get('os', '') == 'CentOS' %}
icinga-stable-release:
  pkgrepo.managed:
    - humanname: ICINGA (stable release for epel)
    - baseurl: http://packages.icinga.com/epel/$releasever/release/
    - gpgcheck: 1
    - gpgkey: file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ICINGA

# manage in GPG key for this repository
/etc/pki/rpm-gpg/RPM-GPG-KEY-ICINGA:
    file.managed:
        - source: https://packages.icinga.com/icinga.key
        - source_hash: be677e07972ed57b99ffc2fd211379ac11b9c6a7c8d9460086b447b96b0a82bb
        - mode: 644
        - user: root
        - group: root

# icinga2 needs epel and scl
install-icinga2-prereqs:
    pkg.installed:
        - pkgs:
            - epel-release
            - centos-release-scl
{% endif %}

{% if grains.get('os_family', '') == 'Debian' %}
{% set ocn = grains.get('oscodename', '') %}
{% set dist = 'icinga-{0} main'.format(ocn) %}
icinga2_repo:
  pkgrepo.managed:
    - humanname: icinga2_official
    - name: deb http://packages.icinga.org/debian {{ dist }}
    - file: /etc/apt/sources.list.d/icinga.list
    - key_url: http://packages.icinga.org/icinga.key
{% endif %}