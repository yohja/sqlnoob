alter procedure inv.usp_refreshSqlLogins
	@HostName nvarchar(32)
	,@FullInstanceName nvarchar(64)
	,@LoginName nvarchar(64)
	,@LoginType nvarchar(32)
	,@DefaultDatabase nvarchar(128)
	,@HashedPassword nvarchar(max)
	,@IsDisabled bit
	,@CreatedDate datetime
	,@UpdatedDate datetime
as
begin
	;with instancelogins as
	(
		select
			@HostName HostName
			,@FullInstanceName FullInstanceName
			,@LoginName LoginName
			,@LoginType LoginType
			,@DefaultDatabase DefaultDatabase
			,@HashedPassword HashedPassword
			,@IsDisabled IsDisabled
			,@CreatedDate CreatedDate
			,@UpdatedDate UpdatedDate
	)
	merge inv.SqlLogins as t using
	(
		select
			b.InstanceId
			,a.LoginName
			,a.LoginType
			,a.DefaultDatabase
			,a.HashedPassword
			,a.IsDisabled
			,iif(a.LoginType = 'SQL_LOGIN',1,0) NeedNotification
			,iif(a.LoginType = 'SQL_LOGIN',365,null) MaxPasswordAge
			,iif(a.LoginType = 'SQL_LOGIN',14,null) ExpirationThreshold
			,iif(a.LoginType = 'SQL_LOGIN',1,null) NotificationFrequency
			,a.CreatedDate
			,a.UpdatedDate
		from instancelogins a
			inner join inv.SqlInstances b on (a.HostName = b.HostName and a.FullInstanceName = b.FullInstanceName)
	) as s
	on
	(
		t.InstanceId	= s.InstanceId
		and t.LoginName	= s.LoginName
	)
	when matched then
		update set
			t.LoginType	= s.LoginType
			,t.DefaultDatabase			= s.DefaultDatabase
			,t.HashedPassword			= s.HashedPassword
			,t.IsDisabled				= s.IsDisabled
			,t.NeedNotification			= s.NeedNotification
			,t.MaxPasswordAge			= s.MaxPasswordAge
			,t.ExpirationThreshold		= s.ExpirationThreshold
			,t.NotificationFrequency	= s.NotificationFrequency
			,t.CreatedDate				= s.CreatedDate
			,t.UpdatedDate				= s.UpdatedDate
			,t.ModifiedDate				= getdate()
	when not matched then
		insert
		(
			InstanceId
			,LoginName
			,LoginType
			,DefaultDatabase
			,HashedPassword
			,IsDisabled
			,NeedNotification
			,MaxPasswordAge
			,ExpirationThreshold
			,NotificationFrequency
			,CreatedDate
			,UpdatedDate
			,RegisteredDate
		)
		values
		(
			s.InstanceId
			,s.LoginName
			,s.LoginType
			,s.DefaultDatabase
			,s.HashedPassword
			,s.IsDisabled
			,s.NeedNotification
			,s.MaxPasswordAge
			,s.ExpirationThreshold
			,s.NotificationFrequency
			,s.CreatedDate
			,s.UpdatedDate
			,getdate()
		);
end