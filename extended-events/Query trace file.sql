
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