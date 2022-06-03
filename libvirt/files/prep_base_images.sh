#!/bin/bash

# where are we storing all the images?
basedir="/storage/prep/base"

if ! [ -d "${basedir}" ]; then
    echo "The basedir variable does not exist as a directory. Exiting."
    exit 2555
fi

function download_and_verify() {
    pushd "${basedir}"

    popd
}

# Download all the images. Really only needs to be done once, as no matter how old the image is, virt-sysprep will update it.
# format: name qcow2_url checksum checksum_type
distros=(
    centos7="https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-2009.qcow2c https://cloud.centos.org/centos/7/images/sha256sum.txt sha256sum"
    rocky8="https://dl.rockylinux.org/pub/rocky/8.6/images/Rocky-8-GenericCloud.latest.x86_64.qcow2 https://dl.rockylinux.org/pub/rocky/8.6/images/CHECKSUM sha256sum"
    almalinux8="https://repo.almalinux.org/almalinux/8/cloud/x86_64/images/AlmaLinux-8-GenericCloud-latest.x86_64.qcow2 https://repo.almalinux.org/almalinux/8/cloud/x86_64/images/CHECKSUM sha256sum"
    buster="https://cloud.debian.org/images/cloud/buster/latest/debian-10-generic-amd64.qcow2 https://cloud.debian.org/images/cloud/buster/latest/SHA512SUMS sha512sum"
    bullseye="https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-generic-amd64.qcow2 https://cloud.debian.org/images/cloud/bullseye/latest/SHA512SUMS sha512sum"
    bionic="https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img https://cloud-images.ubuntu.com/bionic/current/SHA256SUMS sha256sum"
    focal="https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img https://cloud-images.ubuntu.com/focal/current/SHA256SUMS sha256sum"
    jammy="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img https://cloud-images.ubuntu.com/jammy/current/SHA256SUMS sha256sum"
)

for distro in ${distros[@]}; do
    echo "${distro}"
done

# don't do anything below
exit 0

# let's prep some images. This will take a while. Come back later.
find "${basedir}" -maxdepth 1 -type f | while read file; do
        # echo ${file} # has full path, which ain't what we want
        filename="$(basename "${file}")"
        shortname="$(echo ${filename%%-*})"

        if [ "${shortname}" == "debian" ]; then
                # we need to know which version so we can translate it into a codename
                echo ${filename} | grep -q ^debian-10
                if [ $? -eq 0 ]; then
                        codename="buster"
                fi

                echo ${filename} | grep -q ^debian-11
                if [ $? -eq 0 ]; then
                        codename="bullseye"
                fi
        elif [ "${shortname}" == "Fedora" ]; then
                echo ${filename} | grep -q Base-35
                if [ $? -eq 0 ]; then
                        codename="fedora35"
                fi

                echo ${filename} | grep -q Base-36
                if [ $? -eq 0 ]; then
                        codename="fedora36"
                fi
        elif [ "${shortname}" == "CentOS" ]; then
                codename="centos7"
        elif [ "${shortname}" == "AlmaLinux" -o "${shortname}" == "Rocky" ]; then
                nextbit="$(echo ${filename} | cut -d \- -f 2)"
                codename="$(echo ${shortname}${nextbit} | tr [:upper:] [:lower:])"
        else
                codename="$(echo ${shortname} | tr [:upper:] [:lower:])"
        fi

        echo "Codename for ${filename} is ${codename}"
        newfile="/storage/prep/update/${codename}.qcow2"

        test -f "${newfile}"
        if [ $? -eq 0 ]; then
                echo "${newfile} has already been prepped - skipping."
        else
                # make a copy of the file
                cp "${file}" "${newfile}"

                echo "Prepping image: ${newfile}"

                # update it and install qemu-guest-agent
                virt-sysprep -a "${newfile}" --network --update --selinux-relabel --install qemu-guest-agent
        fi

        # now, let's salt one
        newfile_salt="/storage/prep/update/${codename}-salted.qcow2"

        test -f "${newfile_salt}"
        if [ $? -eq 0 ]; then
                echo "${newfile_salt} already exists, skipping."
        else
                cp "${file}" "${newfile_salt}"
                echo "Prepping image with Salt: ${newfile_salt}"
                virt-sysprep -a "${newfile_salt}" --network --update --selinux-relabel --install qemu-guest-agent,curl --run-command 'curl -L https://bootstrap.saltstack.com -o /tmp/install_salt.sh && bash /tmp/install_salt.sh -X -x python3'
        fi
done