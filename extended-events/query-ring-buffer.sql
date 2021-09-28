-- Partial credit goes to Hannah Vernon. Thanks! - https://www.sqlserverscience.com/extended-events/reading-the-ring-buffer-target/


/*
 * Use for performance trace 
 */

DECLARE @ExtendedEventsSessionName sysname = N'Query performance trace 2';
DECLARE @StartTime datetimeoffset;
DECLARE @EndTime datetimeoffset;
DECLARE @Offset int;
 
DROP TABLE IF EXISTS #xmlResults;
CREATE TABLE #xmlResults
(
      xeTimeStamp datetimeoffset NOT NULL
    , xeXML XML NOT NULL
);

/*
SET @StartTime = DATEADD(HOUR, -60, GETDATE()); --modify this to suit your needs
SET @EndTime = GETDATE();
SET @Offset = DATEDIFF(MINUTE, GETDATE(), GETUTCDATE());
SET @StartTime = DATEADD(MINUTE, @Offset, @StartTime);
SET @EndTime = DATEADD(MINUTE, @Offset, @EndTime);

SELECT StartTimeUTC = CONVERT(varchar(30), @StartTime, 127)
    , StartTimeLocal = CONVERT(varchar(30), DATEADD(MINUTE, 0 - @Offset, @StartTime), 120)
    , EndTimeUTC = CONVERT(varchar(30), @EndTime, 127)
    , EndTimeLocal = CONVERT(varchar(30), DATEADD(MINUTE, 0 - @Offset, @EndTime), 120);
*/ 
DECLARE @target_data xml;
SELECT @target_data = CONVERT(xml, target_data)
FROM sys.dm_xe_sessions AS s 
JOIN sys.dm_xe_session_targets AS t 
    ON t.event_session_address = s.address
WHERE s.name = @ExtendedEventsSessionName
    AND t.target_name = N'ring_buffer';
 
;WITH src AS 
(
    SELECT xeXML = xm.s.query('.')
    FROM @target_data.nodes('/RingBufferTarget/event') AS xm(s)
)
INSERT INTO #xmlResults (xeXML, xeTimeStamp)
SELECT src.xeXML
    , [xeTimeStamp] = src.xeXML.value('(/event/@timestamp)[1]', 'datetimeoffset(7)')
FROM src;
 
SELECT [TimeStamp] = CONVERT(varchar(30), DATEADD(MINUTE, 0 - @Offset, xr.xeTimeStamp), 120)
	, xr.xeXML.value('(/event/@name)[1]', 'varchar(max)') AS [event]
	, xr.xeXML.value('(/event/@timestamp)[1]', 'varchar(max)') AS [timestamp] 
	, xr.xeXML.value('(/event/action[@name="database_id"]/value)[1]', 'int') AS [database_id]
	, xr.xeXML.value('(/event/action[@name="database_name"]/value)[1]', 'sysname') AS [database_name]
	, xr.xeXML.value('(/event/data[@name="duration"]/value)[1]', 'bigint')/1000 AS [duration_ms]
	, xr.xeXML.value('(/event/data[@name="cpu_time"]/value)[1]', 'bigint')/1000 AS [cpu_time_ms]
	, xr.xeXML.value('(/event/data[@name="logical_reads"]/value)[1]', 'bigint') AS [logical_reads]
	, xr.xeXML.value('(/event/data[@name="writes"]/value)[1]', 'bigint') AS [writes]
	, xr.xeXML.value('(/event/data[@name="row_count"]/value)[1]', 'bigint') AS [row_count]
	, xr.xeXML.value('(/event/data[@name="statement"]/value)[1]', 'varchar(max)') AS [statement]
	, xr.xeXML.value('(/event/action[@name="client_app_name"]/value)[1]', 'varchar(100)') AS [client_app_name]
	, xr.xeXML.value('(/event/action[@name="client_hostname"]/value)[1]', 'varchar(100)') AS [client_hostname]
	, xr.xeXML.value('(/event/action[@name="nt_username"]/value)[1]', 'sysname') AS [nt_username]
    , xr.xeXML
FROM #xmlResults xr
/*WHERE xr.xeTimeStamp >= @StartTime
    AND xr.xeTimeStamp<= @EndTime*/
--ORDER BY duration_ms DESC;
ORDER BY xr.xeXML.value('(/event/@timestamp)[1]', 'varchar(max)') DESC;

GO

/*
 * Use for lock esclation trace 
 */

DECLARE @ExtendedEventsSessionName sysname = N'lock_escalations';
DECLARE @StartTime datetimeoffset;
DECLARE @EndTime datetimeoffset;
DECLARE @Offset int;
 
DROP TABLE IF EXISTS #xmlResults;
CREATE TABLE #xmlResults
(
      xeTimeStamp datetimeoffset NOT NULL
    , xeXML XML NOT NULL
);

/*
SET @StartTime = DATEADD(HOUR, -60, GETDATE()); --modify this to suit your needs
SET @EndTime = GETDATE();
SET @Offset = DATEDIFF(MINUTE, GETDATE(), GETUTCDATE());
SET @StartTime = DATEADD(MINUTE, @Offset, @StartTime);
SET @EndTime = DATEADD(MINUTE, @Offset, @EndTime);

SELECT StartTimeUTC = CONVERT(varchar(30), @StartTime, 127)
    , StartTimeLocal = CONVERT(varchar(30), DATEADD(MINUTE, 0 - @Offset, @StartTime), 120)
    , EndTimeUTC = CONVERT(varchar(30), @EndTime, 127)
    , EndTimeLocal = CONVERT(varchar(30), DATEADD(MINUTE, 0 - @Offset, @EndTime), 120);
*/ 
DECLARE @target_data xml;
SELECT @target_data = CONVERT(xml, target_data)
FROM sys.dm_xe_sessions AS s 
JOIN sys.dm_xe_session_targets AS t 
    ON t.event_session_address = s.address
WHERE s.name = @ExtendedEventsSessionName
    AND t.target_name = N'ring_buffer';
 
;WITH src AS 
(
    SELECT xeXML = xm.s.query('.')
    FROM @target_data.nodes('/RingBufferTarget/event') AS xm(s)
)
INSERT INTO #xmlResults (xeXML, xeTimeStamp)
SELECT src.xeXML
    , [xeTimeStamp] = src.xeXML.value('(/event/@timestamp)[1]', 'datetimeoffset(7)')
FROM src;
 
SELECT 
	  CAST(xr.xeXML.value('(/event/@timestamp)[1]', 'varchar(max)') AS DATETIME) AS [TimeStamp]
	, xr.xeXML.value('(/event/data[@name="database_id"]/value)[1]', 'int') AS [database_id]
	, xr.xeXML.value('(/event/data[@name = "resource_type"]/text)[1]', 'varchar(max)') AS [resource_type]
	, xr.xeXML.value('(/event/data[@name = "mode"]/text)[1]', 'varchar(max)') AS [lock_mode]
	, xr.xeXML.value('(/event/data[@name="statement"]/value)[1]', 'varchar(max)') AS [statement]
	, xr.xeXML.value('(/event/data[@name="object_id"]/value)[1]', 'varchar(100)') AS [object_id]
	, xr.xeXML.value('(/event/data[@name="escalation_cause"]/text)[1]', 'varchar(100)') AS [escalation_cause]
	, xr.xeXML.value('(/event/data[@name="escalated_lock_count"]/value)[1]', 'varchar(100)') AS [escalated_lock_count]
	, CONVERT(BINARY(8), CONVERT(BIGINT, xr.xeXML.value('(/event/action[@name="query_hash_signed"]/value)[1]', 'varchar(100)'))) AS [query_hash]
	, xr.xeXML.value('(/event/action[@name="client_app_name"]/value)[1]', 'varchar(100)') AS [client_app_name]
	, xr.xeXML.value('(/event/action[@name="client_hostname"]/value)[1]', 'varchar(100)') AS [client_hostname]
    , xr.xeXML
FROM #xmlResults xr
/*WHERE xr.xeTimeStamp >= @StartTime
    AND xr.xeTimeStamp<= @EndTime*/
--ORDER BY duration_ms DESC;
ORDER BY [TimeStamp] ASC;

GO



