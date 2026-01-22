
-- Find the trace file's name(s)
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
	xes.name = 'Performance Test Trace'
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