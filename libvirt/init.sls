{% if grains['os_family'] in [ 'RedHat', 'Rocky' ] %}
{% if grains.get('osmajorrelease', '') == 8 %}
libvirt-dnf-module:
  cmd.run:
    - name: dnf -y module install virt
    - unless: sudo dnf module --installed list | grep -qw virt
libvirt:
  pkg.installed:
    - pkgs:
        - cockpit
        - cockpit-machines
        - virt-install
        - libguestfs-tools-c
  service.running:
    - name: libvirtd
    - require:
      - pkg: libvirt
      - cmd: libvirt-dnf-module
cockpit-service:
  service.running:
    - name: cockpit.socket
    - require:
      - pkg: libvirt
{% endif %} # osmajorrelease end if
{% elif grains.get('os_family', '') == 'Debian' %}
libvirt:
  pkg.installed:
    - pkgs:
        - libvirt-daemon-system
        - libvirt-daemon
        - libguestfs-tools
        - virtinst
        - python3-libvirt
        - libosinfo-bin
        - cloud-image-utils
        - cockpit
        - cockpit-machines
        - bridge-utils
        - nfs-common
  service.running:
    - name: libvirtd
    - require:
      - pkg: libvirt
{% endif %} # grains os_family end if

# drop gagamba's public key in root ssh authorized_keys
sshkeys:
  ssh_auth.present:
    - user: root
    - enc: ssh-rsa
    - comment: gagamba
    - names:
      - AAAAB3NzaC1yc2EAAAADAQABAAABgQDtib+50/6UVY5n/EUnj/AU8W0a5Nxw4ynbDtjrXb4UVwBIKdTkPeTE/N1ycz2235FpPG75Z3tJVovgnCv0wI8MwUpJC0aoaeLVD6XdDuo0I7al+8vjTvQBfGZr6uSaW7Dpz86igRQQjOeNdPhbFigZDdJh8v1OrIqDSZkcCwnqS+KRu6KTFCMWjZ21cGC9NFWJB8FX8zk1NJnyB7z8pXOhXqBdU3qkXA+Ile/pC0hkLzdSofVrAyhfJYWdbz+yXK9NpjbeFtvkHf0HftNiAPdj+XMw6uWXo88DOc7tZFfgIhmae+380wumF3QbCy7T2rsvhA6VswJk2Ud7UbSWDlIUQUgkBEKf28ruEHXlxEKWMCW1acmjSClzIoO+Gp1MBRawqBs8VQ3dY/8V8AHMPvrsWaIZtvC5KVyMOVrnoNJ1YVSnEgyG4HS+Vn+p1ZNcHwStp4JodiSkEUeA2Xf1Lyi1XPG10ASZKj0Qdv7h9juQIiZC3qgFYJWSWEFFkapfD7k=

cloud_img_mount:
  mount.mounted:
    - name: /mnt/cloudimg
    - device: lancah.xthorsworld.com:/storage/cloud-images
    - mkmnt: True
    - fstype: nfs 

/usr/local/bin/new_vm.sh:
  file.managed:
    - source: salt://libvirt/files/new_vm.sh
    - user: root
    - group: root
    - mode: 755

/usr/local/bin/prep_base_images.sh:
  file.managed:
    - source: salt://libvirt/files/prep_base_images.sh
    - user: root
    - group: root
    - mode: 755

# TODO: manage networking with saltstack: https://docs.saltproject.io/en/latest/ref/states/all/salt.states.network.html
