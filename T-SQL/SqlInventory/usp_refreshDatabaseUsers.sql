alter procedure inv.usp_refreshDatabaseUsers
	@HostName nvarchar(32)
	,@FullInstanceName nvarchar(32)
	,@UserName nvarchar(128)
	,@UserType nvarchar(32)
	,@DatabaseName nvarchar(128)
	,@LoginName nvarchar(128)
	,@DefaultSchema nvarchar(32)
	,@CreatedDate datetime
	,@UpdatedDate datetime
as
begin
	;with dbusers as
	(
		select
			@HostName HostName
			,@FullInstanceName FullInstanceName
			,@UserName UserName
			,@UserType UserType
			,@DatabaseName DatabaseName
			,@LoginName LoginName
			,@DefaultSchema DefaultSchema
			,@CreatedDate CreatedDate
			,@UpdatedDate UpdatedDate
	)
	merge inv.DatabaseUsers as t using
	(
		select
			a.UserName
			,a.UserType
			,b.DatabaseId
			,c.LoginId
			,a.DefaultSchema
			,a.CreatedDate
			,a.UpdatedDate
		from dbusers a
			inner join inv.SqlInstances i on (a.HostName = i.HostName and a.FullInstanceName = i.FullInstanceName)
			inner join inv.SqlDatabases b on (a.DatabaseName = b.DatabaseName and b.InstanceId = i.InstanceId)
			left join inv.SqlLogins c on (a.LoginName = c.LoginName and c.InstanceId = i.InstanceId)
	) as s
	on
	(
		t.DatabaseId	= s.DatabaseId
		and t.UserName	= s.UserName
	)
	when matched then
		update set
			t.UserType			= s.UserType
			,t.LoginId			= s.LoginId
			,t.DefaultSchema	= s.DefaultSchema
			,t.CreatedDate		= s.CreatedDate
			,t.UpdatedDate		= s.UpdatedDate
	when not matched then
	insert
	(
		UserName
		,UserType
		,DatabaseId
		,LoginId
		,DefaultSchema
		,CreatedDate
		,UpdatedDate
	)
	values
	(
		s.UserName
		,s.UserType
		,s.DatabaseId
		,s.LoginId
		,s.DefaultSchema
		,s.CreatedDate
		,s.UpdatedDate
	);
end