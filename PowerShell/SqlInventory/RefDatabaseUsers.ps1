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
        declare @dbusers table
        (
            UserName nvarchar(64)
            ,UserType nvarchar(32)
            ,DatabaseName nvarchar(128)
            ,LoginName nvarchar(128)
            ,DefaultSchema nvarchar(32)
            ,CreatedDate datetime
            ,UpdatedDate datetime
        )
        declare @Command nvarchar(max) = N'
                select 
                    a.name UserName
                    ,a.type_desc UserType
                    ,db_name() DatabaseName
                    ,b.name LoginName
                    ,a.default_schema_name DefaultSchema
                    ,a.create_date CreatedDate
                    ,a.modify_date UpdatedDate
                from sys.database_principals a
                    LEFT JOIN sys.server_principals b ON a.[sid] = b.[sid]
                where a.type in(''S'',''U'',''G'')
                    AND a.[name] NOT IN (''guest'',''sys'',''INFORMATION_SCHEMA'',''dbo'')
                    AND a.[name] not like ''##%'''
        DECLARE @CurrDB sysname, @spExecuteSQL NVARCHAR(1000)

        DECLARE DBs CURSOR
        LOCAL FAST_FORWARD
        FOR
        SELECT 
            [name]
        FROM sys.databases WITH (NOLOCK)
        WHERE state = 0 				/* online only */
            AND HAS_DBACCESS([name]) = 1
            AND [name] <> 'tempdb'

        OPEN DBs

        WHILE 1=1
        BEGIN
            FETCH NEXT FROM DBs INTO @CurrDB;
            IF @@FETCH_STATUS <> 0 BREAK;

            SET @spExecuteSQL = QUOTENAME(@CurrDB) + N'..sp_executesql'

            insert into @dbusers (UserName,UserType,DatabaseName,LoginName,DefaultSchema,CreatedDate,UpdatedDate)
            EXEC @spExecuteSQL @Command WITH RECOMPILE;
        END

        CLOSE DBs;
        DEALLOCATE DBs;
        select 
            '$HostName' as HostName
            ,@@SERVERNAME FullInstanceName
            ,UserName
            ,UserType
            ,DatabaseName
            ,LoginName
            ,DefaultSchema
            ,CreatedDate
            ,UpdatedDate
        from @dbusers;
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
				$v3 = $result["UserName"]
				$v4 = $result["UserType"]
				$v5 = $result["DatabaseName"]
				$v6 = $result["LoginName"]
				$v7 = $result["DefaultSchema"]
				$v8 = $result["CreatedDate"]
				$v9 = $result["UpdatedDate"]
				
				$tmpComand = "EXEC [inv].[usp_refreshDatabaseUsers] '$v1','$v2','$v3','$v4','$v5','$v6','$v7','$v8','$v9'"
				
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