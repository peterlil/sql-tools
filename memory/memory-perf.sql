/*****************************************************************************
 *** sys.dm_os_memory_cache_clock_hands
 *** This view contains one internal and one external clock hand for each 
 *** cache store or user store.
 *** The removed_last_round_count is specifically interesting. Large values
 *** compared to other values, or values increasing drastically, is a strong
 *** indication of memory pressure.
 *****************************************************************************/
 
SELECT name, removed_last_round_count, *
	FROM sys.dm_os_memory_cache_clock_hands
	ORDER BY 2 DESC;
	 
/*****************************************************************************
 *** Memory Broker
 *****************************************************************************/

SELECT *
	FROM sys.dm_os_ring_buffers
	WHERE ring_buffer_type = 'RING_BUFFER_MEMORY_BROKER';


/*****************************************************************************
 *** sys.dm_os_sys_info
 *****************************************************************************/
-- 2008 R2
SELECT 
	cpu_ticks,ms_ticks,cpu_count,hyperthread_ratio,physical_memory_in_bytes,
	virtual_memory_in_bytes,
	virtual_memory_in_Mbytes = virtual_memory_in_bytes/(1024*1024),
	bpool_committed,
	bpool_commit_target,
	bpool_committed_mb = (bpool_committed*8)/1024,
	bpool_commit_target_mb = (bpool_commit_target*8)/1024,bpool_visible,
	stack_size_in_bytes,os_quantum,os_error_mode,os_priority_class,
	max_workers_count,scheduler_count,scheduler_total_count,
	deadlock_monitor_serial_number,sqlserver_start_time_ms_ticks,
	sqlserver_start_time,affinity_type,affinity_type_desc,
	process_kernel_time_ms,process_user_time_ms,time_source,time_source_desc,
	virtual_machine_type,virtual_machine_type_desc
	FROM sys.dm_os_sys_info;

-- 2005 SP2	
SELECT 
	cpu_ticks,ms_ticks,cpu_count,hyperthread_ratio,physical_memory_in_bytes,
	virtual_memory_in_bytes,
	virtual_memory_in_Mbytes = virtual_memory_in_bytes/(1024*1024),
	bpool_committed,
	bpool_commit_target,
	bpool_committed_mb = (bpool_committed*8)/1024,
	bpool_commit_target_mb = (bpool_commit_target*8)/1024,bpool_visible,
	stack_size_in_bytes,os_quantum,os_error_mode,os_priority_class,
	max_workers_count,scheduler_count,scheduler_total_count,
	deadlock_monitor_serial_number
	FROM sys.dm_os_sys_info;

/*****************************************************************************
 *** sys.dm_os_memory_clerks
 *****************************************************************************/

SELECT DISTINCT type FROM sys.dm_os_memory_clerks;

SELECT * FROM sys.dm_os_memory_clerks;

/*****************************************************************************
 *** sys.dm_os_memory_cache_counters
 *****************************************************************************/

SELECT * FROM sys.dm_os_memory_cache_counters;

/*****************************************************************************
 *** sys.dm_os_memory_cache_hash_tables
 *****************************************************************************/

SELECT * FROM sys.dm_os_memory_cache_hash_tables;

