#!/usr/bin/env python3

from urllib.request import urlretrieve
import urllib.request
from urllib.parse import urlparse
from os.path import exists as file_exists
from os import get_terminal_size as gtz
import os
import progressbar
import hashlib
import requests
import pprint
import re
import subprocess
import shutil
import datetime
import argparse

# get arguments from command-line
parser = argparse.ArgumentParser()
parser.add_argument('-o', '--os', help='Limit to one OS (specified by short name)', required=False)
args = parser.parse_args()

dirs = {}
dirs['basedir']="/storage/prep"
dirs['original']="{}/original".format(dirs['basedir'])
dirs['updated']="{}/updated".format(dirs['basedir'])
dirs['salted']="{}/salted".format(dirs['basedir'])

distros = {
    'centos7': {
        'url': 'https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-2009.qcow2',
        'checksum': 'https://cloud.centos.org/centos/7/images/sha256sum.txt',
        'checksum_type': 'sha256sum'
    },
    'rocky8': {
        'url': 'https://dl.rockylinux.org/pub/rocky/8.5/images/Rocky-8-GenericCloud.latest.x86_64.qcow2',
        'checksum': 'https://dl.rockylinux.org/pub/rocky/8/images/CHECKSUM',
        'checksum_type': 'sha256sum'
    },
    'almalinux8': {
        'url': 'https://repo.almalinux.org/almalinux/8/cloud/x86_64/images/AlmaLinux-8-GenericCloud-latest.x86_64.qcow2',
        'checksum': 'https://repo.almalinux.org/almalinux/8/cloud/x86_64/images/CHECKSUM',
        'checksum_type': 'sha256sum'
    },
    'buster': {
        'url': 'https://cloud.debian.org/images/cloud/buster/latest/debian-10-generic-amd64.qcow2',
        'checksum': 'https://cloud.debian.org/images/cloud/buster/latest/SHA512SUMS',
        'checksum_type': 'sha512sum'
    },
    'bullseye': {
        'url': 'https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-generic-amd64.qcow2',
        'checksum': 'https://cloud.debian.org/images/cloud/bullseye/latest/SHA512SUMS',
        'checksum_type': 'sha512sum'
    },
    'bionic': {
        'url': 'https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img',
        'checksum': 'https://cloud-images.ubuntu.com/bionic/current/SHA256SUMS',
        'checksum_type': 'sha256sum'
    },
    'focal': {
        'url': 'https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img',
        'checksum': 'https://cloud-images.ubuntu.com/focal/current/SHA256SUMS',
        'checksum_type': 'sha256sum'
    },
    'jammy': {
        'url': 'https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img',
        'checksum': 'https://cloud-images.ubuntu.com/jammy/current/SHA256SUMS',
        'checksum_type': 'sha256sum'
    },
}

pbar = None

def show_progress(block_num, block_size, total_size):
    global pbar
    if pbar is None:
        pbar = progressbar.ProgressBar(maxval=total_size)
        pbar.start()

    downloaded = block_num * block_size
    if downloaded < total_size:
        pbar.update(downloaded)
    else:
        pbar.finish()
        pbar = None


def download_file(url, file):
    if(file_exists(file)):
        print("File already exists: {}".format(file))
    else:
        print("Retrieving: {}".format(url))
        urlretrieve(url, file, show_progress)


def validate_checksum(checksum, url, file, type):
    resp = requests.get(checksum)
    
    a = urlparse(url)
    filename = os.path.basename(a.path).strip()
    print('Debug: filename is {}'.format(filename))

    regex = re.compile('{}$'.format(filename))
    hash = "null"
    for line in resp.text.split('\n'):
        match = re.search(regex, line)
        print('Debugging: {}'.format(line))
        if match:
            hashArr = line.split(' ')
            hash = hashArr[0]
    if hash == "null":
        print("Error: could not find {} hash in {} -- exiting.".format(type, checksum))
        return(False)
    
    if type == "sha256sum":
        sha256_hash = hashlib.sha256()
        with open(file,"rb") as f:
            # Read and update hash string value in blocks of 4K
            for byte_block in iter(lambda: f.read(4096),b""):
                sha256_hash.update(byte_block)
        local_hash = sha256_hash.hexdigest()
    elif type == "sha512sum":
        sha512_hash = hashlib.sha512()
        with open(file,"rb") as f:
            # Read and update hash string value in blocks of 4K
            for byte_block in iter(lambda: f.read(4096),b""):
                sha512_hash.update(byte_block)
        local_hash = sha512_hash.hexdigest()
    else:
        local_hash = "bullshit"

    if local_hash == hash:
        return(True)
    else:
        return(False)

def write_nice_output():
    print("-=" * int(gtz().columns/2))


def virt_sysprep(file, newfile, salt):
    shutil.copy(file, newfile)
    if salt:
        cmdLine = "/usr/bin/virt-sysprep -a {} --network --update --selinux-relabel --install qemu-guest-agent,curl --run-command 'curl -L https://bootstrap.saltstack.com -o /tmp/install_salt.sh && bash /tmp/install_salt.sh -X -x python3'".format(newfile)
    else:
        cmdLine = "/usr/bin/virt-sysprep -a {} --network --update --selinux-relabel --install qemu-guest-agent".format(newfile)
    print("Running virt-sysprep on file {}".format(newfile))
    process = subprocess.run(cmdLine, shell=True, check=True)


# main? I need to learn Python better
# do the output directories exist? if not, create them
for key, dir in dirs.items():
    check_path = os.path.exists(dir)
    if not check_path:
        print("Creating directory: {}".format(dir))
        os.makedirs(dir)


for key, item in distros.items():
    if args.os:
        if key != args.os:
            print("Option -o passed: skipping distro {}...".format(key))
            continue
    print("Processing distro: {}".format(key))
    file="{}/{}.qcow2".format(dirs['original'], key)
    updated_file="{}/{}.qcow2".format(dirs['updated'], key)
    salted_file="{}/{}.qcow2".format(dirs['salted'], key)

    # download
    download_file(item['url'], file)

    # retrieve checksum and validate
    checksum = validate_checksum(item['checksum'], item['url'], file, item['checksum_type'])
    if checksum:
        print("Hash validation for file {} passed.".format(file))
    else:
        print("Hash validation for {} failed - skipping.".format(file))
        write_nice_output
        continue

    # virt-sysprep - but no salt
    virt_sysprep(file, updated_file, False)

    # copy file to -salted and, well, salt it
    virt_sysprep(file, salted_file, True)

    # write some nice user output
    write_nice_output
