<?php

if (!empty($_SERVER['BarCode'])) {
	// Executed via CLI
	$BarCode=$_SERVER['BarCode'];
}
elseif (!empty($_POST['BarCode'])) {
	// Executed via HTTP

	// This script should be called only from certain IPs
	if (!in_array($_SERVER["REMOTE_ADDR"], ['127.0.0.1', '18.217.195.71'])) {
		die("Access Denied!");
	}

	$BarCode=$_POST['BarCode'];

}
else {
	echo("No Data!\n");
	exit(2);
}

// Failsafe
if (empty($BarCode)) die("no data");



## The business logic should be moved to the bash script `/opt/listener/sandbox/listen`!
## Calling this external PHP script is a huge overhead!
## Implement here your business logic
#if (!is_barcode_valid($BarCode)) exit(2);



## Test a Bad Code
if ($BarCode=="badcode" || $BarCode=="bad") exit(2);


### If the barcode is valid and you want to open the relay for 10 seconds, echo "ok" and nothing more
echo "ok";
exit(0);


