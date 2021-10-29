function Set-DestinationPassword {
	param (
		$ConfDir	= ".\conf",
		$PassFile	= "pfile.txt",
		$KeyFile	= "kfile.key"
	)

	$pfile		= $ConfDir + "\" + $PassFile
	$kfile		= $ConfDir + "\" + $KeyFile
	$DestPass	= Get-Content -Path $pfile | ConvertTo-SecureString -Key (Get-Content -Path $kfile)

	$DestPass.MakeReadOnly()
	return $DestPass;
}