CREATE EVENT SESSION [Drive failure detection] ON SERVER 
ADD EVENT sqlos.dump_exception_routine_executed,
ADD EVENT sqlserver.availability_replica_manager_state_change,
ADD EVENT sqlserver.availability_replica_state_change,
ADD EVENT sqlserver.background_job_error,
ADD EVENT sqlserver.database_suspect_data_page,
ADD EVENT sqlserver.errorlog_written,
ADD EVENT sqlserver.failed_hresult,
ADD EVENT sqlserver.failed_hresult_msg,
ADD EVENT sqlserver.hadr_db_manager_state,
ADD EVENT sqlserver.hadr_db_manager_status_change,
ADD EVENT sqlserver.hadr_db_partner_set_sync_state,
ADD EVENT sqlserver.hadr_ddl_failover_execution_state,
ADD EVENT sqlserver.hadr_scan_state,
ADD EVENT sqlserver.hadr_transport_session_state,
ADD EVENT sqlserver.hadr_wsfc_change_notifier_node_not_online,
ADD EVENT sqlserver.hadr_wsfc_change_notifier_severe_error,
ADD EVENT sqlserver.long_io_detected,
ADD EVENT sqlserver.sp_server_diagnostics_component_result
WITH 
(
	MAX_MEMORY=4096 KB,
	EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
	MAX_DISPATCH_LATENCY=1 SECONDS,
	MAX_EVENT_SIZE=0 KB,
	MEMORY_PARTITION_MODE=NONE,
	TRACK_CAUSALITY=OFF,
	STARTUP_STATE=OFF
)
GO

