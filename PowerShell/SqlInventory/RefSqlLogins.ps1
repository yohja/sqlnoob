###
# Refresh sql logins
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
    select
        '$HostName' as HostName
        ,@@SERVERNAME FullInstanceName
        ,a.name LoginName
        ,a.type_desc LoginType
        ,a.default_database_name DefaultDatabase
        ,CAST(CONVERT(varchar(max), CAST(LOGINPROPERTY(a.name,'PasswordHash') AS VARBINARY(max)), 1) AS NVARCHAR(max)) HashedPassword
        ,a.is_disabled IsDisabled
        ,a.create_date CreatedDate
        ,a.modify_date UpdatedDate
    from sys.server_principals a
    where a.type in('S','U','G')
        and a.name not like '##%'
        and a.name not like 'NT%'
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
				$v2 = $result["FullInstanceName"]
				$v3 = $result["LoginName"]
				$v4 = $result["LoginType"]
				$v5 = $result["DefaultDatabase"]
				$v6 = $result["HashedPassword"]
				$v7 = $result["IsDisabled"]
				$v8 = $result["CreatedDate"]
				$v9 = $result["UpdatedDate"]
				
				$tmpComand = "EXEC [inv].[usp_refreshSqlLogins] '$v1','$v2','$v3','$v4','$v5','$v6',$v7,'$v8','$v9'"
				
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