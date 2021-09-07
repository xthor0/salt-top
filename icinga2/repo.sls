# Install repo for icinga2
install-icinga2-prereqs:
  pkg.installed:
    - pkgs:
{% if grains['os_family'] in [ 'RedHat', 'Rocky' ] %}
      - epel-release
{% if grains.get('osmajorrelease', '') == 7 %}
      - centos-release-scl
{% endif %}
{% elif grains.get('os_family', '') == 'Debian' %}
      - gnupg1
{% endif %}

icinga-stable-release:
  pkgrepo.managed:
{% if grains['os_family'] in [ 'RedHat', 'Rocky' ] %}
    - humanname: ICINGA (stable release for epel)
    - baseurl: http://packages.icinga.com/epel/$releasever/release/
    - gpgcheck: 1
    - gpgkey: file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ICINGA
{% elif grains.get('os_family', '') == 'Debian' %}
{% set ocn = grains.get('oscodename', '') %}
{% set dist = 'icinga-{0} main'.format(ocn) %}
    - humanname: icinga2_official
    - name: deb https://packages.icinga.org/debian {{ dist }}
    - file: /etc/apt/sources.list.d/icinga.list
    - key_url: https://packages.icinga.com/icinga.key
{% endif %}
    - require:
      - pkg: install-icinga2-prereqs

{% if grains['os_family'] in [ 'RedHat', 'Rocky' ] %}
# manage in GPG key for this repository
/etc/pki/rpm-gpg/RPM-GPG-KEY-ICINGA:
    file.managed:
        - source: https://packages.icinga.com/icinga.key
        - source_hash: be677e07972ed57b99ffc2fd211379ac11b9c6a7c8d9460086b447b96b0a82bb
        - mode: 644
        - user: root
        - group: root
{% endif %}
