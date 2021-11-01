###
# Refresh sql server disks
###

$RootDir	= Split-Path -parent $MyInvocation.MyCommand.Definition
$ConfDir	= $RootDir + "\conf"
$sFile		= $ConfDir + "\serverlist.txt"
$servers	= Get-Content -Path  $sFile

$disks = Foreach ($server in $servers)
{
	Get-WmiObject Win32_Volume -ComputerName $server -Filter "DriveType='3'" | ForEach-Object {
    New-Object PSObject -Property @{
        HostName = $_.PSComputerName
		VolumeLabel = $_.Label
		MountPoint = $_.Name
        VolumeSize = ([Math]::Round($_.Capacity /1MB,2))
        FreeSpace = ([Math]::Round($_.FreeSpace /1MB,2))
        
		}
	}
}

Import-Module ".\Modules\SqlNoobModule.psm1"
$Destination			= Set-Destination -ConfDir $ConfDir -PassFile "pfile.txt" -KeyFile "kfile.key"
$DestInstance			= $Destination.DestInstance
$DestDb					= $Destination.DestDb
$DestUser				= $Destination.DestUser
$DestPass				= $Destination.DestPass

$scred  				= New-Object -TypeName System.Data.SqlClient.SqlCredential($DestUser,$DestPass)
$Conn					= New-Object System.Data.SqlClient.SqlConnection
$Conn.ConnectionString	= "server='$DestInstance';database='$DestDb';trusted_connection=false;"
$Conn.Credential        = $scred

try
{
	$Conn.Open()
	$cmd = $Conn.CreateCommand()

	foreach($disk in $disks)
	{
		$v1 = $disk.HostName
		$v2 = $disk.VolumeLabel
		$v3 = $disk.MountPoint
		$v4 = $disk.VolumeSize
		$v5 = $disk.FreeSpace
		$v6 = (Get-Date).ToString("yyyy-MM-dd")
		
		#write-host "EXEC [inv].[usp_refreshServerVolume] '$v1','$v2','$v3',$v4,$v5,'$v6'"
		
		$cmd.CommandText = "EXEC [inv].[usp_refreshServerVolume] '$v1','$v2','$v3',$v4,$v5,'$v6'"
		$cmd.ExecuteNonQuery() | Out-Null
		
	}
	$Conn.Close()
}
catch
{
	Write-Warning $Error[0]
}
#Remove-Item $filename