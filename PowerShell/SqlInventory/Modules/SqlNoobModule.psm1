function Set-Destination {
	<#
		.DESCRIPTION
			This function to get the encrypted password from the encrypted password file and convert to secure string using the key file attached
		
		.PARAMETER ConfDir
			Specify configuration directory where you store the encrypted password file and key file

		.PARAMETER KeyFile
			Specify key file name including extension
			if you don't have key file yet, you can generate one file using Add-EncryptedKeyFile function in this module
			eg. Add-EncryptedKeyFile -ByteLength 32 -OutputFile "C:\DRV\KeyFile.key"
		
		.PARAMETER PassFile
			Specify encrypted password file name including extension
			If you don't have the encrypted password file yet, you can create one file using Add-EncryptedPasswordFile function in this module
			eg. Add-EncryptedPasswordFile -Pass "MyPassword" -KeyFile "C:\DRV\KeyFile.key" -OutputFile "C:\DRV\PassFile.txt"


		.EXAMPLE
			Set Password using encrypted password file and key file stored in "C:\DRV\" folder
			----------
			Set-Destination -ConfDir "C:\DRV" -PassFile "PassFile.txt" -KeyFile "KeyFile.key"
	#>
	param (
		[String] $ConfDir	= ".\conf"
	)

	$dfile			= $ConfDir + "\config_file.json"
	$dObject		= Get-Content $dfile | ConvertFrom-Json

	$pfile			= $ConfDir + "\" + $dObject.Destination.PassFile
	$kfile			= $ConfDir + "\" + $dObject.Destination.KeyFile

	
	$DestInstance	= $dObject.Destination.Instance
	$DestDb			= $dObject.Destination.Database
	$DestUser		= $dObject.Destination.UserName
	$DestPass		= Get-Content -Path $pfile | ConvertTo-SecureString -Key (Get-Content -Path $kfile)

	$DestPass.MakeReadOnly()

	$value = New-Object PsObject -Property @{
		DestInstance	= $DestInstance;
		DestDb			= $DestDb;
		DestUser		= $DestUser;
		DestPass		= $DestPass
	}

	return $value;
}

function Get-ServerListFile {
	param (
		[String] $ConfDir	= ".\conf"
	)
	$dfile		= $ConfDir + "\config_file.json"
	$dObject	= Get-Content $dfile | ConvertFrom-Json
	$slist		= $ConfDir + "\" + $dObject.Source.ServerList

	return $slist
}

function Get-InstanceListFile {
	param (
		[String] $ConfDir	= ".\conf"
	)
	$dfile		= $ConfDir + "\config_file.json"
	$dObject	= Get-Content $dfile | ConvertFrom-Json
	$ilist		= $ConfDir + "\" + $dObject.Source.InstanceList

	return $ilist
}


function Get-InstanceList {
	param (
		[String] $ConfDir	= ".\conf"
	)
	$dfile		= $ConfDir + "\config_file.json"
	$dObject	= Get-Content $dfile | ConvertFrom-Json
	$slist		= $ConfDir + "\" + $dObject.Source.ServerList
	$servers	= Get-Content -Path $slist
	foreach ($server in $servers) {
		#Get-Service -ComputerName $server | Where-Object {
		#	($_.Name -eq 'MSSQLSERVER' -or $_.Name -like 'MSSQL$*') -and $_.DisplayName -like 'SQL Server*'
		#}
		$slists = Get-Service -ComputerName $server | Where-Object { $_.DisplayName -like "SQL Server (*" }
		foreach($slist in $slists) {
			if($slist.Name -eq "MSSQLSERVER") {
				$inm = $server
			}
			else {
				$sps = ($slist.Name).IndexOf("$")
				$inm = $server + "\" + ($slist.Name).Substring($sps + 1)
			}
			New-Object PSObject -Property @{
				HostName		= $server;
				ServerInstance	= $inm
			}
		}
		
		#$slist.Name
	}
}

function Add-EncryptedKeyFile {
	param (
		[Int] $ByteLength	= 32,
		[String] $OutputFile	= "C:\DRV\KeyFile.key"
	)

	$Key	= New-Object Byte[] $ByteLength
	[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
	
	$Key | Out-File $OutputFile

}

function Add-EncryptedPasswordFile {
	param (
		[String] $Pass		= "MyPassword",
		[String] $KeyFile	= "C:\DRV\KeyFile.key",
		[String] $OutputFile	= "C:\DRV\PassFile.txt"
	)

	$key = Get-Content -Path $KeyFile
	
	$Pass | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString -Key $key | Out-File $OutputFile
	
}