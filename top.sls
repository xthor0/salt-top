base:
##### OS specific states
  'kernel:linux':
    - match: grain
    - states.linuxos
##### Begin Roles ######
  'G@roles:docker':
    - roles.dockerinst
  'G@roles:yumrepo':
    - centos.roles.yumrepo
  'G@roles:icinga2server':
    - centos.states.roles.icinga2
