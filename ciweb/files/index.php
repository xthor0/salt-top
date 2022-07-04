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
timezone: America/Denver
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
