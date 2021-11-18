create procedure inv.usp_refreshSqlDatabases
    @HostName nvarchar(32)
	,@FullInstanceName nvarchar(64)
	,@DatabaseName nvarchar(128)
	,@FileOwner nvarchar(64)
	,@CompatibilityLevel tinyint
	,@RecoveryModel nvarchar(32)
	,@DatabaseCollation nvarchar(128)
	,@CreatedDate datetime
	,@DatabaseState nvarchar(32)
	,@DatabaseSize decimal(15,2)
as
begin
    with ud as
	(
		select
			@HostName HostName
			,@FullInstanceName FullInstanceName
			,@DatabaseName DatabaseName
			,@FileOwner FileOwner
			,@CompatibilityLevel CompatibilityLevel
			,@RecoveryModel RecoveryModel
			,@DatabaseCollation DatabaseCollation
			,@CreatedDate CreatedDate
			,@DatabaseState DatabaseState
			,@DatabaseSize DatabaseSize
	)
	merge inv.UserDatabases as t
	using
	(
		select
			b.InstanceId
			,a.DatabaseName
			,a.FileOwner
			,a.CompatibilityLevel
			,a.RecoveryModel
			,a.DatabaseCollation
			,a.CreatedDate
			,a.DatabaseState
			,a.DatabaseSize
		from ud a
			join inv.SqlInstances b on (a.HostName = b.HostName and a.FullInstanceName = b.FullInstanceName)
	) as s
	on
	(
		t.InstanceId		= s.InstanceId
		and t.DatabaseName	= s.DatabaseName
	)
	when matched then
		update set
			t.FileOwner				= s.FileOwner
			,t.CompatibilityLevel	= s.CompatibilityLevel
			,t.RecoveryModel		= s.RecoveryModel
			,t.DatabaseCollation	= s.DatabaseCollation
			,t.CreatedDate			= s.CreatedDate
			,t.DatabaseState		= s.DatabaseState
			,t.DatabaseSize			= s.DatabaseSize
			,t.ModifiedDate			= getdate()
	when not matched then
		insert
		(
			InstanceId
			,DatabaseName
			,FileOwner
			,CompatibilityLevel
			,RecoveryModel
			,DatabaseCollation
			,CreatedDate
			,DatabaseState
			,DatabaseSize
			,RegisteredDate
		)
		values
		(
			s.InstanceId
			,s.DatabaseName
			,s.FileOwner
			,s.CompatibilityLevel
			,s.RecoveryModel
			,s.DatabaseCollation
			,s.CreatedDate
			,s.DatabaseState
			,s.DatabaseSize
			,getdate()
		);
end
