python3-pkgs:
  pkg.installed:
    - pkgs:
        - python3
        - python3-pip

{# 
    pip packages are crashing salt minion on bionic. fix it.
    also, why does the minion have salt master installed on it?
#}

pip-pingparsing:
    pip.installed:
        - name: pingparsing
        - bin_env: /usr/bin/pip3
        - require:
            - python3-pkgs

pip-netifaces:
    pip.installed:
        - name: netifaces
        - bin_env: /usr/bin/pip3
        - require:
            - python3-pkgs

/usr/local/bin/packetloss.py:
    file.managed:
        - source: salt://pipingcheck/files/packetloss.py
        - user: root
        - group: root
        - mode: 755
        - require:
            - python3-pkgs
            - pip-pipingcheck