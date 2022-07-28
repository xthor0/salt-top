<?php
if (strpos($_SERVER['REQUEST_URI'],'meta-data') !== false) {
	$uriExplode = explode('/', $_SERVER['REQUEST_URI']);
	$vmname = $uriExplode[1];
	if($vmname == "meta-data") {
		$vmname = substr(str_shuffle(MD5(microtime())), 0, 10);
		echo "# no hostname specified in URI, generating random hostname\n";
	}
	echo "instance-id: 1\n";
	echo "local-hostname: " . htmlspecialchars($vmname);
} elseif(strpos($_SERVER['REQUEST_URI'],'user-data') !== false) {
	echo '#cloud-config
users:
    - name: root
      plain_text_passwd: resetm3n0w
      lock_passwd: false
    - name: xthor
      shell: /bin/bash
      plain_text_passwd: resetm3n0w
      lock_passwd: false
      sudo: ALL=(ALL) NOPASSWD:ALL
      ssh_authorized_keys:
        - ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJ4OwD4MqSuGlqmJsMY6SCEY7Js4n1rS+altYALKSqN/XOlxEGXOkyrfrlgZ99jaj7IDYeVYbDZN4fMUlTYjWGA= caaro@secretive.caaro.local
        - ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBM0iPdemESmJ/Dgs/Xg1apaSVl8x27IP7FJcwRZa9BKQ6nNjFMhVVLNpvXfeAV8iq09k86/o0McXpR3T/Li2Kmk= hala@secretive.hala.local
        - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDEf06CwDy+lnmUERTywZAjLGgpdwlO9pKuwQhPBENIWWRi3MKsG7hoR68+A0H/4lwxSAHFTJNHtL8khLV0559kzf+6f4tQDf1woVgLJ8GHh3EDMwVLXqNP/4oSGySrbuFbOIP9oKplxFtVOqP3h976yRZfmWG/Qqyw5OrGx7aUnj5uziY6g8QE+rJXcy9WXue6LfBqrLY94lmSc8W1VpYw71TE49jjvTM3KXOIZJZbea+OSd0AxVYhcwjUOaCP8GN/F+gWR4KJaLkWGsWBYMh2D8WyQY3qQgoD+/3J0GhH1dWnHPMHQPlkvEmxr8yx5hOzTxMw+F3UZVQr191+wSlqaQKn3/XWGwRTafkJ7qRvAYlxT+o+FaFsxNDgZMSrN+oVN9lYzvseDVc4aV4InsADnywRCMbKVhrrxZpMWz7AdKaZTQGFylbwwdnDzkfggXjnKHj3NwvF7KpK5Omil3DVd7Sriqg9KcCWfL0Xv1lawcFI1jguajXu1EZwvawKNPk= 20220705@1password
timezone: America/Denver
        - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDJNEonif7PNwf6DFR1/nqU9phsdgGFzSMO8EWkD3caLDoAs8/TvnQ+iwvzcox8yAKpU6uIaungjEil3LdiScQSB6yJXB++/4pO827+8AkYmo3seKWkk7LTpHuW8zPc8dbsre1uBCuV7VoAeMJkml1O4wwYooJVt55Nfj2qwVqbg7EMyO9C0KN6X85GLOV1WI3Oa95gmwJvnhg3sbFFW0l4DddsU7rmqzftHyfNzgg/X7VbBa1GzAhhr+EmCh19r8msAgVj6odKutk9/Z8bvE9kUH1+4c0WkdpeVOkdcacluRFZ3lrb9+UTdZ/H1ebTEKbpp/wg7eGT+pO4JcFNrqSqyiVkcBjYi6u8rzCJ3KjSy9718wwWM+y3m/NW0gCuuKTQnCeNqe+b1SUvvPZqGvMykGxStHszkVSDjuGZlu9IsP59ALSWDOvTkybu+fIONw4EmItrdPmGqGHYuA0tTzwLh4QqPr8fvF8sZaVislzHaPWzwaafKc2QpxjoABpfXdU= xthor@spindel.xthorsworld.com
package_upgrade: true
runcmd:
    - touch /etc/cloud/cloud-init.disabled
' ;
} elseif (strpos($_SERVER['REQUEST_URI'],'vendor-data') !== false) {
	echo '#vendor-data intentionally left empty';
} else {
	echo '
	<html><head>
		<title>Metadata Server</title>
		<h1>Metadata server</h1>
		<p>you didn\'t say the magic word.</p>
	</html></head>
	';
}
?>
