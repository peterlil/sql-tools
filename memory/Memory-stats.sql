
-- Shows how much memory SQL Server is using
SELECT 
	physical_memory_in_use_kb -- True memory that SQL is using (working set (heaps, e.t.c.), large pages, locked pages)
FROM sys.dm_os_process_memory

-- Two important measures
SELECT 
	committed_kb -- total server memory = used
	, committed_target_kb -- target server memory = ceiling
	FROM sys.dm_os_sys_info

-- DMVs
-- dm_os_memory_nodes -> a look at SQL allocation per node
-- dm_os_memory_clerks -> wher clerks (components) consuming the most
-- dm_os_memory_objects -> Look only here if you think something is wrong

-- DBCC MEMORYSTATUS
-- Check for foreign memory access by looking at these at node level:
-- Foreign Committed
-- Away Committed
-- Taken Away Committed