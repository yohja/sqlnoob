###
# Refresh user databases
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
	$HostName		= $item.HostName;
	$ServerInstance	= $item.ServerInstance;
	
	$Conn					= New-Object System.Data.SqlClient.SqlConnection
	$Conn.ConnectionString	= "server='$ServerInstance';database='$sDatabase';trusted_connection=true"
	
	$sqltext	= "
		SELECT 
			'$HostName' as HostName
			,@@SERVERNAME as FullInstanceName
			,sdb.name as DatabaseName
			,SUSER_SNAME(sdb.owner_sid) as FileOwner
			,sdb.compatibility_level as CompatibilityLevel
			,sdb.recovery_model_desc as RecoveryModel
			,sdb.collation_name as DatabaseCollation
			,sdb.create_date as CreatedDate
			,sdb.state_desc as DatabaseState
			,sum((mf.size * 8)/1024) as 'DatabaseSize'
		FROM sys.databases sdb
			JOIN sys.master_files mf ON sdb.database_id = mf.database_id
		WHERE sdb.database_id <> 2
		GROUP BY 
			sdb.name,
			sdb.state_desc,
			sdb.owner_sid,
			sdb.create_date,
			sdb.compatibility_level,
			sdb.recovery_model_desc,
			sdb.collation_name
	"
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
				$v2 = $result["ServerInstance"]
				$v3 = $result["DatabaseName"]
				$v4 = $result["FileOwner"]
				$v5 = $result["CompatibilityLevel"]
				$v6 = $result["RecoveryModel"]
				$v7 = $result["DatabaseCollation"]
				$v8 = $result["CreatedDate"]
				$v9 = $result["DatabaseState"]
				$v10 = $result["DatabaseSize"]
				
				$tmpComand = "EXEC [inv].[usp_refreshUserDatabases] '$v1','$v2','$v3','$v4',$v5,'$v6','$v7','$v8','$v9',$v10"

				#write-host $tmpComand
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