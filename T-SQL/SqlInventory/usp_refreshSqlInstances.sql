
create procedure [inv].[usp_refreshSqlInstances]
	@HostName nvarchar(32)
	,@InstanceName nvarchar(32)
	,@FullInstanceName nvarchar(64)
	,@FullVersion nvarchar(512)
	,@MajorVersion nvarchar(64)
	,@ProductLevel nvarchar(16)
	,@Updatelevel nvarchar(32)
	,@ProductVersion nvarchar(32)
	,@ProductEdition nvarchar(128)
as
begin
	with si as
	(
		select
			@HostName HostName
			,@InstanceName InstanceName
			,@FullInstanceName FullInstanceName
			,@FullVersion FullVersion
			,@MajorVersion MajorVersion
			,@ProductLevel ProductLevel
			,@Updatelevel UpdateLevel
			,@ProductVersion ProductVersion
			,@ProductEdition ProductEdition
	)
	merge inv.SqlInstances as t
	using
	(
		select
			HostName
			,InstanceName
			,FullInstanceName
			,FullVersion
			,MajorVersion
			,Productlevel
			,UpdateLevel
			,ProductVersion
			,Productedition
		from si
	) as s
	on
	(
		t.HostName				= s.HostName
		and t.FullInstanceName	= s.FullInstanceName
	)
	when matched then
		update set
			t.InstanceName			= s.InstanceName
			,t.FullVersion			= s.FullVersion
			,t.MajorVersion			= s.MajorVersion
			,t.Productlevel			= s.ProductLevel
			,t.UpdateLevel			= s.UpdateLevel
			,t.ProductVersion		= s.ProductVersion
			,t.ProductEdition		= s.ProductEdition
			,t.ModifiedDate			= getdate()
	when not matched then
		insert
		(
			HostName
			,InstanceName
			,FullInstanceName
			,FullVersion
			,MajorVersion
			,Productlevel
			,UpdateLevel
			,ProductVersion
			,Productedition
			,RegisteredDate
		)
		values
		(
			s.HostName
			,s.InstanceName
			,s.FullInstanceName
			,s.FullVersion
			,s.MajorVersion
			,s.Productlevel
			,s.UpdateLevel
			,s.ProductVersion
			,s.Productedition
			,getdate()
		);
end

-- inv.usp_refreshSqlInstances
