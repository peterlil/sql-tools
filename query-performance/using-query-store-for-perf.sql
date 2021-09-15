/************************************************
 * Troubleshooting with Query store             *
 ************************************************/


/*
 * Check if querystore is enabled and what features that are used.
 * Run this query in the target database.
 */
SELECT * 
FROM sys.database_query_store_options


/*
 * Use this query to:
 *   - Find the query you are after that had the long execution
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
	AND q.query_id NOT IN (4524, 1058, 1521, 6911, 140/* 1520*/) -- Add/remove query ids here narrow down to the queries you are looking for
	--AND q.query_id IN (15654) -- When you found the query, comment row above and select only that query here, and you will get the list of plans for that query
	AND rsi.start_time > DATEADD(hour, -2, GETDATE())
ORDER BY 
	max_duration DESC
	--rsi.start_time desc

/*
 * Open one query plan in SSMS
 */
SELECT
	CONVERT(nvarchar(max), p.query_plan, 1) AS [processing-instruction(query_plan)]
FROM 
	sys.query_store_plan p
WHERE
	p.plan_id = 30049
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
	--, rs.max_duration / 60000000 AS max_duration_in_minutes -- Use seconds or minutes depending on your circumstances
	--, rs.avg_duration / 1000000 AS avg_duration_in_seconds -- Use seconds or minutes depending on your circumstances
	--, ROUND(rs.avg_duration / 60000000, 0) AS avg_duration_in_minutes -- Use seconds or minutes depending on your circumstances
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
	AND q.query_id IN (26690) -- When you found the query, comment row above and select only that query here, and you will get the list of plans for that query
	AND rsi.start_time > DATEADD(hour, -2, GETDATE())
ORDER BY 
	q.query_id ASC
	, p.plan_id ASC
	, avg_query_wait_time_ms DESC
	
