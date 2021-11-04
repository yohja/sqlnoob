CREATE SCHEMA inv;

-- Table inv.SqlServers : Store server related information

CREATE TABLE inv.SqlServers
(
    HostName NVARCHAR(32) NOT NULL
    ,IpAddress NVARCHAR(16)
    ,OperatingSystem NVARCHAR(128)
    ,Environment NVARCHAR(16)
    ,HostStatus BIT
    ,ProcessorCores INT
    ,ServerDescription NVARCHAR(256)
    ,RegisteredDate DATETIME
    ,ModifiedDate DATETIME
    ,CONSTRAINT PK_SqlServers PRIMARY KEY CLUSTERED(HostName)
)
GO

-- Table inv.SqlInstances : store information about sql server instances on each servers
CREATE TABLE inv.SqlInstances
(
    InstanceId INT IDENTITY(1,1) NOT NULL
    ,HostName NVARCHAR(32) NOT NULL
    ,InstanceName NVARCHAR(32) NOT NULL
    ,FullInstanceName NVARCHAR(64)
    ,FullVersion NVARCHAR(512)
    ,MajorVersion NVARCHAR(64)
    ,ProductVersion NVARCHAR(32)
    ,ProductEdition NVARCHAR(128)
    ,ProductLevel NVARCHAR(16)
    ,UpdateLevel NVARCHAR(32)
    ,InstanceDescription NVARCHAR(128)
    ,RegisteredDate DATETIME
    ,ModifiedDate DATETIME
    ,CONSTRAINT PK_SqlInstances PRIMARY KEY CLUSTERED(InstanceId)
)
GO
ALTER TABLE inv.SqlInstances WITH CHECK ADD CONSTRAINT FK_SqlInstances_SqlServers FOREIGN KEY (HostName)
REFERENCES inv.SqlServers(HostName)
GO

-- Table inv.SqlDatabases : store information about databases on each instances
CREATE TABLE inv.SqlDatabases
(
    DatabaseId INT IDENTITY(1,1) NOT NULL
    ,InstanceId INT NOT NULL
    ,DatabaseName NVARCHAR(128) NOT NULL
    ,FileOwner NVARCHAR(64)
    ,CompatibilityLevel TINYINT
    ,RecoveryModel NVARCHAR(32)
    ,DatabaseCollaction NVARCHAR(128)
    ,CreatedDate DATETIME
    ,DatabaseState NVARCHAR(32)
    ,DatabaseSize DECIMAL(15,2)
    ,RegisteredDate DATETIME
    ,ModifiedDate DATETIME
    ,CONSTRAINT PK_SqlDatabases PRIMARY KEY CLUSTERED(DatabaseId)
)
GO
ALTER TABLE inv.SqlDatabases WITH CHECK ADD CONSTRAINT FK_SqlDatabases_SqlInstances FOREIGN KEY(InstanceId)
REFERENCES inv.SqlInstances(InstanceId)
GO


-- Table inv.ApplicationCatalog : store brief information about application related to database
CREATE TABLE inv.ApplicationCatalog
(
    ApplicationId INT IDENTITY(1,1) NOT NULL
    ,ApplicationName NVARCHAR(128)
    ,InformationOwner NVARCHAR(128)
    ,OwnerTeam NVARCHAR(128)
    ,CONSTRAINT PK_ApplicationCatalog PRIMARY KEY CLUSTERED(ApplicationId)
)

-- Table inv.SqlLogins : store information about logins on each instances
CREATE TABLE inv.SqlLogins
(
    LoginId INT IDENTITY(1,1) NOT NULL
    ,InstanceId INT NOT NULL
    ,LoginName NVARCHAR(64) NOT NULL
    ,LoginType NVARCHAR(32)
    ,DefaultDatabase NVARCHAR(128)
    ,ApplicationId INT NOT NULL
    ,PicName NVARCHAR(128)
    ,PicEmail NVARCHAR(256)
    ,TechPicName NVARCHAR(128)
    ,TechPicEmail NVARCHAR(256)
    ,ServerRole NVARCHAR(64)
    ,EncryptedPassword VARBINARY(MAX)
    ,HashedPassword VARBINARY(MAX)
    ,IsDisabled BIT
    ,NeedNotification BIT
    ,MaxPasswordAge INT
    ,ExpirationThreshold INT
    ,NotificationFrequency INT
    ,CreatedDate DATETIME
    ,UpdatedDate DATETIME
    ,RegisteredDate DATETIME
    ,ModifiedDate DATETIME
    ,CONSTRAINT PK_SqlLogins PRIMARY KEY CLUSTERED(LoginId)
)
GO
ALTER TABLE inv.SqlLogins WITH CHECK ADD CONSTRAINT FK_SqlLogins_SqlInstances FOREIGN KEY(InstanceId)
REFERENCES inv.SqlInstances(InstanceId)
GO
ALTER TABLE inv.SqlLogins WITH NOCHECK ADD CONSTRAINT FK_SqlLogins_ApplicationCatalog FOREIGN KEY(ApplicationId)
REFERENCES inv.ApplicationCatalog(ApplicationId)
GO

-- Table inv.DatabaseUsers : table to store all database users
CREATE TABLE inv.DatabaseUsers
(
    UserId INT IDENTITY(1,1) NOT NULL
    ,UserName NVARCHAR(128)
    ,DatabaseId INT NOT NULL
    ,LoginId INT NOT NULL
    ,DefaultSchema NVARCHAR(64)
    ,CreatedDate DATETIME
    ,UpdatedDate DATETIME
    ,CONSTRAINT PK_DatabaseUsers PRIMARY KEY CLUSTERED(UserId)
)
GO
ALTER TABLE inv.DatabaseUsers WITH CHECK ADD CONSTRAINT FK_DatabaseUsers_SqlDatabases FOREIGN KEY(DatabaseId)
REFERENCES inv.SqlDatabases(DatabaseId)
GO
ALTER TABLE inv.DatabaseUsers WITH NOCHECK ADD CONSTRAINT FK_DatabaseUsers_SqlLogins FOREIGN KEY(LoginId)
REFERENCES inv.SqlLogins(LoginId)
GO

-- Table inv.UserPermissions : table to store all user permission on each databases
CREATE TABLE inv.UserPermissions
(
    PermissionId INT IDENTITY(1,1) NOT NULL
    ,UserId INT NOT NULL
    ,RoleName NVARCHAR(32)
    ,PermissionType NVARCHAR(16)
    ,PermissionState NVARCHAR(16)
    ,ObjectType NVARCHAR(16)
    ,SchemaName NVARCHAR(32)
    ,ObjectName NVARCHAR(128)
    ,CONSTRAINT PK_UserPermission PRIMARY KEY CLUSTERED(PermissionId)
)
GO
ALTER TABLE inv.UserPermissions WITH CHECK ADD CONSTRAINT FK_UserPermission_DatabaseUsers FOREIGN KEY(UserId)
REFERENCES inv.DatabaseUsers(UserId)
GO
