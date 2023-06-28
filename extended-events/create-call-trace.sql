-- View existing event objects

SELECT TOP 5 * 
FROM sys.dm_xe_packages

SELECT TOP 5 * 
FROM sys.dm_xe_objects

SELECT TOP 5 * 
FROM sys.dm_xe_object_columns

SELECT object_type FROM sys.dm_xe_objects GROUP BY object_type

SELECT 
	p.name AS PackageName,
	o.name AS ObjectName,
	p.description AS PackageDescription,
	o.description AS ObjectDescription
FROM sys.dm_xe_packages p
INNER JOIN sys.dm_xe_objects o ON p.guid = o.package_guid
WHERE
	o.object_type = 'event'

SELECT 
	p.name AS PackageName,
	o.name AS ObjectName,
	p.description AS PackageDescription,
	o.description AS ObjectDescription
FROM sys.dm_xe_packages p
INNER JOIN sys.dm_xe_objects o ON p.guid = o.package_guid
WHERE
	o.object_type = 'action'

SELECT 
	p.name AS PackageName,
	o.name AS ObjectName,
	c.name AS ColumnName,
	p.description AS PackageDescription,
	o.description AS ObjectDescription,
	c.description AS ColumnDescription
FROM sys.dm_xe_packages p
INNER JOIN sys.dm_xe_objects o ON p.guid = o.package_guid
INNER JOIN sys.dm_xe_object_columns c on p.guid = c.object_package_guid AND o.name = c.object_name
WHERE
	o.object_type = 'event' AND
	o.name = 'error_reported'
	
	



-- SQL Server
CREATE 
	EVENT SESSION [Performance Test Trace] ON SERVER 
ADD EVENT sqlserver.databases_bulk_insert_rows(
    ACTION(sqlserver.query_hash,sqlserver.query_plan_hash)),
ADD EVENT sqlserver.rpc_completed(SET collect_statement=(1)
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.nt_username,sqlserver.query_hash,sqlserver.query_plan_hash)
    WHERE ([object_name]<>N'sp_reset_connection')),
ADD EVENT sqlserver.sql_batch_completed(SET collect_batch_text=(1)
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.nt_username,sqlserver.query_hash,sqlserver.query_plan_hash)) 
ADD TARGET package0.event_file(SET filename=N'F:\Mounts\Data\Data01\SQLDATA\MSSQL11.MSSQLSERVER\MSSQL\Log\Performance Test Trace.xel',max_file_size=(2048),max_rollover_files=(10))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=10 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

-- Azure SQL DB - ring buffer
CREATE 
	EVENT SESSION [Performance Test Trace] ON DATABASE 
ADD EVENT sqlserver.rpc_completed(SET collect_statement=(1)
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.num_response_rows,sqlserver.query_hash,sqlserver.query_plan_hash)
    WHERE ([object_name]<>N'sp_reset_connection')),
ADD EVENT sqlserver.sql_batch_completed(SET collect_batch_text=(1)
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.num_response_rows,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.sql_text)),
ADD EVENT sqlserver.sp_statement_completed(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.num_response_rows,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.sql_text)) 
ADD TARGET package0.ring_buffer WITH (max_memory=64MB)
GO






DROP EVENT SESSION [Performance Test Trace] ON DATABASE
GO

-- Azure SQL Database: To monitor for permissions required by SSMS Table Designer

-- Create the master key
IF NOT EXISTS
    (SELECT * FROM sys.symmetric_keys
        WHERE symmetric_key_id = 101)
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = '<hidden key>'
END
GO


IF EXISTS
    (SELECT * FROM sys.database_scoped_credentials
        -- TODO: Assign AzureStorageAccount name, and the associated Container name.
        WHERE name = 'https://sqlva3gvldcy4pkgje.blob.core.windows.net/xevent-sink')
BEGIN
    DROP DATABASE SCOPED CREDENTIAL
        -- TODO: Assign AzureStorageAccount name, and the associated Container name.
        [https://sqlva3gvldcy4pkgje.blob.core.windows.net/xevent-sink] ;
END
GO


CREATE
    DATABASE SCOPED
    CREDENTIAL
        -- use '.blob.',   and not '.queue.' or '.table.' etc.
        -- TODO: Assign AzureStorageAccount name, and the associated Container name.
        [https://sqlva3gvldcy4pkgje.blob.core.windows.net/xevent-sink]
    WITH
        IDENTITY = 'SHARED ACCESS SIGNATURE',  -- "SAS" token.
        -- TODO: Paste in the long SasToken string here for Secret, but exclude any leading '?'.
        SECRET = '<hidden SAS>'
    ;
GO

CREATE 
	EVENT SESSION [Permissions-For-DDL] ON DATABASE
ADD EVENT sqlserver.error_reported(
    ACTION(sqlserver.sql_text, sqlserver.tsql_stack))
ADD TARGET
        package0.event_file
            (
            -- TODO: Assign AzureStorageAccount name, and the associated Container name.
            -- Also, tweak the .xel file name at end, if you like.
            SET filename =
                'https://sqlva3gvldcy4pkgje.blob.core.windows.net/xevent-sink/permissions-for-ddl.xel'
            )
WITH (MAX_MEMORY = 10 MB,
        MAX_DISPATCH_LATENCY = 3 SECONDS)
GO

ALTER
    EVENT SESSION
        [Permissions-For-DDL]
    ON DATABASE
    STATE = START;
GO