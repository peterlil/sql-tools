DECLARE @database_id nvarchar(2) = N'18';
DECLARE  @exec_stmt nvarchar(4096);

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
            ([sqlserver].[database_id]=(' + @database_id + N'))
        )
    )
ADD TARGET package0.ring_buffer(SET max_memory=(512000))
WITH (
    MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,
    MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=OFF
)
';

EXECUTE (@exec_stmt);