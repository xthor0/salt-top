#!/bin/bash

image_dir=/mnt/cloudimg
target_dir=/var/lib/libvirt/images

# default options
flavor="rocky8"
ram=2
vcpus=1
storage=10
network=54

# display usage
function usage() {
  echo "`basename $0`: Deploy a cloud-init templated libvirt VM."
  echo "Usage:

`basename $0` -h <hostname of VM> -f <flavor> -t <network> [ -i <ip address> ]

where <ip address> is in x.x.x.x/xx notation"

  exit 255
}

function bad_taste() {
  echo "Error: no flavor named ${flavor} -- exiting."
  exit 255
}

# check if tools required by this script are installed
for x in virt-sysprep mcopy virt-install; do
  which ${x} >& /dev/null 
  if [ $? -ne 0 ]; then
    echo "ERROR: Missing ${x} -- please install."
    exit 255
  fi
done

# get command-line args
while getopts "h:f:t:s:p:r:i:m" OPTION; do
  case $OPTION in
    h) host_name=${OPTARG};;
    f) flavor=${OPTARG};;
    t) network=${OPTARG};;
    s) storage=${OPTARG};;
    p) vcpus=${OPTARG};;
    r) ram=${OPTARG};;
    i) ipaddr=${OPTARG};;
    m) salted="1";;
    *) usage;;
  esac
done

# make sure we have necessary variables
if [ -z "${host_name}" ]; then
  usage
fi

if [ ${#} -eq 0 ]; then
  usage
fi

# regex to validate network
if [[ ${network} =~ ^(1|5[0-5])$ ]]; then
else
  echo "Bad network: ${network}"
  usage
fi

if [ ${network} -eq 1 ]; then
  ifname="br0"
else
  ifname="br-vlan${network}"
fi

# ensure that hostname passed for vlan54 ends in .lab
if [ "${network}" -eq 54 ]; then
  if [[ ${host_name} =~ .lab$ ]]; then
    echo "Hostname ${host_name} validated."
  else
    echo "ERROR: Hostname ${host_name} invalid with vlan id 54."
    usage
  fi
fi

# RAM is tricky, don't let me be stupid and specify more RAM than I have. Capping out at 16.
if [ "${ram}" -gt 16 ]; then
    echo "Um, no, you can't have more than 16GB RAM."
    usage
else
    memory=$((${ram} * 1024))
fi

# turn the flavor variable into a location for images
case ${flavor} in
  bionic) image="${image_dir}/standard/bionic.qcow2"; salted_image="${image_dir}/salted/bionic.qcow2"; variant="ubuntu18.04";;
  focal) image="${image_dir}/standard/focal.qcow2"; salted_image="${image_dir}/salted/focal.qcow2"; variant="ubuntu20.04";;
  jammy) image="${image_dir}/standard/jammy.qcow2"; salted_image="${image_dir}/salted/jammy.qcow2"; variant="ubuntu20.04";;
  centos7) image="${image_dir}/standard/centos7.qcow2"; salted_image="${image_dir}/salted/centos7.qcow2"; variant="centos7.0";;
  alma8) image="${image_dir}/standard/almalinux8.qcow2"; salted_image="${image_dir}/salted/almalinux8.qcow2"; variant="centos8";;
  rocky8) image="${image_dir}/standard/rocky8.qcow2"; salted_image="${image_dir}/salted/rocky8.qcow2"; variant="centos8";;
  buster) image="${image_dir}/standard/buster.qcow2"; salted_image="${image_dir}/salted/buster.qcow2"; variant="debian10";;
  bullseye) image="${image_dir}/standard/bullseye.qcow2"; salted_image="${image_dir}/salted/bullseye.qcow2"; variant="debian10";;
  *) bad_taste;;
esac

# network needs to be validated - expected to be a valid bridge interface name
test -L /sys/class/net/${ifname}
if [ $? -ne 0 ]; then
  echo "${ifname} for network ${network} is not a valid network interface - exiting."
  exit 255
fi

# variablize (is that a word?) this so I don't have to type it again in this script
disk_image=${target_dir}/${host_name}.qcow2
ci_image=${target_dir}/${host_name}-ci.qcow2

# if salted flag is passed, swap out image for salted_image
if [ -n "${salted}" ]; then
  image="${salted_image}"
fi

# I HAVE been known to forget to create a flavor on the VM host (with virt-sysprep), so we should... check that.
test -f ${image}
if [ $? -ne 0 ]; then
  echo "Oops. Missing disk image for ${flavor}. Exiting..."
  exit 255
fi

# is this VM already defined on the hypervisor?
test -f /etc/libvirt/qemu/${vmname}.xml
if [ $? -eq 0 ]; then
  echo "VM ${host_name} already defined -- exiting."
  exit 255
fi

# does this disk image already exist? Overwriting a running domain's disk, that's bad news, so don't do it.
test -f ${disk_image}
if [ $? -eq 0 ]; then
  echo "${disk_image} exists already -- exiting."
  exit 255
fi

# does the FQDN resolve and ping?
ping -q -c1 -w1 ${hostname} >& /dev/null
if [ $? -eq 0 ]; then
  echo "Error: ${hostname} is alive and responding to pings. Exiting."
  exit 255
fi

# network validation
# maybe I should stop asking for a NIC name above, and start referencing VLAN IDs only. something to think about.
if [ -n "${ipaddr}" ]; then
  ip_octet=$(echo ${ipaddr} | cut -d \. -f 3)
  if [ ${network} -ne ${ip_octet} ]; then
    echo "Error: IP address you specified does not match VLAN. Exiting."
    exit 255
  fi

  ping -q -c1 -w1 $(echo ${ipaddr} | cut -d \/ -f 1) >& /dev/null
  if [ $? -eq 0 ]; then
    echo "Error: ${ipaddr} is alive and responding to pings. Exiting."
    exit 255
  fi
fi

# create a temp dir for user-data and meta-data files
tmpdir=$(mktemp -d)

# for virt-sysprep --copy-in to work correctly, the directory name MUST be nocloud
mkdir ${tmpdir}/nocloud
if [ $? -ne 0 ]; then
  echo "Error creating ${tmpdir}/nocloud -- exiting."
  exit 255
fi

# copy the disk image to the right location, and then resize it
echo "Copying ${image} to ${disk_image} and resizing to ${storage}G..."
sudo cp ${image} ${disk_image} && sudo qemu-img resize ${disk_image} ${storage}G
if [ $? -ne 0 ]; then
  echo "Something went wrong either with copying the image, or resizing it -- exiting."
  exit 255
fi

# create a meta-data file
cat << EOF > ${tmpdir}/nocloud/meta-data
instance-id: 1
local-hostname: ${host_name}
EOF

# create user-data file
cat << EOF > ${tmpdir}/nocloud/user-data
#cloud-config
users:
    - name: root
      plain_text_passwd: resetm3n0w
      lock_passwd: false
      ssh_authorized_keys:
        - ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJ4OwD4MqSuGlqmJsMY6SCEY7Js4n1rS+altYALKSqN/XOlxEGXOkyrfrlgZ99jaj7IDYeVYbDZN4fMUlTYjWGA= caaro@secretive.caaro.local
        - ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBM0iPdemESmJ/Dgs/Xg1apaSVl8x27IP7FJcwRZa9BKQ6nNjFMhVVLNpvXfeAV8iq09k86/o0McXpR3T/Li2Kmk= hala@secretive.hala.local
        - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDJNEonif7PNwf6DFR1/nqU9phsdgGFzSMO8EWkD3caLDoAs8/TvnQ+iwvzcox8yAKpU6uIaungjEil3LdiScQSB6yJXB++/4pO827+8AkYmo3seKWkk7LTpHuW8zPc8dbsre1uBCuV7VoAeMJkml1O4wwYooJVt55Nfj2qwVqbg7EMyO9C0KN6X85GLOV1WI3Oa95gmwJvnhg3sbFFW0l4DddsU7rmqzftHyfNzgg/X7VbBa1GzAhhr+EmCh19r8msAgVj6odKutk9/Z8bvE9kUH1+4c0WkdpeVOkdcacluRFZ3lrb9+UTdZ/H1ebTEKbpp/wg7eGT+pO4JcFNrqSqyiVkcBjYi6u8rzCJ3KjSy9718wwWM+y3m/NW0gCuuKTQnCeNqe+b1SUvvPZqGvMykGxStHszkVSDjuGZlu9IsP59ALSWDOvTkybu+fIONw4EmItrdPmGqGHYuA0tTzwLh4QqPr8fvF8sZaVislzHaPWzwaafKc2QpxjoABpfXdU= xthor@spindel.xthorsworld.com
    - name: xthor
      shell: /bin/bash
      plain_text_passwd: p@ssw0rd
      lock_passwd: false
      sudo: ALL=(ALL) NOPASSWD:ALL
      ssh_authorized_keys:
        - ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJ4OwD4MqSuGlqmJsMY6SCEY7Js4n1rS+altYALKSqN/XOlxEGXOkyrfrlgZ99jaj7IDYeVYbDZN4fMUlTYjWGA= caaro@secretive.caaro.local
        - ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBM0iPdemESmJ/Dgs/Xg1apaSVl8x27IP7FJcwRZa9BKQ6nNjFMhVVLNpvXfeAV8iq09k86/o0McXpR3T/Li2Kmk= hala@secretive.hala.local
        - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDJNEonif7PNwf6DFR1/nqU9phsdgGFzSMO8EWkD3caLDoAs8/TvnQ+iwvzcox8yAKpU6uIaungjEil3LdiScQSB6yJXB++/4pO827+8AkYmo3seKWkk7LTpHuW8zPc8dbsre1uBCuV7VoAeMJkml1O4wwYooJVt55Nfj2qwVqbg7EMyO9C0KN6X85GLOV1WI3Oa95gmwJvnhg3sbFFW0l4DddsU7rmqzftHyfNzgg/X7VbBa1GzAhhr+EmCh19r8msAgVj6odKutk9/Z8bvE9kUH1+4c0WkdpeVOkdcacluRFZ3lrb9+UTdZ/H1ebTEKbpp/wg7eGT+pO4JcFNrqSqyiVkcBjYi6u8rzCJ3KjSy9718wwWM+y3m/NW0gCuuKTQnCeNqe+b1SUvvPZqGvMykGxStHszkVSDjuGZlu9IsP59ALSWDOvTkybu+fIONw4EmItrdPmGqGHYuA0tTzwLh4QqPr8fvF8sZaVislzHaPWzwaafKc2QpxjoABpfXdU= xthor@spindel.xthorsworld.com
timezone: America/Denver
package_upgrade: true
runcmd:
    - touch /etc/cloud/cloud-init.disabled
EOF

if [ -n "${ipaddr}" ]; then
  # we expect this IP address to be provided in x.x.x.x/xx form
  # TODO: regex to check it
    gateway="10.200.${network}.1"
  if [ ${network} -eq 54 ]; then
    search="xthorsworld.lab"
  else
    search="xthorsworld.com"
  fi

	if [[ "${variant}" == centos* ]]; then
	cat << EOF > ${tmpdir}/nocloud/network-config
version: 2
ethernets:
  eth0:
    match:
      name: "eth*"
    addresses:
    - ${ipaddr}
    gateway4: ${gateway}
    nameservers:
      search: [${search}]
      addresses: [${gateway}]
EOF
	else
  cat << EOF > ${tmpdir}/nocloud/network-config
version: 2
ethernets:
  zz-all-en:
    match:
      name: "en*"
    addresses:
    - ${ipaddr}
    gateway4: ${gateway}
    nameservers:
      search: [${search}]
      addresses: [${gateway}]
  zz-all-eth:
    match:
      name: "eth*"
    addresses:
    - ${ipaddr}
    gateway4: ${gateway}
    nameservers:
      search: [${search}]
      addresses: [${gateway}]
EOF
	fi
fi

# virt-sysprep and inject user-data and meta-data
sudo virt-sysprep -a ${disk_image} --hostname ${host_name} --network --update --run-command 'mkdir -p /var/lib/cloud/seed' --copy-in ${tmpdir}/nocloud:/var/lib/cloud/seed --selinux-relabel
if [ $? -ne 0 ]; then
  echo "virt-sysprep exited with a non-zero status -- exiting."
  exit 255
fi

# kick off virt-install
echo "Installing VM ${host_name}..."
sudo virt-install --virt-type kvm --name ${host_name} --ram ${memory} --vcpus ${vcpus} \
  --os-variant ${variant} --network=bridge=${ifname},model=virtio --graphics vnc \
  --disk path=${disk_image},cache=writeback \
  --noautoconsole --import

# cleanup
rm -rf ${tmpdir}

exit 0
