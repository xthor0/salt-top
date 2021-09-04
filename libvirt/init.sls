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
  service.running:
    - name: libvirtd
    - require:
      - pkg: libvirt
