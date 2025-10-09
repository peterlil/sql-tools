# Query Store Helpers

## User query store to identify long running queries

### Find all queries and order by longest execution time

```sql

-- Find queries relative today
--DECLARE @noOfDays int = 5
--DECLARE @end_time datetime2(7) = SYSDATETIME()
--DECLARE @start_time datetime2(7) = DATEADD(D, @noOfDays * -1, @end_time)

-- Find the queries based on date and time
DECLARE @start_time datetime2(7) = '2025-09-01 00:00:00'
DECLARE @end_time datetime2(7) = '2025-10-08 23:59:59'


DECLARE @start_time_utc datetime2(7) = SWITCHOFFSET(TODATETIMEOFFSET(@start_time, '+02:00'), '+00:00');
DECLARE @end_time_utc datetime2(7) = SWITCHOFFSET(TODATETIMEOFFSET(@end_time, '+02:00'), '+00:00');
SELECT TOP 50 
	  rs.runtime_stats_id
	, p.plan_id
	, q.query_id
	, qt.query_text_id
	, qt.query_sql_text
	, rs.count_executions
	, rs.max_duration / 1000000 AS max_duration_in_seconds -- Use seconds or minutes depending on your circumstances
	, rs.avg_duration / 1000000 AS avg_duration_in_seconds -- Use seconds or minutes depending on your circumstances
	, ROUND(rs.min_duration / 1000000, 0) AS min_duration_in_seconds -- Use seconds or minutes depending on your circumstances
	--, rs.max_duration / 60000000 AS max_duration_in_minutes -- Use seconds or minutes depending on your circumstances
	--, ROUND(rs.avg_duration / 60000000, 0) AS avg_duration_in_minutes -- Use seconds or minutes depending on your circumstances
	--, rs.min_duration / 60000000 AS min_duration_in_minutes -- Use seconds or minutes depending on your circumstances
	, rs.max_rowcount, ROUND(rs.avg_rowcount, 0) AS avg_rowcount, rs.min_rowcount
	, CONVERT(nvarchar(30), SWITCHOFFSET(TODATETIMEOFFSET(rsi.start_time, '+00:00'), '+02:00'), 120) as rsi_start_time
	, CONVERT(nvarchar(30), SWITCHOFFSET(TODATETIMEOFFSET(rsi.end_time, '+00:00'), '+02:00'), 120) as rsi_endtime
	, CONVERT(nvarchar(30), SWITCHOFFSET(TODATETIMEOFFSET(rs.last_execution_time, '+00:00'), '+02:00'), 120) as last_execution_time
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
	--AND rsi.start_time > DATEADD(hour, -2, GETDATE())
	rsi.start_time >= @start_time_utc AND rsi.end_time <= @end_time_utc
ORDER BY 
	max_duration DESC
	--rsi.start_time desc
GO
```

### Find the queries with execution time longer than x seconds

```sql
-- Find queries relative today
--DECLARE @noOfDays int = 5
--DECLARE @end_time datetime2(7) = SYSDATETIME()
--DECLARE @start_time datetime2(7) = DATEADD(D, @noOfDays * -1, @end_time)

-- Find the queries based on date and time
DECLARE @start_time datetime2(7) = '2025-09-01 00:00:00'
DECLARE @end_time datetime2(7) = '2025-10-08 23:59:59'


DECLARE @start_time_utc datetime2(7) = SWITCHOFFSET(TODATETIMEOFFSET(@start_time, '+02:00'), '+00:00');
DECLARE @end_time_utc datetime2(7) = SWITCHOFFSET(TODATETIMEOFFSET(@end_time, '+02:00'), '+00:00');

SELECT
    q.query_id,
    p.plan_id,
    rs.max_duration / 1000.0 AS max_duration_ms,
	qst.query_sql_text
FROM sys.query_store_runtime_stats AS rs
INNER JOIN sys.query_store_runtime_stats_interval rsi ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
JOIN sys.query_store_plan AS p ON rs.plan_id = p.plan_id
JOIN sys.query_store_query AS q ON p.query_id = q.query_id
JOIN sys.query_store_query_text AS qst ON q.query_text_id = qst.query_text_id
WHERE rs.max_duration >= 3000000 -- 3 seconds in microseconds
	AND rsi.start_time >= @start_time_utc AND rsi.end_time <= @end_time_utc
ORDER BY rs.max_duration DESC;
```

## Find when a query executed

```sql
/*
 * Get the time of when a query executed
 */
DECLARE @start_time datetime2(7) = '2025-09-01 00:00:00'
DECLARE @end_time datetime2(7) = '2025-10-08 23:59:59'
DECLARE @query_id INT = 9;

DECLARE @start_time_utc datetime2(7) = SWITCHOFFSET(TODATETIMEOFFSET(@start_time, '+02:00'), '+00:00');
DECLARE @end_time_utc datetime2(7) = SWITCHOFFSET(TODATETIMEOFFSET(@end_time, '+02:00'), '+00:00');

SELECT TOP 20
    q.query_id,
	rs.[max_duration],
	ROUND(CAST(rs.[max_duration] AS float)/1000000.0, 1) AS max_duration_s,
    rs.last_execution_time,
    qt.query_text_id,
    qt.query_sql_text,
	rs.count_executions
FROM 
    sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
JOIN sys.query_store_runtime_stats_interval rsi ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
WHERE 
    q.query_id = @query_id
  AND rs.max_duration >= 1500000
  AND rsi.start_time >= @start_time_utc
  AND rsi.end_time <= @end_time_utc
ORDER BY rs.max_duration DESC;
GO
```


## Get waits for a query

```sql
DECLARE @start_time datetime2(7) = '2025-09-28 02:00:00' -- DATEADD(D, @noOfDays * -1, @end_time)
DECLARE @end_time datetime2(7) = '2025-09-28 03:00:00' -- SYSDATETIME()
DECLARE @query_id INT = 9;

DECLARE @start_time_utc datetime2(7) = SWITCHOFFSET(TODATETIMEOFFSET(@start_time, '+02:00'), '+00:00');
DECLARE @end_time_utc datetime2(7) = SWITCHOFFSET(TODATETIMEOFFSET(@end_time, '+02:00'), '+00:00');

SELECT 
    q.query_id,
    qt.query_sql_text,
    ws.wait_category_desc,
    ws.execution_type_desc,
    ws.total_query_wait_time_ms,
    ws.avg_query_wait_time_ms,
    rsi.start_time,
    rsi.end_time
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p ON q.query_id = p.query_id
JOIN sys.query_store_wait_stats ws ON p.plan_id = ws.plan_id
JOIN sys.query_store_runtime_stats_interval rsi ON ws.runtime_stats_interval_id = rsi.runtime_stats_interval_id
WHERE q.query_id = @query_id
  AND rsi.start_time >= @start_time_utc
  AND rsi.end_time <= @end_time_utc
ORDER BY rsi.start_time;
```

## Get aborted queries 

```sql
-- aborted
DECLARE @start_time datetime2(7) = '2025-09-01 00:00:00'
DECLARE @end_time datetime2(7) = '2025-10-08 23:59:59'
DECLARE @query_id INT = 9;

DECLARE @start_time_utc datetime2(7) = SWITCHOFFSET(TODATETIMEOFFSET(@start_time, '+02:00'), '+00:00');
DECLARE @end_time_utc datetime2(7) = SWITCHOFFSET(TODATETIMEOFFSET(@end_time, '+02:00'), '+00:00');

WITH top_waits_per_interval(query_id, plan_id, runtime_stats_id, runtime_stats_interval_id, max_total_query_wait_time_ms) AS 
(
	SELECT
		q.query_id
		,p.plan_id
		,rs.runtime_stats_id
		,rsi.runtime_stats_interval_id
		,MAX(ws.total_query_wait_time_ms) as max_total_query_wait_time_ms
	FROM
		sys.query_store_query q
	JOIN sys.query_store_plan p ON q.query_id = p.query_id
	JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
	JOIN sys.query_store_runtime_stats_interval rsi ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
	JOIN sys.query_store_wait_stats ws ON p.plan_id = ws.plan_id AND rsi.runtime_stats_interval_id = ws.runtime_stats_interval_id
	WHERE 
		q.query_id = @query_id
	  AND rs.max_duration >= 5000000 -- 5s
	  AND rsi.start_time >= @start_time_utc
	  AND rsi.end_time <= @end_time_utc
	  AND rs.execution_type = 3 -- Client initiated aborted execution
	GROUP BY q.query_id, p.plan_id, rs.runtime_stats_id, rsi.runtime_stats_interval_id
) 
SELECT
	q.query_id
	,p.plan_id
	,SWITCHOFFSET(TODATETIMEOFFSET(rsi.start_time, '+00:00'), '+02:00') as start_time
    ,SWITCHOFFSET(TODATETIMEOFFSET(rsi.end_time, '+00:00'), '+02:00') as end_time
	,ROUND(CAST(rs.[max_duration] AS float)/1000000.0, 1) AS max_duration_s
	,ws.wait_category_desc
    ,ws.execution_type_desc
    ,ws.total_query_wait_time_ms
    ,CAST(ROUND(ws.avg_query_wait_time_ms, 0) AS int) AS avg_query_wait_time_ms
	,rs.count_executions
	, rs.execution_type_desc
	,qt.query_sql_text
	--ts.*
FROM top_waits_per_interval ts
  JOIN sys.query_store_query q ON ts.query_id = q.query_id
  JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
  JOIN sys.query_store_plan p ON q.query_id = p.query_id AND ts.plan_id = p.plan_id
  JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id AND ts.runtime_stats_id = rs.runtime_stats_id
  JOIN sys.query_store_runtime_stats_interval rsi ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id AND ts.runtime_stats_interval_id = rsi.runtime_stats_interval_id
  JOIN sys.query_store_wait_stats ws ON p.plan_id = ws.plan_id AND rsi.runtime_stats_interval_id = ws.runtime_stats_interval_id AND ts.max_total_query_wait_time_ms = ws.total_query_wait_time_ms
	
GO 
```