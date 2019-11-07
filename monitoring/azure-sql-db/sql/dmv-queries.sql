--<<<<<<<<<<----------------------------------------------------------------->>>>>>>>>>--
--DMV_All-Stars.sql
    --Jimmy May 317.590.8650
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
--<<<<<<<<<<----------------------------------------------------------------->>>>>>>>>>--
--Weasel Clause: This script is provided "AS IS" with no warranties, and confers no rights. 
--  Use of included script samples are subject to the terms specified at 
--  http://www.microsoft.com/info/cpyright.htm
--<<<<<<<<<<----------------------------------------------------------------->>>>>>>>>>--

--1. expensive queries
    --text *and* statement
    --usage: modify WHERE & ORDER BY clauses to suit circumstances
SELECT --TOP 10
      -- the following four columns are NULL for ad hoc and prepared batches
      DB_Name(qp.dbid) as dbname , qp.dbid , qp.objectid , qp.number 
    --, qp.query_plan --the query plan can be *very* useful; enable if desired
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
    , qs.plan_generation_num, qs.query_hash  -- , qp.encrypted 
    , REPLACE(REPLACE(REPLACE(SUBSTRING(qt.text, (qs.statement_start_offset/2) + 1,
        ((CASE statement_end_offset 
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE qs.statement_end_offset END 
                - qs.statement_start_offset)/2) + 1), CHAR(10), ' '), CHAR(13), ''), CHAR(9), ' ') as statement_text
    , REPLACE(REPLACE(REPLACE(qt.text, CHAR(10), ' '), CHAR(13), ''), CHAR(9), ' ') AS [text]
    FROM sys.dm_exec_query_stats as qs 
    CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) as qp
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
    --WHERE...
    --ORDER BY qs.execution_count      DESC  --Frequency
      ORDER BY qs.total_worker_time    DESC  --CPU
    --ORDER BY qs.total_elapsed_time   DESC  --Durn
    --ORDER BY qs.total_logical_reads  DESC  --Reads 
    --ORDER BY qs.total_logical_writes DESC  --Writes
    --ORDER BY qs.total_physical_reads DESC  --PhysicalReads    
    --ORDER BY avg_worker_time         DESC  --AvgCPU
    --ORDER BY avg_elapsed_time        DESC  --AvgDurn     
    --ORDER BY avg_logical_reads       DESC  --AvgReads
    --ORDER BY avg_logical_writes      DESC  --AvgWrites
    --ORDER BY avg_physical_reads      DESC  --AvgPhysicalReads

    --sample WHERE clauses
    --WHERE last_execution_time > '20070507 15:00'
    --WHERE execution_count = 1
    --  WHERE SUBSTRING(qt.text, (qs.statement_start_offset/2) + 1,
    --    ((CASE statement_end_offset 
    --        WHEN -1 THEN DATALENGTH(qt.text)
    --        ELSE qs.statement_end_offset END 
    --            - qs.statement_start_offset)/2) + 1)
    --      LIKE '%MyText%'




-- Execute in master database 
-- Get utilization in last 6 hours for a database 
Declare 
    @StartTime DATETIME = DATEADD(HH,-3,GetUTCDate()), 
    @EndTime DATETIME = GetUTCDate(),
    @dbname varchar(20) = 'toystore' 
SELECT 
    database_name, 
    start_time, 
    end_time, 
    avg_cpu_percent, 
    avg_data_io_percent, 
    avg_log_write_percent, 
    ( 
        SELECT Max(v) 
        FROM (
            VALUES (avg_cpu_percent), (avg_data_io_percent), (avg_ log_write_ percent)
        ) AS value(v)
    ) AS [avg_DTU_percent] 
FROM sys.resource_stats 
WHERE database_name = @dbname 
    AND start_time BETWEEN @StartTime AND @ EndTime 
ORDER BY avg_cpu_percent desc 

-- Get avg_cpu_utilization across databases in last 14 days
SELECT 
    database_name, 
    AVG(avg_cpu_percent) AS avg_cpu_percent 
FROM sys.resource_stats 
GROUP BY database_name 
ORDER BY avg_cpu_percent DESC

-- Get Average CPU, Data IO, Log IO and Memory utilization
-- Execute in user database
SELECT    
    AVG(avg_cpu_percent) AS avg_cpu_percent,   
    AVG(avg_data_io_percent) AS avg_data_io_percent,   
    AVG(avg_log_write_percent) AS avg_log_write_percent,   
    AVG(avg_memory_usage_percent) AS avg_memory_usage_percent
FROM sys.dm_db_resource_stats;
GO
-- Get the Average DTU utilization for user database
-- Execute in user database
SELECT    
   end_time,   
  (SELECT Max(v)    
   FROM (VALUES (avg_cpu_percent), (avg_data_io_percent), (avg_log_write_percent)) AS    
   value(v)) AS [avg_DTU_percent]   
FROM sys.dm_db_resource_stats
ORDER BY end_time DESC
GO

-- Get all sessions for a user
-- Execute in master or the user database
DECLARE @username varchar(20) = 'sqladmin'
SELECT 
	session_id, 
	program_name, 
	status,
	reads, 
	writes,
	logical_reads 
from sys.dm_exec_sessions WHERE login_name=@username
GO

-- Get all the requests for the login sqladmin
DECLARE @username varchar(20) = 'sqladmin'
SELECT 
	s.session_id,
	s.status AS session_status,
	r.status AS request_status, 
	r.cpu_time, 
	r.total_elapsed_time,
	r.writes,
	r.logical_reads,
	t.Text AS query_batch_text,
	SUBSTRING(t.text, (r.statement_start_offset/2)+1,   
        ((CASE r.statement_end_offset  
          WHEN -1 THEN DATALENGTH(t.text)  
         ELSE r.statement_end_offset  
         END - r.statement_start_offset)/2) + 1) AS running_query_text 
FROM sys.dm_exec_sessions s join  sys.dm_exec_requests r 
ON r.session_id=s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
WHERE s.login_name=@username

GO
-- top 5 CPU intensive queries
SELECT 
	TOP 5 
	(total_worker_time/execution_count)/(1000*1000) AS [Avg CPU Time(Seconds)],  
    SUBSTRING(st.text, (qs.statement_start_offset/2)+1,   
        ((CASE qs.statement_end_offset  
          WHEN -1 THEN DATALENGTH(st.text)  
         ELSE qs.statement_end_offset  
         END - qs.statement_start_offset)/2) + 1) AS statement_text,
	qs.execution_count, 
	(qs.total_elapsed_time/execution_count)/(1000*1000) AS [Avg Duration(Seconds)] 
FROM sys.dm_exec_query_stats AS qs  
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st  
ORDER BY total_worker_time/execution_count DESC;  

-- top 5 long running queries
SELECT 
	TOP 5 
	(total_worker_time/execution_count)/(1000*1000) AS [Avg CPU Time(Seconds)],  
    SUBSTRING(st.text, (qs.statement_start_offset/2)+1,   
        ((CASE qs.statement_end_offset  
          WHEN -1 THEN DATALENGTH(st.text)  
         ELSE qs.statement_end_offset  
         END - qs.statement_start_offset)/2) + 1) AS statement_text,
	qs.execution_count, 
	(qs.total_elapsed_time/execution_count)/(1000*1000) AS [Avg Duration(Seconds)] 
FROM sys.dm_exec_query_stats AS qs  
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st  
ORDER BY (qs.total_elapsed_time/execution_count) DESC;  

-- Get blocked queries
SELECT   
  w.session_id
 ,w.wait_duration_ms
 ,w.wait_type
 ,w.blocking_session_id
 ,w.resource_description
 ,t.text
FROM sys.dm_os_waiting_tasks w
INNER JOIN sys.dm_exec_requests r
ON w.session_id = r.session_id
CROSS APPLY sys.dm_exec_sql_text (r.sql_handle) t
WHERE w.blocking_session_id>0
GO
