###
# Refresh sql server instances
###

$RootDir	= Split-Path -parent $MyInvocation.MyCommand.Definition
$ConfDir	= $RootDir + "\conf"

Import-Module ".\Modules\SqlNoobModule.psm1"
$Destination	= Set-Destination -ConfDir $ConfDir
$DestInstance	= $Destination.DestInstance
$DestDb			= $Destination.DestDb
$DestUser		= $Destination.DestUser
$DestPass		= $Destination.DestPass

$InstanceList	= Get-InstanceList

foreach($item in $InstanceList)
{
	$ServerName		= $item.HostName
	$ServerInstance	= $item.ServerInstance

	$Conn					= New-Object System.Data.SqlClient.SqlConnection
	$Conn.ConnectionString	= "server='$ServerInstance';database='$sDatabase';trusted_connection=true"
	
	$sqltext	= "select 
						'$ServerName' as HostName
						,@@SERVICENAME as InstanceName 
						,'$ServerInstance' as ServerInstance 
						,@@VERSION as FullVersion
						,CASE 
							WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) like '8%' THEN 'Microsoft SQL Server 2000'
							WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) like '9%' THEN 'Microsoft SQL Server 2005'
							WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) like '10.0%' THEN 'Microsoft SQL Server 2008'
							WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) like '10.5%' THEN 'Microsoft SQL Server 2008 R2'
							WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) like '11%' THEN 'Microsoft SQL Server 2012'
							WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) like '12%' THEN 'Microsoft SQL Server 2014'
							WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) like '13%' THEN 'Microsoft SQL Server 2016'     
							WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) like '14%' THEN 'Microsoft SQL Server 2017' 
							WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) like '15%' THEN 'Microsoft SQL Server 2019' 
						ELSE 'unknown'
						END AS MajorVersion
						,SERVERPROPERTY('ProductLevel') AS ProductLevel
						,SERVERPROPERTY('ProductUpdateLevel') AS UpdateLevel
						,SERVERPROPERTY('ProductVersion') AS ProductVersion
						,SERVERPROPERTY('Edition') AS ProductEdition"
	try
	{
		$Conn.Open()
		$cmd = $Conn.CreateCommand()
		
		$cmd.CommandText = $sqltext
				
		$result = $cmd.ExecuteReader()
		while($result.Read())
		{
            $scred              = New-Object -TypeName System.Data.SqlClient.SqlCredential($DestUser,$DestPass)
			$c					= New-Object System.Data.SqlClient.SqlConnection
			$c.ConnectionString	= "server='$DestInstance';database='$DestDb';trusted_connection=false;"
            $c.Credential       = $scred
			try
			{
				$c.Open()
				$cm = $c.CreateCommand()
				$v1 = $result["HostName"]
				$v2 = $result["InstanceName"]
				$v3 = $result["ServerInstance"]
				$v4 = $result["FullVersion"]
				$v5 = $result["MajorVersion"]
				$v6 = $result["ProductLevel"]
				$v7 = $result["UpdateLevel"]
				$v8 = $result["ProductVersion"]
				$v9 = $result["ProductEdition"]
				
				$tmpComand = "EXEC [inv].[usp_refreshSqlInstances] '$v1','$v2','$v3','$v4','$v5','$v6','$v7','$v8','$v9'"

				$cm.CommandText = $tmpComand
				$cm.ExecuteNonQuery() | Out-Null
				
				$c.Close()
			}
			catch
			{
				Write-Warning $Error[0]
			}
		}
		
		$Conn.Close()
	}
	catch
	{
		Write-Warning $Error[0]
	}
}