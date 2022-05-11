{% if grains['os_family'] in [ 'RedHat', 'Rocky' ] %}
{% if grains.get('osmajorrelease', '') == 8 %}
libvirt-dnf-module:
  cmd.run:
    - name: dnf module install virt
    - unless: sudo dnf module --installed list | grep -qw virt
libvirt:
  pkg.installed:
    - pkgs:
        - cockpit
        - cockpit-machines
        - virt-install
  service.running:
    - name: libvirtd
    - require:
      - pkg: libvirt
      - cmd: libvirt-dnf-module
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

# TODO: template out /etc/network/interfaces? Not sure if it'll work

# also - mount pavuk NFS share so cloud-images can be copied from there instead of using up storage locally

# also also - new_vm.sh 