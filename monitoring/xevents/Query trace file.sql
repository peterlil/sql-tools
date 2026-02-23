
-- Find the trace file's name(s)
DECLARE @TraceName SYSNAME = 'Performance Trace';
SELECT 
	xes.name AS [Event Session Name]
	, xet.target_name
    , CAST(xet.target_data AS XML).value('(EventFileTarget/File/@name)[1]', 'nvarchar(256)') AS file_path
	--, * 
FROM 
	sys.dm_xe_sessions xes
INNER JOIN 
	sys.dm_xe_session_targets xet
	ON 
		xes.address = xet.event_session_address
WHERE 
	xes.name = @TraceName
	AND xet.target_name = 'event_file'


-- Get all the event and action names from the file
DECLARE @xe_file nvarchar(260) = ''
SELECT event_name, action_name
FROM 
(
	SELECT
		event_xml.value('(event/@name)[1]', 'nvarchar(256)') AS event_name,
		action.value('(@name)[1]', 'nvarchar(256)') AS action_name
	FROM 
		sys.fn_xe_file_target_read_file(
			@xe_file, 
			NULL, NULL, NULL
		) AS xef
	CROSS APPLY 
		(SELECT CAST(xef.event_data AS XML) AS event_xml) AS xml_data
	CROSS APPLY 
		xml_data.event_xml.nodes('//event/action') AS actions(action)
) base
GROUP BY event_name, action_name


-- Get all the event field names and corresponding data type from the file
DECLARE @xe_file nvarchar(260) =
    N'G:\logs\extended-events\Performance Trace_0_134159891711350000.xel';

;WITH events_in_file AS
(
    SELECT DISTINCT
        CAST(xef.event_data AS xml).value('(event/@name)[1]', 'sysname') AS event_name
    FROM sys.fn_xe_file_target_read_file(@xe_file, NULL, NULL, NULL) AS xef
)
SELECT
    e.event_name,
    oc.name        AS payload_field,
    oc.type_name   AS xe_type_name,
    oc.column_type,
    oc.description
FROM events_in_file e
JOIN sys.dm_xe_objects o
    ON o.name = e.event_name
   AND o.object_type = 'event'
JOIN sys.dm_xe_object_columns oc
    ON oc.object_name = o.name
   AND oc.object_package_guid = o.package_guid
   AND oc.column_type = 'data'
ORDER BY e.event_name, oc.name;

GO

-- Get all the event field names from the file
DECLARE @xe_file nvarchar(260) = ''
SELECT event_name, field_name
FROM 
(
	SELECT TOP 100
		event_xml.value('(event/@name)[1]', 'nvarchar(256)') AS event_name,
		data.value('(@name)[1]', 'nvarchar(256)') AS field_name
	FROM 
		sys.fn_xe_file_target_read_file(
			@xe_file, 
			NULL, NULL, NULL
		) AS xef
	CROSS APPLY 
		(SELECT CAST(xef.event_data AS XML) AS event_xml) AS xml_data
	CROSS APPLY 
		event_xml.nodes('//event/data') AS event_fields(data)
) base
GROUP BY event_name, field_name
GO

-- Query the file for basic information
DECLARE @xe_file nvarchar(260) = ''
SELECT
	xdata.value('(/event/@name)[1]', 'varchar(max)') AS [event]
	, xdata.value('(/event/@timestamp)[1]', 'varchar(max)') AS [timestamp] 
	, xdata.value('(/event/data[@name="duration"]/value)[1]', 'int')/1000 AS [duration_ms]
	, xdata.value('(/event/data[@name="cpu_time"]/value)[1]', 'int')/1000 AS [cpu_time_ms]
	, xdata.value('(/event/data[@name="logical_reads"]/value)[1]', 'int') AS [logical_reads]
	, xdata.value('(/event/data[@name="writes"]/value)[1]', 'int') AS [writes]
	, xdata.value('(/event/data[@name="row_count"]/value)[1]', 'int') AS [row_count]
	, xdata.value('(/event/data[@name="statement"]/value)[1]', 'varchar(max)') AS [statement]
	, xdata.value('(/event/action[@name="client_app_name"]/value)[1]', 'varchar(100)') AS [client_app_name]
	, xdata.value('(/event/action[@name="client_hostname"]/value)[1]', 'varchar(100)') AS [client_hostname]
	, xdata.value('(/event/action[@name="database_id"]/value)[1]', 'int') AS [database_id]
	, xdata.value('(/event/action[@name="database_name"]/value)[1]', 'sysname') AS [database_name]
	, xdata.value('(/event/action[@name="nt_username"]/value)[1]', 'sysname') AS [nt_username]
FROM
(
	select CAST(event_data AS XML) 
		from sys.fn_xe_file_target_read_file(@xe_file, NULL, NULL, NULL)
)  as xmlr(xdata)
WHERE xdata.value('(/event/action[@name="database_name"]/value)[1]', 'sysname') != 'master'
ORDER BY duration_ms DESC



SELECT
	xdata.value('(/event/@name)[1]', 'varchar(max)') AS [event]
	, xdata.value('(/event/@timestamp)[1]', 'varchar(max)') AS [timestamp] 
	, xdata.value('(/event/data[@name="duration"]/value)[1]', 'int')/1000 AS [duration_ms]
	, xdata.value('(/event/data[@name="cpu_time"]/value)[1]', 'int')/1000 AS [cpu_time_ms]
	, xdata.value('(/event/data[@name="logical_reads"]/value)[1]', 'int') AS [logical_reads]
	, xdata.value('(/event/data[@name="writes"]/value)[1]', 'int') AS [writes]
	, xdata.value('(/event/data[@name="row_count"]/value)[1]', 'int') AS [row_count]
	, xdata.value('(/event/data[@name="statement"]/value)[1]', 'varchar(max)') AS [statement]
	, xdata.value('(/event/action[@name="client_app_name"]/value)[1]', 'varchar(100)') AS [client_app_name]
	, xdata.value('(/event/action[@name="client_hostname"]/value)[1]', 'varchar(100)') AS [client_hostname]
	, xdata.value('(/event/action[@name="database_id"]/value)[1]', 'int') AS [database_id]
	, xdata.value('(/event/action[@name="database_name"]/value)[1]', 'sysname') AS [database_name]
	, xdata.value('(/event/action[@name="nt_username"]/value)[1]', 'sysname') AS [nt_username]
FROM
(
	select CAST(event_data AS XML) 
		from sys.fn_xe_file_target_read_file('F:\Mounts\Data\Data01\SQLDATA\MSSQL11.MSSQLSERVER\MSSQL\Log\Performance Test Trace - Long running queries_0_130367671369620000.xel', NULL, NULL, NULL)
)  as xmlr(xdata)
WHERE xdata.value('(/event/action[@name="database_name"]/value)[1]', 'sysname') != 'master'
ORDER BY duration_ms DESC



/* Query Performance Trace file for sql_statement_completed and sql_batch_completed */

DECLARE @xe_file nvarchar(260) =
  N'G:\logs\extended-events\Performance Trace_0_134159891711350000.xel';

WITH XEvents AS
(
    SELECT CAST(event_data AS xml) AS xdata
    FROM sys.fn_xe_file_target_read_file(@xe_file, NULL, NULL, NULL)
)
SELECT
      xdata.value('(/event/@name)[1]', 'sysname') AS [event]
    , xdata.value('(/event/@timestamp)[1]', 'datetime2(3)') AS [timestamp]

    , xdata.value('(/event/data[@name="duration"]/value)[1]', 'bigint') / 1000 AS [duration_ms]
    , xdata.value('(/event/data[@name="cpu_time"]/value)[1]', 'bigint') / 1000 AS [cpu_time_ms]
    , xdata.value('(/event/data[@name="logical_reads"]/value)[1]', 'bigint') AS [logical_reads]
	, xdata.value('(/event/data[@name="page_server_reads"]/value)[1]', 'bigint') AS [page_server_reads]
	, xdata.value('(/event/data[@name="physical_reads"]/value)[1]', 'bigint') AS [physical_reads]
    , xdata.value('(/event/data[@name="writes"]/value)[1]', 'bigint') AS [writes]
    , xdata.value('(/event/data[@name="row_count"]/value)[1]', 'bigint') AS [row_count]
	, xdata.value('(/event/data[@name="spills"]/value)[1]', 'bigint') AS spills
	
    -- Present for sql_statement_completed
    , CASE WHEN xdata.exist('/event/data[@name="statement"]/value') = 1
           THEN xdata.value('(/event/data[@name="statement"]/value)[1]', 'nvarchar(max)')
      END AS [statement]
	, CASE WHEN xdata.exist('/event/data[@name="last_row_count"]/value') = 1
           THEN xdata.value('(/event/data[@name="last_row_count"]/value)[1]', 'bigint')
      END AS last_row_count
	, CASE WHEN xdata.exist('/event/data[@name="line_number"]/value') = 1
           THEN xdata.value('(/event/data[@name="line_number"]/value)[1]', 'int')
      END AS [line_number]
	, CASE WHEN xdata.exist('/event/data[@name="offset"]/value') = 1
           THEN xdata.value('(/event/data[@name="offset"]/value)[1]', 'int')
      END AS [offset]
	, CASE WHEN xdata.exist('/event/data[@name="offset_end"]/value') = 1
           THEN xdata.value('(/event/data[@name="offset_end"]/value)[1]', 'int')
      END AS [offset_end]
	
    -- Present for sql_batch_completed (if that event includes batch_text)
    , CASE WHEN xdata.exist('/event/data[@name="batch_text"]/value') = 1
           THEN xdata.value('(/event/data[@name="batch_text"]/value)[1]', 'nvarchar(max)')
      END AS [batch_text]

    , xdata.value('(/event/action[@name="client_app_name"]/value)[1]', 'nvarchar(100)') AS [client_app_name]
    , xdata.value('(/event/action[@name="client_hostname"]/value)[1]', 'nvarchar(100)') AS [client_hostname]
    , xdata.value('(/event/action[@name="database_id"]/value)[1]', 'int') AS [database_id]
    , xdata.value('(/event/action[@name="database_name"]/value)[1]', 'sysname') AS [database_name]
    , xdata.value('(/event/action[@name="nt_username"]/value)[1]', 'sysname') AS [nt_username]
    , xdata.value('(/event/action[@name="query_hash"]/value)[1]', 'binary(8)') AS [query_hash]
    , xdata.value('(/event/action[@name="query_plan_hash"]/value)[1]', 'binary(8)') AS [query_plan_hash]
FROM XEvents
WHERE xdata.value('(/event/action[@name="database_name"]/value)[1]', 'sysname') <> 'master'
ORDER BY [duration_ms] DESC;





-- Write the query (using double queries to avoid long running reads of file)
--SELECT *
--FROM 
--(
	SELECT TOP 100
		xdata.value('(/event/@name)[1]', 'varchar(max)') AS [event]
		, xdata.value('(/event/@timestamp)[1]', 'varchar(max)') AS [timestamp] 
		, xdata.value('(/event/data[@name="duration"]/value)[1]', 'int')/1000 AS [duration_ms]
		, xdata.value('(/event/data[@name="cpu_time"]/value)[1]', 'int')/1000 AS [cpu_time_ms]
		, xdata.value('(/event/data[@name="logical_reads"]/value)[1]', 'int') AS [logical_reads]
		, xdata.value('(/event/data[@name="page_server_reads"]/value)[1]', 'int') AS [page_server_reads]
		, xdata.value('(/event/data[@name="physical_reads"]/value)[1]', 'int') AS [physical_reads]
		, xdata.value('(/event/data[@name="writes"]/value)[1]', 'int') AS [writes]
		, xdata.value('(/event/data[@name="row_count"]/value)[1]', 'int') AS [row_count]
		, xdata.value('(/event/data[@name="statement"]/value)[1]', 'varchar(max)') AS [statement]
		, xdata.value('(/event/data[@name="batch_text"]/value)[1]', 'varchar(max)') AS [batch_text]
		, xdata.value('(/event/data[@name="result"]/value)[1]', 'int') AS [result]
		, xdata.value('(/event/data[@name="spills"]/value)[1]', 'int') AS [spills]
		, xdata.value('(/event/action[@name="client_app_name"]/value)[1]', 'varchar(100)') AS [client_app_name]
		, xdata.value('(/event/action[@name="client_hostname"]/value)[1]', 'varchar(100)') AS [client_hostname]
		, xdata.value('(/event/action[@name="database_id"]/value)[1]', 'int') AS [database_id]
		, xdata.value('(/event/action[@name="database_name"]/value)[1]', 'sysname') AS [database_name]
		, xdata.value('(/event/action[@name="nt_username"]/value)[1]', 'sysname') AS [nt_username]
		, xdata.value('(/event/action[@name="query_hash"]/value)[1]', 'nvarchar(25)') AS [query_hash]
		, xdata.value('(/event/action[@name="query_plan_hash"]/value)[1]', 'nvarchar(256)') AS [query_plan_hash]
	FROM
	(
		SELECT CAST(event_data AS XML) 
			FROM sys.fn_xe_file_target_read_file
			(
				'G:\xe-logs\Performance Test Trace_0_134006778528650000.xel'
				, NULL
				, NULL
				, NULL
			)
	)  AS xmlr(xdata)
	WHERE 
		-- Not master db
		xdata.value('(/event/action[@name="database_name"]/value)[1]', 'sysname') != 'master'
		-- Check for reads and writes. If no reads or writes then it's only a metadata operation.
		AND
		(
			xdata.value('(/event/data[@name="logical_reads"]/value)[1]', 'int') > 0
			OR
			xdata.value('(/event/data[@name="writes"]/value)[1]', 'int') > 0
		)
		-- Filter for the client app name
		AND
		(
			xdata.value('(/event/action[@name="client_app_name"]/value)[1]', 'nvarchar(100)') = N'cLA'
		)
--) base
ORDER BY 
	duration_ms DESC
GO