DECLARE @database_id nvarchar(2) = N'18';
DECLARE  @exec_stmt nvarchar(4000);

SELECT @exec_stmt = N'
CREATE EVENT SESSION [workload capture] ON SERVER 
ADD EVENT sqlserver.rpc_completed(
    SET collect_data_stream=(1)
    ACTION(
        sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,
        sqlserver.nt_username,sqlserver.plan_handle,sqlserver.server_principal_name,sqlserver.session_id,
        sqlserver.session_nt_username,sqlserver.sql_text
    )
    WHERE (
        (
            ([package0].[greater_than_uint64]([sqlserver].[database_id],(4))) AND 
            ([package0].[equal_boolean]([sqlserver].[is_system],(0)))) AND 
            ([sqlserver].[database_id]=(' + @database_id + N'18))
        )
),
ADD EVENT sqlserver.sp_statement_completed(
    ACTION(
        sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,
        sqlserver.nt_username,sqlserver.plan_handle,sqlserver.server_principal_name,sqlserver.session_id,
        sqlserver.session_nt_username,sqlserver.sql_text
    )
    WHERE (
        (
            ([package0].[greater_than_uint64]([sqlserver].[database_id],(4))) AND 
            ([package0].[equal_boolean]([sqlserver].[is_system],(0)))) AND 
            ([sqlserver].[database_id]=(' + @database_id + N')
        )
    )
),
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(
        sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,
        sqlserver.nt_username,sqlserver.plan_handle,sqlserver.server_principal_name,sqlserver.session_id,
        sqlserver.session_nt_username,sqlserver.sql_text
    )
    WHERE (
        (
            ([package0].[greater_than_uint64]([sqlserver].[database_id],(4))) AND 
            ([package0].[equal_boolean]([sqlserver].[is_system],(0)))) AND 
            ([sqlserver].[database_id]=(' + @database_id + N')
		)
    )
)
ADD TARGET package0.ring_buffer(SET max_memory=(512000))
WITH (
    MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,
    MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=OFF
)
';

EXECUTE (@exec_stmt);

GO


-- Database scoped for Azure SQL Database

DECLARE @database_name nvarchar(20) = N'toystore';
DECLARE @exec_stmt nvarchar(4000);

SELECT @exec_stmt = N'
CREATE EVENT SESSION [sql statement capture] ON DATABASE 
ADD EVENT sqlserver.sql_batch_completed(
	ACTION(
        sqlserver.client_app_name, sqlserver.client_hostname, sqlserver.database_id, sqlserver.database_name,
        sqlserver.num_response_rows, sqlserver.plan_handle, sqlserver.query_hash, sqlserver.query_plan_hash, 
		sqlserver.request_id, sqlserver.session_id, sqlserver.sql_text, sqlserver.username
    )
    WHERE (
        (
            [sqlserver].[database_name]=N''' + @database_name + '''
		)
    )
),
ADD EVENT sqlserver.sql_statement_completed(
	ACTION(
        sqlserver.client_app_name, sqlserver.client_hostname, sqlserver.database_id, sqlserver.database_name,
        sqlserver.num_response_rows, sqlserver.plan_handle, sqlserver.query_hash, sqlserver.query_plan_hash, 
		sqlserver.request_id, sqlserver.session_id, sqlserver.sql_text, sqlserver.username
    )
    WHERE (
        (
            [sqlserver].[database_name]=N''' + @database_name + '''
		)
    )
)
ADD TARGET package0.ring_buffer(
	SET max_memory=(102400) -- Units of KB
)
WITH (
    MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,
    MAX_EVENT_SIZE=4096 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF
)'
EXECUTE (@exec_stmt);
GO

-- Start the Event Session
ALTER EVENT SESSION [sql statement capture]
    ON DATABASE
    STATE = START;
GO

-- Stop the Event Session
ALTER EVENT SESSION [sql statement capture]
    ON DATABASE
    STATE = STOP;
GO

DROP EVENT SESSION [sql statement capture] ON DATABASE
GO

DROP TABLE #XEventData
GO
-- Get the target data into temporary table
SELECT
    se.name   AS [XEventSession],
    ev.event_name,
    ac.action_name,
    st.target_name,
    se.session_source,
    st.target_data,
    CAST(st.target_data AS XML)  AS [target_data_XML]
into #XEventData
FROM
    sys.dm_xe_database_session_event_actions  AS ac

    INNER JOIN sys.dm_xe_database_session_events         AS ev  ON ev.event_name = ac.event_name
        AND CAST(ev.event_session_address AS BINARY(8)) = CAST(ac.event_session_address AS BINARY(8))

    INNER JOIN sys.dm_xe_database_session_object_columns AS oc
         ON CAST(oc.event_session_address AS BINARY(8)) = CAST(ac.event_session_address AS BINARY(8))

    INNER JOIN sys.dm_xe_database_session_targets        AS st
         ON CAST(st.event_session_address AS BINARY(8)) = CAST(ac.event_session_address AS BINARY(8))

    INNER JOIN sys.dm_xe_database_sessions               AS se
         ON CAST(ac.event_session_address AS BINARY(8)) = CAST(se.address AS BINARY(8))
WHERE
        oc.column_name = 'occurrence_number'
    AND
        se.name        = 'sql statement capture'
    AND
        ac.action_name = 'sql_text'
ORDER BY
    se.name,
    ev.event_name,
    ac.action_name,
    st.target_name,
    se.session_source
;
GO
-- SELECT * FROM #XEventData

SELECT 
	xed.event_data.value('(@name)', 'nvarchar(max)') AS [event],
	xed.event_data.value('(@timestamp)', 'nvarchar(max)') AS [timestamp],
	xed.event_data.value('(data[@name="duration"]/value)[1]', 'int')/1000 AS [duration_ms],
	xed.event_data.value('(data[@name="cpu_time"]/value)[1]', 'int')/1000 AS [cpu_time_ms],
	xed.event_data.value('(data[@name="physical_reads"]/value)[1]', 'int') AS [physical_reads],
	xed.event_data.value('(data[@name="logical_reads"]/value)[1]', 'int') AS [logical_reads],
	xed.event_data.value('(data[@name="writes"]/value)[1]', 'int') AS [writes],
	xed.event_data.value('(data[@name="spills"]/value)[1]', 'int') AS [spills],
	xed.event_data.value('(data[@name="row_count"]/value)[1]', 'int') AS [row_count],
	xed.event_data.value('(data[@name="statement"]/value)[1]', 'nvarchar(max)') AS [statement],
	xed.event_data.value('(data[@name="batch_text"]/value)[1]', 'nvarchar(max)') AS [batch_text],
	xed.event_data.value('(action[@name="sql_text"]/value)[1]', 'nvarchar(max)') AS [sql_text],
	xed.event_data.value('(action[@name="client_app_name"]/value)[1]', 'nvarchar(max)') AS [client_app_name],
	xed.event_data.value('(action[@name="client_host_name"]/value)[1]', 'nvarchar(max)') AS [client_host_name],
	xed.event_data.value('(action[@name="database_id"]/value)[1]', 'int') AS [database_id],
	xed.event_data.value('(action[@name="database_name"]/value)[1]', 'nvarchar(max)') AS [database_name],
	xed.event_data.value('(action[@name="username"]/value)[1]', 'nvarchar(max)') AS [username],
	xed.event_data.value('(action[@name="session_id"]/value)[1]', 'int') AS [session_id],
	xed.event_data.value('(action[@name="request_id"]/value)[1]', 'int') AS [request_id],
	xed.event_data.value('(action[@name="plan_handle"]/value)[1]', 'varbinary(200)') AS [request_id],
	xed.event_data.value('(action[@name="query_plan_hash"]/value)[1]', 'varbinary(16)') AS [query_plan_hash],
	xed.event_data.value('(action[@name="query_hash"]/value)[1]', 'varbinary(16)') AS [query_hash],
	xed.event_data.value('(action[@name="num_response_rows"]/value)[1]', 'int') AS [num_response_rows]
	FROM #XEventData
	CROSS APPLY target_data_XML.nodes('//RingBufferTarget/event') AS xed (event_data)



DROP TABLE #XEventData