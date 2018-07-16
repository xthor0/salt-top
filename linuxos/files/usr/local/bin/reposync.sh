#!/bin/bash

for repo in base centosplus extras updates epel; do
  reposync --gpgcheck -l --repoid=${repo} --download_path={{ reposync_path }} --downloadcomps --download-metadata
  if [ $? -ne 0 ]; then
    error=1
  else
    if [ -f "{{ reposync_path }}/${repo}/comps.xml" ]; then
      createrepo "{{ reposync_path }}/${repo}" -g comps.xml
    else
      createrepo "{{ reposync_path }}/${repo}" -g comps.xml
    fi
  fi
done

# if error variable is set, we need to stop
if [ -n "$error" ]; then
  echo "Error running reposync - examine output."
  exit 255
fi

## TODO: got some work to do here
# Carner sent me his reposync script, and it used this command:
# reposync ${QOPT} -c ~/updater/docker.repo -e /var/tmp/mirror.docker --norepopath -d -r docker-stable -p /srv/repo/docker/x86_64
# I need to modify this for my own use
# -c -> use the specified config file
# -e -> directory in which to store metadata... I think he's deleting this in his script, so he puts it there and nukes it
### I could do a mktemp, pass that path, and then rm -rf it
# --norepopath -> don't add the reponame to the download path, I think this will just download to the directory specified with -p
# -p -> where to download the packages
# -d -> delete files locally if they aren't present in the repository
# -r -> repoid - I think we could put everything in the same config file and then just specify the repoid
# not specified here, but I want to use -m to tell it to download comps.xml, at least on centos :)

## TODO: part 2
# since this script is managing in all the repo files, I should have this script do the heavy lifting for me when I want to add a repo.
# each file will be named appropriately with a .repo config file
# the script loops through all the files in that directory, and runs reposync against each file
# this requires a little more work up-front (for example, CentOS 7 has four repos in the main config file, and I'll have to break that apart)
# but it has the added benefit of allowing this script to rarely be modified, and instead new repos can be added just by managing in a new config file
# I'll give this more thought and see if this approach makes the most sense...
# I could also pull in the remote RPM for each repo on the primary repo server...

exit 0
