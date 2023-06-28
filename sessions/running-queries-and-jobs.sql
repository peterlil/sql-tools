
SELECT s.session_id, c.client_net_address, inbuf.event_info AS sql_text, s.last_request_start_time, s.[status], s.*
FROM sys.dm_exec_sessions s
INNER JOIN sys.dm_exec_connections c ON s.session_id = c.session_id
CROSS APPLY sys.dm_exec_input_buffer(s.session_id,0) inbuf
WHERE inbuf.event_info IS NOT NULL
	--AND LEFT(c.client_net_address, 7) = '192.168'
	--AND s.[status] = 'running'
	--AND inbuf.event_info = 'MSS_Staging.dbo.0_main_staging;1'
