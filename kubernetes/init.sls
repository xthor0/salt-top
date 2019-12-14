{% if grains.get('os_family', '') == 'RedHat' %}
kubernetes-yum-repo:
    pkgrepo.managed:
        - humanname: Kubernetes
        - baseurl: https://packages.cloud.google.com/yum/repos/kubernetes-el7-$basearch
        - gpgcheck: 1
        - repo_gpgcheck: 1
        - gpgkey: https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg https://packages.cloud.google.com/yum/doc/yum-key.gpg

install-kubes-packages:
    pkg.installed:
        - pkgs:
            - docker
            - kubeadm

start-docker-service:
    service.running:
        - name: docker
        - enable: True

start-kubelet-service:
    service.running:
        - name: kubelet
        - enable: True

k8master-hosts:
    host.present:
        - ip: 
            - 10.187.88.109
        - names:
            - k8master.lab

k8worker1-hosts:
    host.present:
        - ip: 
            - 10.187.88.188
        - names:
            - k8worker1.lab

k8worker2-hosts:
    host.present:
        - ip: 
            - 10.187.88.156
        - names:
            - k8worker2.lab

net.bridge.bridge-nf-call-iptables:
  sysctl.present:
    - value: 1

permissive:
    selinux.mode

{% if 'master' in grains.get('id', '') %}
kubectl-bash-completion:
    cmd.run:
        - name: kubectl completion bash >/etc/bash_completion.d/kubectl
        - unless: test -f /etc/bash_completion.d/kubectl

# end master grain id check
{% endif %}

# end os_family grain check
{% endif %}