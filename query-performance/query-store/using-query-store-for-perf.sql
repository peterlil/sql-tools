/************************************************
 * Troubleshooting with Query store             *
 ************************************************/


/*
 * Check if querystore is enabled and what features that are used.
 * Run this query in the target database.
 */
SELECT * 
FROM sys.database_query_store_options
GO

/*
 * Turn on query store by using this statement per db
 */
ALTER DATABASE <database_name>
SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE);
GO

/*
 * Use this query to:
 *   - Find queries with long execution times
 */
 
SELECT TOP 50 
	  rs.runtime_stats_id
	, p.plan_id
	, q.query_id
	, qt.query_text_id
	, qt.query_sql_text
	, rs.count_executions
	, rs.max_duration / 1000 AS max_duration_in_ms -- Use ms, seconds or minutes depending on your circumstances
	, rs.avg_duration / 1000 AS avg_duration_in_ms -- Use ms, seconds or minutes depending on your circumstances
	, ROUND(rs.min_duration / 1000, 0) AS min_duration_in_ms -- Use ms, seconds or minutes depending on your circumstances
	--, rs.max_duration / 1000000 AS max_duration_in_seconds -- Use ms, seconds or minutes depending on your circumstances
	--, rs.avg_duration / 1000000 AS avg_duration_in_seconds -- Use ms, seconds or minutes depending on your circumstances
	--, ROUND(rs.min_duration / 1000000, 0) AS min_duration_in_seconds -- Use ms, seconds or minutes depending on your circumstances
	--, rs.max_duration / 60000000 AS max_duration_in_minutes -- Use ms, seconds or minutes depending on your circumstances
	--, ROUND(rs.avg_duration / 60000000, 0) AS avg_duration_in_minutes -- Use ms, seconds or minutes depending on your circumstances
	--, rs.min_duration / 60000000 AS min_duration_in_minutes -- Use ms, seconds or minutes depending on your circumstances
	, rs.max_rowcount, ROUND(rs.avg_rowcount, 0) AS avg_rowcount, rs.min_rowcount
	, CONVERT(nvarchar(30), rsi.start_time, 120) as rsi_start_time
	, CONVERT(nvarchar(30), rsi.end_time, 120) as rsi_endtime
	, rs.last_execution_time
	--, rs.*, rsi.*, p.*
FROM sys.query_store_runtime_stats rs
INNER JOIN sys.query_store_runtime_stats_interval rsi ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
INNER JOIN sys.query_store_plan p ON rs.plan_id = p.plan_id
INNER JOIN sys.query_store_query q ON p.query_id = q.query_id
INNER JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
WHERE 
	execution_type = 0 -- regular execution (successfully finished)
--	AND q.query_id NOT IN (4524, 1058, 1521, 6911, 140/* 1520*/) -- Add/remove query ids here narrow down to the queries you are looking for
	--AND q.query_id IN (15654) -- When you found the query, comment row above and select only that query here, and you will get the list of plans for that query
	AND rsi.start_time > DATEADD(day, -7, GETDATE())
	--AND rsi.start_time >= '2021-09-27 09:00:00.000' AND rsi.end_time <= '2021-09-27 10:00:00.000'
ORDER BY 
	rs.max_duration DESC
	--rsi.start_time desc


/*
 * Use this query to:
 *   - Find queries with most logical reads
 */
 
SELECT TOP 50 
	  rs.runtime_stats_id
	, p.plan_id
	, q.query_id
	, qt.query_text_id
	, qt.query_sql_text
	, rs.count_executions
	/* Duration */
	, rs.max_duration / 1000 AS max_duration_in_ms -- Use ms, seconds or minutes depending on your circumstances
	, rs.avg_duration / 1000 AS avg_duration_in_ms -- Use ms, seconds or minutes depending on your circumstances
	, ROUND(rs.min_duration / 1000, 0) AS min_duration_in_ms -- Use ms, seconds or minutes depending on your circumstances
	--, rs.max_duration / 1000000 AS max_duration_in_seconds -- Use ms, seconds or minutes depending on your circumstances
	--, rs.avg_duration / 1000000 AS avg_duration_in_seconds -- Use ms, seconds or minutes depending on your circumstances
	--, ROUND(rs.min_duration / 1000000, 0) AS min_duration_in_seconds -- Use ms, seconds or minutes depending on your circumstances
	--, rs.max_duration / 60000000 AS max_duration_in_minutes -- Use ms, seconds or minutes depending on your circumstances
	--, ROUND(rs.avg_duration / 60000000, 0) AS avg_duration_in_minutes -- Use ms, seconds or minutes depending on your circumstances
	--, rs.min_duration / 60000000 AS min_duration_in_minutes -- Use ms, seconds or minutes depending on your circumstances
	/* Logical reads (no of 8-KB pages read) */
	, rs.avg_logical_io_reads * 8 / 1024 AS avg_logical_io_reads_mb
	, rs.last_logical_io_reads * 8 / 1024 AS last_logical_io_reads_mb
	, rs.min_logical_io_reads * 8 / 1024 AS min_logical_io_reads_mb
	, rs.max_logical_io_reads * 8 / 1024 AS max_logical_io_reads_mb
	, rs.stdev_logical_io_reads * 8 / 1024 AS stdev_logical_io_reads_mb

	, rs.max_rowcount, ROUND(rs.avg_rowcount, 0) AS avg_rowcount, rs.min_rowcount
	, CONVERT(nvarchar(30), rsi.start_time, 120) as rsi_start_time
	, CONVERT(nvarchar(30), rsi.end_time, 120) as rsi_endtime
	, rs.last_execution_time
	--, rs.*, rsi.*, p.*
FROM sys.query_store_runtime_stats rs
INNER JOIN sys.query_store_runtime_stats_interval rsi ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
INNER JOIN sys.query_store_plan p ON rs.plan_id = p.plan_id
INNER JOIN sys.query_store_query q ON p.query_id = q.query_id
INNER JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
WHERE 
	execution_type = 0 -- regular execution (successfully finished)
	--	AND q.query_id NOT IN (4524, 1058, 1521, 6911, 140/* 1520*/) -- Add/remove query ids here narrow down to the queries you are looking for
	--AND q.query_id IN (15654) -- When you found the query, comment row above and select only that query here, and you will get the list of plans for that query
	AND rsi.start_time > DATEADD(day, -7, GETDATE())
	--AND rsi.start_time >= '2021-09-27 09:00:00.000' AND rsi.end_time <= '2021-09-27 10:00:00.000'
ORDER BY 
	rs.avg_logical_io_reads DESC
	--rsi.start_time desc



/*
 * Use this query to:
 *   - Find queries that take a lot of CPU
 */
SELECT --TOP 50 
	  rs.runtime_stats_id
	, p.plan_id
	, q.query_id
	, rs.execution_type
	, qt.query_text_id
	, qt.query_sql_text
	, rs.count_executions
	, ROUND(rs.avg_cpu_time / 1000, 0) AS avg_cpu_time_ms
	, ROUND(rs.last_cpu_time / 1000, 0) AS last_cpu_time_ms
	, ROUND(rs.min_cpu_time / 1000, 0) AS min_cpu_time_ms
	, ROUND(rs.max_cpu_time / 1000, 0) AS max_cpu_time_ms
	, ROUND(rs.stdev_cpu_time / 1000, 0) AS stdev_cpu_time_ms
	--, ROUND(rs.avg_cpu_time / 1000000, 0) AS avg_cpu_time_sec         
	--, ROUND(rs.last_cpu_time / 1000000, 0) AS last_cpu_time_sec
	--, ROUND(rs.min_cpu_time / 1000000, 0) AS min_cpu_time_sec
	--, ROUND(rs.max_cpu_time / 1000000, 0) AS max_cpu_time_sec
	--, ROUND(rs.stdev_cpu_time / 1000000, 0) AS stdev_cpu_time_sec
	, rs.max_duration / 1000000 AS max_duration_in_seconds			-- Use ms, seconds or minutes depending on your circumstances
	--, rs.max_duration / 60000000 AS max_duration_in_minutes			-- Use ms, seconds or minutes depending on your circumstances
	, rs.avg_duration / 1000000 AS avg_duration_in_seconds			-- Use ms, seconds or minutes depending on your circumstances
	--, ROUND(rs.avg_duration / 60000000, 0) AS avg_duration_in_minutes -- Use ms, seconds or minutes depending on your circumstances
	, ROUND(rs.min_duration / 1000000, 0) AS min_duration_in_seconds  -- Use ms, seconds or minutes depending on your circumstances
	--, rs.min_duration / 60000000 AS min_duration_in_minutes           -- Use ms, seconds or minutes depending on your circumstances
	, rs.max_rowcount, ROUND(rs.avg_rowcount, 0) AS avg_rowcount, rs.min_rowcount
	, CONVERT(nvarchar(30), rsi.start_time, 120) as rsi_start_time
	, CONVERT(nvarchar(30), rsi.end_time, 120) as rsi_endtime
	, rs.last_execution_time
	--, rs.*, rsi.*, p.*
FROM sys.query_store_runtime_stats rs
INNER JOIN sys.query_store_runtime_stats_interval rsi ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
INNER JOIN sys.query_store_plan p ON rs.plan_id = p.plan_id
INNER JOIN sys.query_store_query q ON p.query_id = q.query_id
INNER JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
WHERE 
	--execution_type = 0 -- regular execution (successfully finished)
	--AND q.query_id NOT IN (4524, 1058, 1521, 6911, 140/* 1520*/) -- Add/remove query ids here narrow down to the queries you are looking for
	--AND q.query_id IN (15654) -- When you found the query, comment row above and select only that query here, and you will get the list of plans for that query
	rsi.start_time > DATEADD(DAY, -7, GETDATE())
	--rsi.start_time >= '2021-10-15 19:00:00.000' AND rsi.end_time <= '2021-10-15 20:00:00.000'
ORDER BY 
	avg_cpu_time DESC
	--rsi.start_time desc

/*
 * Use this query to see if some plans are better than others for a specific id
 */
SELECT TOP 50 
	  rs.runtime_stats_id
	, p.plan_id
	, q.query_id
	, qt.query_text_id
	, qt.query_sql_text
	, rs.count_executions
	--, rs.max_duration / 1000000 AS max_duration_in_seconds -- Use seconds or minutes depending on your circumstances
	, rs.max_duration / 60000000 AS max_duration_in_minutes -- Use seconds or minutes depending on your circumstances
	--, rs.avg_duration / 1000000 AS avg_duration_in_seconds -- Use seconds or minutes depending on your circumstances
	, ROUND(rs.avg_duration / 60000000, 0) AS avg_duration_in_minutes -- Use seconds or minutes depending on your circumstances
	--, ROUND(rs.min_duration / 1000000, 0) AS min_duration_in_seconds -- Use seconds or minutes depending on your circumstances
	, rs.min_duration / 60000000 AS min_duration_in_minutes -- Use seconds or minutes depending on your circumstances
	, rs.max_rowcount, ROUND(rs.avg_rowcount, 0) AS avg_rowcount, rs.min_rowcount
	, CONVERT(nvarchar(30), rsi.start_time, 120) as rsi_start_time
	, CONVERT(nvarchar(30), rsi.end_time, 120) as rsi_endtime
	--, rs.*, rsi.*, p.*
FROM sys.query_store_runtime_stats rs
INNER JOIN sys.query_store_runtime_stats_interval rsi ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
INNER JOIN sys.query_store_plan p ON rs.plan_id = p.plan_id
INNER JOIN sys.query_store_query q ON p.query_id = q.query_id
INNER JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
WHERE 
	execution_type = 0 -- regular execution (successfully finished)
	AND q.query_id IN (55443) -- When you found the query, comment row above and select only that query here, and you will get the list of plans for that query
	AND rsi.start_time > DATEADD(hour, -12, GETDATE())
	--AND rsi.start_time >= '2021-09-14 23:00:00.000' AND rsi.end_time <= '2021-09-15 00:00:00.000'
ORDER BY 
	rsi.start_time desc


/*
 * Get the SQL Statement from the Query Hash
 */
SELECT q.query_id, qt.query_sql_text, q.* 
FROM sys.query_store_query q
INNER JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
WHERE q.query_hash = 0x301C509A005A2CF8
ORDER BY q.last_execution_time DESC






/*
 * Open one query plan in SSMS
 */
SELECT
	CONVERT(nvarchar(max), p.query_plan, 1) AS [processing-instruction(query_plan)]
FROM 
	sys.query_store_plan p
WHERE
	p.plan_id = 70462
FOR XML PATH('');


/*
 * Use this query to:
 *   - Look at the wait stats for a plan or query
 */
 SELECT --TOP 50 
	  rs.runtime_stats_id
	, p.plan_id
	, q.query_id
	, qt.query_text_id
	, qt.query_sql_text
	, rs.count_executions
	, ws.wait_stats_id
	, ws.wait_category
	, ws.wait_category_desc
	, ws.avg_query_wait_time_ms
	--, rs.max_duration / 1000000 AS max_duration_in_seconds -- Use seconds or minutes depending on your circumstances
	, rs.max_duration / 60000000 AS max_duration_in_minutes -- Use seconds or minutes depending on your circumstances
	--, rs.avg_duration / 1000000 AS avg_duration_in_seconds -- Use seconds or minutes depending on your circumstances
	, ROUND(rs.avg_duration / 60000000, 0) AS avg_duration_in_minutes -- Use seconds or minutes depending on your circumstances
	--, ROUND(rs.min_duration / 1000000, 0) AS min_duration_in_seconds -- Use seconds or minutes depending on your circumstances
	--, rs.min_duration / 60000000 AS min_duration_in_minutes -- Use seconds or minutes depending on your circumstances
	, rs.max_rowcount, ROUND(rs.avg_rowcount, 0) AS avg_rowcount, rs.min_rowcount
	, CONVERT(nvarchar(30), rsi.start_time, 120) as rsi_start_time
	, CONVERT(nvarchar(30), rsi.end_time, 120) as rsi_endtime
	--, rs.*, rsi.*, p.*
FROM sys.query_store_runtime_stats rs
INNER JOIN sys.query_store_runtime_stats_interval rsi ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
INNER JOIN sys.query_store_plan p ON rs.plan_id = p.plan_id
INNER JOIN sys.query_store_query q ON p.query_id = q.query_id
INNER JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
INNER JOIN sys.query_store_wait_stats ws ON p.plan_id = ws.plan_id AND rsi.runtime_stats_interval_id = ws.runtime_stats_interval_id
WHERE 
	rs.execution_type = 0 -- regular execution (successfully finished)
	AND q.query_id NOT IN(1058, 1579, 1581)
	--AND q.query_id IN (26690) -- When you found the query, comment row above and select only that query here, and you will get the list of plans for that query
	AND rsi.start_time BETWEEN '2021-09-27 08:00:00.000' AND '2021-09-27 10:00:00.000'
	--AND rsi.start_time > DATEADD(hour, -2, GETDATE())
ORDER BY 
	q.query_id ASC
	, p.plan_id ASC
	, avg_query_wait_time_ms DESC
	

/*
 * Use this to force a query plan
 */

EXEC sp_query_store_force_plan @query_id = 55443, @plan_id = 70462;