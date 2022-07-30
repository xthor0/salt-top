#!/bin/bash

image_dir=/mnt/cloudimg
target_dir=/var/lib/libvirt/images
cloud_init_url="http://10.200.55.5" # TODO: build a VM in DMZ, salt the motherfucker

# default options
flavor="bullseye"
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
test -L /sys/class/net/${network}
if [ $? -ne 0 ]; then
	echo "${network} is not a valid network interface - exiting."
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

# copy the disk image to the right location, and then resize it
echo "Copying ${image} to ${disk_image} and resizing to ${storage}G..."
sudo cp ${image} ${disk_image} && sudo qemu-img resize ${disk_image} ${storage}G
if [ $? -ne 0 ]; then
	echo "Something went wrong either with copying the image, or resizing it -- exiting."
	exit 255
fi

# update the OS to latest, and set the hostname. that way, when it first comes up, DHCP will use the right hostname.
sudo virt-sysprep -a ${disk_image} --hostname ${host_name} --network --update --selinux-relabel
if [ $? -ne 0 ]; then
	echo "virt-sysprep exited with a non-zero status -- exiting."
	exit 255
fi

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
      plain_text_passwd: resetm3n0w
      lock_passwd: false
      ssh_authorized_keys:
        - ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJ4OwD4MqSuGlqmJsMY6SCEY7Js4n1rS+altYALKSqN/XOlxEGXOkyrfrlgZ99jaj7IDYeVYbDZN4fMUlTYjWGA= caaro@secretive.caaro.local
        - ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBM0iPdemESmJ/Dgs/Xg1apaSVl8x27IP7FJcwRZa9BKQ6nNjFMhVVLNpvXfeAV8iq09k86/o0McXpR3T/Li2Kmk= hala@secretive.hala.local
    - name: xthor
      shell: /bin/bash
      plain_text_passwd: p@ssw0rd
      lock_passwd: false
      sudo: ALL=(ALL) NOPASSWD:ALL
      ssh_authorized_keys:
        - ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJ4OwD4MqSuGlqmJsMY6SCEY7Js4n1rS+altYALKSqN/XOlxEGXOkyrfrlgZ99jaj7IDYeVYbDZN4fMUlTYjWGA= caaro@secretive.caaro.local
        - ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBM0iPdemESmJ/Dgs/Xg1apaSVl8x27IP7FJcwRZa9BKQ6nNjFMhVVLNpvXfeAV8iq09k86/o0McXpR3T/Li2Kmk= hala@secretive.hala.local
timezone: America/Denver
package_upgrade: true
runcmd:
    - touch /etc/cloud/cloud-init.disabled
EOF

# create ci image
# sure would be nice if RHEL and their clones had cloud-localds! Or, hell, if virt-install supported --cloud-init (not till v3.2, sadly)
sudo dd if=/dev/zero of=${ci_image} count=1 bs=1M && sudo mkfs.vfat -n cidata ${ci_image}
if [ $? -eq 0 ]; then
	# stuff in the user-data and meta-data files
	sudo mcopy -i ${ci_image} /tmp/meta-data :: && sudo mcopy -i ${ci_image} /tmp/user-data ::
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

exit 0
