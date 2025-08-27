-- View existing event objects

-- List all Extended Event packages
SELECT * 
FROM sys.dm_xe_packages

/*
Returns a row for each object that is exposed by an event package. 
Objects can be one of the following:
- Events. Events indicate points of interest in an execution path. 
	All events contain information about a point of interest.
- Actions. Actions are run synchronously when events fire. 
	An action can append run time data to an event.
- Targets. Targets consume events, either synchronously on the thread 
	that fires the event or asynchronously on a system-provided thread.
- Predicates. Predicate sources retrieve values from event sources for 
	use in comparison operations. Predicate comparisons compare 
	specific data types and return a Boolean value.
- Types. Types encapsulate the length and characteristics of the byte 
	collection, which is required in order to interpret the data.
*/

--- EVENTS
SELECT xep.name, xeo.* 
FROM sys.dm_xe_objects xeo
INNER JOIN sys.dm_xe_packages xep ON xeo.package_guid = xep.guid
WHERE 
	xeo.object_type = 'event'
	--xeo.object_type = 'action'
	--xeo.object_type = 'target'
	--xeo.object_type = 'predicate'
	--xeo.object_type = 'types'
ORDER BY xep.name, xeo.name

SELECT xep.name AS package_name, xeo.name as [object_name], xeo.description, xeoc.name AS event_name, xeoc.description
FROM sys.dm_xe_objects xeo
INNER JOIN sys.dm_xe_packages xep ON xeo.package_guid = xep.guid
INNER JOIN sys.dm_xe_object_columns xeoc on xep.guid = xeoc.object_package_guid AND xeo.name = xeoc.object_name
WHERE 
	xeo.object_type = 'event'
	--and xeo.name = 'sql_statement_completed'
	--and xeo.name = 'rpc_completed'
	and xeo.name = 'sql_batch_completed'
ORDER BY xep.name, xeo.name

-- ACTIONS
SELECT xep.name + '.' + xeo.name AS [name], xeo.* 
FROM sys.dm_xe_objects xeo
INNER JOIN sys.dm_xe_packages xep ON xeo.package_guid = xep.guid
WHERE 
	--xeo.object_type = 'event'
	xeo.object_type = 'action'
	--xeo.object_type = 'target'
	--xeo.object_type = 'predicate'
	--xeo.object_type = 'types'
ORDER BY xep.name, xeo.name

/* Information about targets */
SELECT xep.name + '.' + xeo.name AS [name], xeo.* 
FROM sys.dm_xe_objects xeo
INNER JOIN sys.dm_xe_packages xep ON xeo.package_guid = xep.guid
WHERE 
	--xeo.object_type = 'event'
	--xeo.object_type = 'action'
	xeo.object_type = 'target'
	--xeo.object_type = 'predicate'
	--xeo.object_type = 'types'
ORDER BY xep.name, xeo.name


SELECT xep.name AS package_name, xeo.name AS [object_name], xeo.description, xeoc.name, xeoc.description
FROM sys.dm_xe_objects xeo
INNER JOIN sys.dm_xe_packages xep ON xeo.package_guid = xep.guid
INNER JOIN sys.dm_xe_object_columns xeoc on xep.guid = xeoc.object_package_guid AND xeo.name = xeoc.object_name
WHERE 
	xeo.object_type = 'target'
	--and xeo.name = 'ring_buffer'
	and xeo.name = 'event_file'
	--and xeo.name = 'rpc_completed'
ORDER BY xep.name, xeo.name





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
GO	

	


/*
 * Create an Extended Events session that writes to disk. 
 * For: 
 * - SQL Server
 * 
 * Requires permissions:
 * - ALTER ANY EVENT SESSION	- GRANT ALTER ANY EVENT SESSION TO [YourLoginName];
 * - VIEW SERVER STATE			- GRANT VIEW SERVER STATE TO [YourLoginName];
 */

 
DECLARE @filename nvarchar(200) = N'G:\xe-logs\Performance Test Trace.xel';

DECLARE @sql NVARCHAR(MAX);

SET @sql = N'
CREATE EVENT SESSION [Performance Test Trace] 
ON SERVER 
	ADD EVENT sqlserver.sql_batch_completed
	(
		SET collect_batch_text=(1)
		ACTION
		(
			sqlserver.client_app_name,
			sqlserver.client_hostname,
			sqlserver.database_id,
			sqlserver.database_name,
			sqlserver.nt_username,
			sqlserver.query_hash,
			sqlserver.query_plan_hash
		)
		--WHERE 
		--(
		    -- Use to filter on dbs
			--(
			--	[sqlserver].[database_id] = 152
			--)
			
			-- Use this to only trace requests from a specific application
			-- AND ([sqlserver].[client_hostname]=N''cLA'')

			--([sqlserver].[client_hostname]=N''SQL Server Management Studio'')
			-- Use this filter if tracing rpc_completed
			-- AND ([sqlserver].[not_equal_i_sql_unicode_string]([object_name],N''sp_reset_connection''))
			
			-- Use if looking for requests with a certain duration
			-- AND ([package0].[greater_than_equal_uint64]([duration],(120000000)))
			
		--)
	) 
	ADD TARGET package0.event_file
	(
		SET filename = N''' + @filename + N''', 
			max_file_size=(512)	/* Maximum file size in MB */, 
			max_rollover_files=(20) /* Maximum number of files to retain */
	)
	WITH 
	(
		MAX_MEMORY=4096 KB /* 4096 KB is default */
		,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS /* Safeguard to keep acceptable performance */
		,MAX_DISPATCH_LATENCY=30 SECONDS /* 30 seconds is default and good balance for event_file as not so much stress is put on the system */
		,MAX_EVENT_SIZE=0 KB /* Default */
		,MEMORY_PARTITION_MODE=NONE /* Default */
		,TRACK_CAUSALITY=OFF /* Default, no need to track causality */
		,STARTUP_STATE=OFF /* This event session is started manually */
		--,MAX_DURATION = 2 DAYS /* Default is UNLIMITED  - SQL Server 2025 Preview feature*/
	)

';

EXEC sp_executesql @sql;

GO

ALTER
    EVENT SESSION
        [Performance Test Trace]
    ON SERVER
    STATE = START;
GO

ALTER
    EVENT SESSION
        [Performance Test Trace]
    ON SERVER
    STATE = STOP;
GO

DROP EVENT SESSION [Performance Test Trace] ON SERVER
GO


-- Create an extended event session with a ring buffer
-- Works with Azure SQL Database Managed Instance

CREATE EVENT SESSION [Query performance trace] ON SERVER 
ADD EVENT sqlserver.rpc_completed(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.nt_username,sqlserver.query_hash,sqlserver.query_plan_hash)
    WHERE ((([sqlserver].[not_equal_i_sql_unicode_string]([object_name],N'sp_reset_connection')) AND ([package0].[greater_than_equal_uint64]([duration],(120000000)))) AND ([sqlserver].[database_id]<>(1)))), 
ADD EVENT sqlserver.sql_batch_completed(SET collect_batch_text=(1)
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.nt_username,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.sql_text)
    WHERE (([package0].[greater_than_equal_uint64]([duration],(120000000))) AND ([sqlserver].[database_id]<>(1)))), 
ADD EVENT sqlserver.sql_statement_completed(
    ACTION(sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.execution_plan_guid,sqlserver.nt_username,sqlserver.num_response_rows,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.sql_text)
    WHERE (([package0].[greater_than_equal_int64]([duration],(60000000))) AND ([sqlserver].[database_id]<>(1))))
ADD TARGET package0.ring_buffer(SET max_events_limit=(0),max_memory=(512000))
GO


-- Create an extended event session with a ring buffer
-- Works with Azure SQL Database

CREATE EVENT SESSION [Query performance trace] ON DATABASE
ADD EVENT sqlserver.rpc_completed(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.query_hash,sqlserver.query_plan_hash)
    WHERE ((([sqlserver].[not_equal_i_sql_unicode_string]([object_name],N'sp_reset_connection')) AND ([package0].[greater_than_equal_uint64]([duration],(120000000)))) AND ([sqlserver].[database_id]<>(1)))), 
ADD EVENT sqlserver.sql_batch_completed(SET collect_batch_text=(1)
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.sql_text)
    WHERE (([package0].[greater_than_equal_uint64]([duration],(120000000))) AND ([sqlserver].[database_id]<>(1)))), 
ADD EVENT sqlserver.sql_statement_completed(
    ACTION(sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.execution_plan_guid,sqlserver.num_response_rows,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.sql_text)
    WHERE (([package0].[greater_than_equal_int64]([duration],(60000000))) AND ([sqlserver].[database_id]<>(1))))
ADD TARGET package0.ring_buffer(SET max_events_limit=(0),max_memory=51200) --50MB
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