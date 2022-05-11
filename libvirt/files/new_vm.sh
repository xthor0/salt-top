#!/bin/bash

image_dir=/mnt/cloudimg
target_dir=/var/lib/libvirt/images

# default options
flavor="rocky8"
ram=2
vcpus=1
storage=10

# display usage
function usage() {
	echo "`basename $0`: Deploy a cloud-init templated libvirt VM."
	echo "Usage:

`basename $0` -h <hostname of VM> -f <flavor> -t <network>"

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
while getopts "h:f:t:s:p:r:m" OPTION; do
	case $OPTION in
		h) host_name=${OPTARG};;
		f) flavor=${OPTARG};;
		t) network=${OPTARG};;
		s) storage=${OPTARG};;
		p) vcpus=${OPTARG};;
		r) ram=${OPTARG};;
		m) salted="1";;
		*) usage;;
	esac
done

# make sure we have necessary variables
if [ -z "${host_name}" -o -z "${network}" ]; then
	usage
fi

if [ ${#} -eq 0 ]; then
	usage
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
    bionic) image="${image_dir}/bionic-server-cloudimg-amd64.qcow2"; variant="ubuntu18.04";;
    focal) image="${image_dir}/focal-server-cloudimg-amd64.qcow2"; variant="ubuntu20.04";;
    centos7) image="${image_dir}/CentOS-7-x86_64-GenericCloud-2009.qcow2c"; variant="centos7.0";;
    almalinux8) image="${image_dir}/AlmaLinux-8-GenericCloud-latest.x86_64.qcow2"; variant="centos8";;
    rocky8) image="${image_dir}/Rocky-8-GenericCloud-8.5-20211114.2.x86_64.qcow2"; variant="centos8";;
    fedoracoreos35) image="${image_dir}/fedora-coreos-35.20211029.3.0-qemu.x86_64.qcow2"; variant="fedora-coreos-stable";;
    fedora35) image="${image_dir}/Fedora-Cloud-Base-35-1.2.x86_64.qcow2"; variant="fedora33";;
    debian10) image="${image_dir}/debian-10-generic-amd64.qcow2"; variant="debian10";;
    debian11) image="${image_dir}/debian-11-generic-amd64.qcow2"; variant="debian10";;
    *) bad_taste;;
esac

# network needs to be validated - expected to be a valid bridge interface name
test -L /sys/class/net/${network}
if [ $? -ne 0 ]; then
	echo "${network} is not a valid network interface - exiting."
	exit 255
fi

# variablize (is that a word?) this so I don't have to type it again in this script
disk_image=${target_dir}/${host_name}.qcow2
ci_image=${target_dir}/${host_name}-ci.qcow2

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

# copy the disk image to the right location, and then resize it
echo "Copying ${image} to ${disk_image} and resizing to ${storage}G..."
sudo cp ${image} ${disk_image} && sudo qemu-img resize ${disk_image} ${storage}G
if [ $? -ne 0 ]; then
	echo "Something went wrong either with copying the image, or resizing it -- exiting."
	exit 255
fi

# virt-sysprep to set a few things
echo "Updating host image for ${host_name}..."
# I really wish I didn't have 2 different freaking commands here, but it's not working right otherwise
if [ -z "${salted}" ]; then
	sudo virt-sysprep -a ${disk_image} --hostname ${host_name} --network --update --selinux-relabel
else
	sudo virt-sysprep -a ${disk_image} --hostname ${host_name} --network --update --selinux-relabel --run-command "curl -L https://bootstrap.saltstack.com -o /tmp/install_salt.sh && bash /tmp/install_salt.sh -P -X"
fi
if [ $? -ne 0 ]; then
	echo "Something went wrong with virt-sysprep -- exiting."
	exit 255
fi

# virt-install older than 3.2 (I think) doesn't support --cloud-init option, which is a bummer
# TODO: add a check for that!
#sudo virt-install --virt-type kvm --name ${host_name} --ram ${memory} --vcpus ${vcpus} \
#	--os-variant ${variant} --network=bridge=${network},model=virtio --graphics vnc \
#	--disk path=${disk_image},cache=writeback \
#	--cloud-init root-password-generate=no,disable=on,user-data=/home/xthor/ci/user-data,meta-data=/tmp/meta-data \
#	--noautoconsole --import

# create a meta-data file
cat << EOF > /tmp/meta-data
instance-id: 1
local-hostname: ${host_name}
EOF

# create user-data file
cat << EOF > /tmp/user-data
#cloud-config
users:
    - name: root
      passwd: resetm3n0w
      ssh_authorized_keys:
        - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDSUppn5b2njEQSw8FHqyZ0OZiPD14wEejulwnQ7gxLdQYJEqXMleHx4u/9ff3/jDXoGaBFiT2LmUTnpMV8HSj4jsB4PCoFAbq4XnlnwyBx7va/8LQOMdKsjF5W6peO+DYKh+ow9YaJvctzGPebkkNvhI0YFhZod58uoO7lyTnQXkMm8DXl6q7WhNfsZZiwr7tXicUZojU0msMiDpX1JvhGow+mKym0U/6cMgozypYfNbQ2PVkfNnadslp29O5Mfd5X4U+cbACa1sUYYqOT2Zz8C4t5QFXRY1LNokmRbcqbO01bygbE4S2TDnvRz+XZmfZTuw9MMgp7JPfo6cOfDYKf xthor
    - name: xthor
      shell: /bin/bash
      passwd: p@ssw0rd
      lock_passwd: false
      sudo: ALL=(ALL) NOPASSWD:ALL
      ssh_authorized_keys:
        - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDSUppn5b2njEQSw8FHqyZ0OZiPD14wEejulwnQ7gxLdQYJEqXMleHx4u/9ff3/jDXoGaBFiT2LmUTnpMV8HSj4jsB4PCoFAbq4XnlnwyBx7va/8LQOMdKsjF5W6peO+DYKh+ow9YaJvctzGPebkkNvhI0YFhZod58uoO7lyTnQXkMm8DXl6q7WhNfsZZiwr7tXicUZojU0msMiDpX1JvhGow+mKym0U/6cMgozypYfNbQ2PVkfNnadslp29O5Mfd5X4U+cbACa1sUYYqOT2Zz8C4t5QFXRY1LNokmRbcqbO01bygbE4S2TDnvRz+XZmfZTuw9MMgp7JPfo6cOfDYKf xthor
timezone: America/Denver
package_upgrade: true
runcmd:
    - touch /etc/cloud/cloud-init.disabled
EOF

# create ci image
# TODO: salt-ify the user-data file... somehow
# jesus, cloud-localds is only a Debian thing...
#sudo cloud-localds -H ${host_name} -d qcow2 ${ci_image} /home/xthor/ci/user-data
dd if=/dev/zero of=${ci_image} count=1 bs=1M && mkfs.vfat -n cidata ${CLOUDINIT_IMG}
if [ $? -eq 0 ]; then
	# stuff in the user-data and meta-data files
	mcopy -i ${ci_image} /tmp/meta-data :: && mcopy -i ${ci_image} /tmp/user-data ::
	if [ $? -ne 0 ]; then
		echo "Error: could not mcopy user-data or meta-data to ${ci_image}. Exiting."
		exit 255
	fi
else
	echo "Error: could not create ${ci_image}. Exiting."
	exit 255
fi

# kick off virt-install
echo "Installing VM ${host_name}..."
sudo virt-install --virt-type kvm --name ${host_name} --ram ${memory} --vcpus ${vcpus} \
	--os-variant ${variant} --network=bridge=${network},model=virtio --graphics vnc \
	--disk path=${disk_image},cache=writeback \
	--disk path=${ci_image} \
	--noautoconsole --import

rm /tmp/meta-data /tmp/user-data
exit 0
