Upgrade Salt-Minion:
  cmd.run:
    - name: |
        exec 0>&- # close stdin
        exec 1>&- # close stdout
        exec 2>&- # close stderr
        nohup /bin/sh -c 'salt-call --local pkg.install salt-minion && salt-call --local service.restart salt-minion' &
    - onlyif: "[[ $(salt-call --local pkg.upgrade_available salt-minion 2>&1) == *'True'* ]]" 
