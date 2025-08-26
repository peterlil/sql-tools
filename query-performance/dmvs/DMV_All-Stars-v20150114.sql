--DMV_All-Stars.sql
--Jimmy May 
--A.C.E. Performance Team
--jimmymay@microsoft.com
--aspiringgeek@live.com
--http://blogs.msdn.com/jimmymay
--Table of Contents
--1. expensive queries
--2. wait stats
--3. virtual file stats (& virtual file latency)
--4. plan cache interrogation
--5. real-time blockers
--<<<<<<<<<<------------------------------------------->>>>>>>>>>-
--Weasel Clause: This script is provided “AS IS” with no warranties, and confers no rights.
--  Use of included script samples are subject to the terms specified at
--  http://www.microsoft.com/info/cpyright.htm
--<<<<<<<<<<------------------------------------------->>>>>>>>>>-

--1. expensive queries
--text *and* statement
--usage: modify WHERE & ORDER BY clauses to suit circumstances
SELECT TOP 25
-- the following four columns are NULL for ad hoc and prepared batches
DB_Name(qp.dbid) as dbname , qp.dbid , qp.objectid , qp.number
--, qp.query_plan -the query plan can be *very* useful; enable if desired
, qt.text
, REPLACE(REPLACE(REPLACE(SUBSTRING(qt.text, (qs.statement_start_offset/2) + 1,
        ((CASE statement_end_offset 
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE qs.statement_end_offset END 
                - qs.statement_start_offset)/2) + 1), CHAR(10), ' '), CHAR(13), ''), CHAR(9), ' ') as statement_text
    , REPLACE(REPLACE(REPLACE(qt.text, CHAR(10), ' '), CHAR(13), ''), CHAR(9), ' ') AS [statement_text]
, qs.creation_time , qs.last_execution_time , qs.execution_count
, qs.total_worker_time    / qs.execution_count as avg_worker_time
, qs.total_physical_reads / qs.execution_count as avg_physical_reads
, qs.total_logical_reads  / qs.execution_count as avg_logical_reads
, qs.total_logical_writes / qs.execution_count as avg_logical_writes
, qs.total_elapsed_time   / qs.execution_count as avg_elapsed_time
, qs.total_clr_time       / qs.execution_count as avg_clr_time
, qs.total_worker_time , qs.last_worker_time , qs.min_worker_time , qs.max_worker_time
, qs.total_physical_reads , qs.last_physical_reads , qs.min_physical_reads , qs.max_physical_reads
, qs.total_logical_reads , qs.last_logical_reads , qs.min_logical_reads , qs.max_logical_reads
, qs.total_logical_writes , qs.last_logical_writes , qs.min_logical_writes , qs.max_logical_writes
, qs.total_elapsed_time , qs.last_elapsed_time , qs.min_elapsed_time , qs.max_elapsed_time
, qs.total_clr_time , qs.last_clr_time , qs.min_clr_time , qs.max_clr_time
--, qs.sql_handle , qs.statement_start_offset , qs.statement_end_offset
, qs.plan_generation_num
, qp.encrypted
, qp.query_plan
FROM sys.dm_exec_query_stats as qs
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) as qp
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
--WHERE last_execution_time >= '2023-07-04 01:26' AND last_execution_time < '2023-07-04 04:21'
--ORDER BY qs.execution_count      DESC  --Frequency
--ORDER BY qs.total_worker_time    DESC  --CPU
ORDER BY qs.total_elapsed_time   DESC  --Durn
--ORDER BY qs.total_logical_reads  DESC  --Reads
--ORDER BY qs.total_logical_writes DESC  --Writes
--ORDER BY qs.total_physical_reads DESC  --PhysicalReads
--ORDER BY avg_worker_time         DESC  --AvgCPU
--ORDER BY avg_elapsed_time        DESC  --AvgDurn
--ORDER BY avg_logical_reads       DESC  --AvgReads
--ORDER BY avg_logical_writes      DESC  --AvgWrites
--ORDER BY avg_physical_reads      DESC  --AvgPhysicalReads
-- ORDER BY last_execution_time DESC

--sample WHERE clauses
--WHERE last_execution_time > '20070507 15:00′
--WHERE execution_count = 1
--  WHERE SUBSTRING(qt.text, (qs.statement_start_offset/2) + 1,
--    ((CASE statement_end_offset
--        WHEN -1 THEN DATALENGTH(qt.text)
--        ELSE qs.statement_end_offset END
--            - qs.statement_start_offset)/2) + 1)
--      LIKE '%MyText%'

--<<<<<<<<<<------------------------------------------->>>>>>>>>>-
--2. wait stats
--DBCC sqlperf(waitstats)
--DBCC sqlperf('sys.dm_os_wait_stats',CLEAR)  -re-initialize waitstats
SELECT * , (wait_time_ms - signal_wait_time_ms) as resource_wait_time_ms
, signal_wait_time_per_wait
= CASE WHEN waiting_tasks_count = 0
THEN 0 ELSE (signal_wait_time_ms/waiting_tasks_count) END
, resource_wait_time_per_wait
= CASE WHEN waiting_tasks_count = 0
THEN 0 ELSE ((wait_time_ms - signal_wait_time_ms)/waiting_tasks_count) END
FROM sys.dm_os_wait_stats
ORDER BY resource_wait_time_ms DESC
--ORDER BY wait_time_ms DESC
--ORDER BY signal_wait_time_ms DESC
--ORDER BY waiting_tasks_count DESC
--ORDER BY max_wait_time_ms DESC

--adapted from Paul Randal
--Wait statistics, or please tell me where it hurts
--http://www.sqlskills.com/blogs/paul/wait-statistics-or-please-tell-me-where-it-hurts
;WITH Waits AS
(SELECT
wait_type,
wait_time_ms / 1000.0 AS WaitS,
(wait_time_ms - signal_wait_time_ms) / 1000.0 AS ResourceS,
signal_wait_time_ms / 1000.0 AS SignalS,
waiting_tasks_count AS WaitCount,
100.0 * wait_time_ms / SUM (wait_time_ms) OVER() AS Percentage,
ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS RowNum
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN
( N'BROKER_EVENTHANDLER',             N'BROKER_RECEIVE_WAITFOR',    N'BROKER_TASK_STOP',                N'BROKER_TO_FLUSH',
N'BROKER_TRANSMITTER',              N'CHECKPOINT_QUEUE',          N'CHKPT',                           N'CLR_AUTO_EVENT',
N'CLR_MANUAL_EVENT',                N'CLR_SEMAPHORE',             N'DBMIRROR_DBM_EVENT',              N'DBMIRROR_EVENTS_QUEUE',
N'DBMIRROR_WORKER_QUEUE',           N'DBMIRRORING_CMD',           N'DIRTY_PAGE_POLL',                 N'DISPATCHER_QUEUE_SEMAPHORE',
N'EXECSYNC',                        N'FSAGENT',                   N'FT_IFTS_SCHEDULER_IDLE_WAIT',     N'FT_IFTSHC_MUTEX',
N'HADR_CLUSAPI_CALL',               N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
N'HADR_LOGCAPTURE_WAIT',            N'HADR_NOTIFICATION_DEQUEUE', N'HADR_TIMER_TASK',                 N'HADR_WORK_QUEUE',
N'KSOURCE_WAKEUP',                  N'LAZYWRITER_SLEEP',          N'LOGMGR_QUEUE',                    N'ONDEMAND_TASK_QUEUE',
N'PWAIT_ALL_COMPONENTS_INITIALIZED',                              N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',                N'REQUEST_FOR_DEADLOCK_SEARCH',     N'RESOURCE_QUEUE',
N'SERVER_IDLE_CHECK',               N'SLEEP_BPOOL_FLUSH',         N'SLEEP_DBSTARTUP',                 N'SLEEP_DCOMSTARTUP',
N'SLEEP_MASTERDBREADY',             N'SLEEP_MASTERMDREADY',       N'SLEEP_MASTERUPGRADED',            N'SLEEP_MSDBSTARTUP',
N'SLEEP_SYSTEMTASK',                N'SLEEP_TASK',                N'SLEEP_TEMPDBSTARTUP',             N'SNI_HTTP_ACCEPT',
N'SP_SERVER_DIAGNOSTICS_SLEEP',     N'SQLTRACE_BUFFER_FLUSH',     N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
N'SQLTRACE_WAIT_ENTRIES',           N'WAIT_FOR_RESULTS',          N'WAITFOR',                         N'WAITFOR_TASKSHUTDOWN',
N'WAIT_XTP_HOST_WAIT',              N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
N'WAIT_XTP_CKPT_CLOSE',             N'XE_DISPATCHER_JOIN',        N'XE_DISPATCHER_WAIT',              N'XE_TIMER_EVENT'
)
)
SELECT TOP 10
W1.wait_type AS WaitType,
CAST (W1.Percentage AS DECIMAL(4, 2)) AS Percentage,
CAST (W1.WaitS AS DECIMAL(14, 2)) AS Wait_Sec,
CAST (W1.ResourceS AS DECIMAL(14, 2)) AS Resource_Sec,
CAST (W1.SignalS AS DECIMAL(14, 2)) AS Signal_Sec,
W1.WaitCount AS WaitCount,
CAST ((W1.WaitS / W1.WaitCount) AS DECIMAL (14, 4)) AS AvgWait_Sec,
CAST ((W1.ResourceS / W1.WaitCount) AS DECIMAL (14, 4)) AS AvgRes_Sec,
CAST ((W1.SignalS / W1.WaitCount) AS DECIMAL (14, 4)) AS AvgSig_Sec
FROM Waits AS W1
INNER JOIN Waits AS W2 ON W2.RowNum <= W1.RowNum
GROUP BY W1.RowNum, W1.wait_type, W1.WaitS, W1.ResourceS, W1.SignalS, W1.WaitCount, W1.Percentage
HAVING SUM (W2.Percentage) - W1.Percentage < 99.9; -- percentage threshold

GO

--<<<<<<<<<<------------------------------------------->>>>>>>>>>-
--3. virtual file stats (not for Azure SQL Database)
SELECT
--virtual file latency
vReadLatency
= CASE WHEN num_of_reads = 0
THEN 0 ELSE (io_stall_read_ms/num_of_reads) END
, vWriteLatency
= CASE WHEN num_of_writes = 0
THEN 0 ELSE (io_stall_write_ms/num_of_writes) END
, vLatency
= CASE WHEN (num_of_reads = 0 AND num_of_writes = 0)
THEN 0 ELSE (io_stall/(num_of_reads + num_of_writes)) END
--avg bytes per IOP
, BytesperRead
= CASE WHEN num_of_reads = 0
THEN 0 ELSE (num_of_bytes_read/num_of_reads) END
, BytesperWrite
= CASE WHEN num_of_writes = 0
THEN 0 ELSE (num_of_bytes_written/num_of_writes) END
, BytesperTransfer
= CASE WHEN (num_of_reads = 0 AND num_of_writes = 0)
THEN 0 ELSE ((num_of_bytes_read+num_of_bytes_written)/(num_of_reads + num_of_writes)) END

, LEFT(mf.physical_name,2) as Drive
, DB_NAME(vfs.database_id) as DB
--, mf.name AS FileName
, vfs.*
, mf.physical_name
FROM sys.dm_io_virtual_file_stats(NULL,NULL) as vfs
JOIN sys.master_files as mf ON vfs.database_id = mf.database_id AND vfs.file_id = mf.file_id
--WHERE mf.type_desc = 'LOG' -- log files
--WHERE DB_NAME(vfs.database_id) IN ('tpcc','tpcc2′)
ORDER BY vLatency DESC
-- ORDER BY vReadLatency DESC
-- ORDER BY vWriteLatency DESC
--<<<<<<<<<<------------------------------------------->>>>>>>>>>-
--4. plan cache interrogation
-- note: sys.dm_exec_cached_plans is diminutive version of syscacheobjects
-- no dbid, setopts
-- we want reusable code, absence of ad hoc SQL
-- we want relatively few rows with low usecounts
--2000
SELECT cacheobjtype , objtype , usecounts , pagesused , dbid , sql
FROM master.dbo.syscacheobjects
WHERE cacheobjtype = 'Compiled Plan'
ORDER BY usecounts DESC
--ORDER BY sql
--2005
SELECT c.cacheobjtype , c.objtype , c.usecounts , c.size_in_bytes , t.dbid , t.text
FROM sys.dm_exec_cached_plans as c
CROSS APPLY sys.dm_exec_sql_text(plan_handle) as t
WHERE c.cacheobjtype = 'Compiled Plan'
ORDER BY c.usecounts DESC
--ORDER BY t.text

--<<<<<<<<<<------------------------------------------->>>>>>>>>>-
--5. real-time blockers
--Report Blocker and Waiter SQL Statements
--http://www.microsoft.com/technet/scriptcenter/scripts/sql/sql2005/trans/sql05vb044.mspx?mfr=true
-- SQLCAT BPT
SELECT
t1.resource_type as lock_type
, db_name(resource_database_id) as DB
, t1.resource_associated_entity_id as blkd_obj
, t1.request_mode as lock_req          -- lock requested
, t1.request_session_id as waiter_sid  -- spid of waiter
, t2.wait_duration_ms as waittime
, (SELECT text FROM sys.dm_exec_requests as r  -- get sql for waiter
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle)
WHERE r.session_id = t1.request_session_id) as waiter_batch
, (SELECT SUBSTRING(qt.text , r.statement_start_offset/2
, (CASE WHEN r.statement_end_offset = -1
THEN LEN(CONVERT(nvarchar(MAX), qt.text)) * 2
ELSE r.statement_end_offset END - r.statement_start_offset)/2)
FROM sys.dm_exec_requests as r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) as qt
WHERE r.session_id = t1.request_session_id) as waiter_stmt    -- this is the statement executing right now
, t2.blocking_session_id as blocker_sid -- spid of blocker
, (SELECT text FROM sys.sysprocesses as p       -- get sql for blocker
CROSS APPLY sys.dm_exec_sql_text(p.sql_handle)
WHERE p.spid = t2.blocking_session_id) as blocker_stmt
FROM sys.dm_tran_locks as t1
JOIN sys.dm_os_waiting_tasks as t2
ON t1.lock_owner_address = t2.resource_address