# Query store queries for multiple databases

## Waits

```sql
/*
 * Use this query to:
 *   - Find queries with>
 *		- long execution times and the corresponding wait types
 *      - high logical reads and the corresponding wait types
 *     across all online user databases with Query Store enabled.
 *
 * Note: One query with multiple wait types will have one row per wait type.
 *
 * Name: QSWAITS-MULTIDB
 */

DECLARE @start_time_local DATETIME2 = '2026-06-04 00:00:00';
DECLARE @end_time_local   DATETIME2 = '2026-06-04 04:00:00';

DECLARE @start_time_utc DATETIMEOFFSET;
DECLARE @end_time_utc   DATETIMEOFFSET;

-- First: interpret local wall-clock time as Central Europe (handles CET/CEST automatically)
-- Second: convert that moment to UTC
SELECT
	@start_time_utc = (@start_time_local AT TIME ZONE 'Central European Standard Time') AT TIME ZONE 'UTC',
	@end_time_utc   = (@end_time_local   AT TIME ZONE 'Central European Standard Time') AT TIME ZONE 'UTC';

IF OBJECT_ID('tempdb..#query_store_waits') IS NOT NULL
	DROP TABLE #query_store_waits;

CREATE TABLE #query_store_waits
(
	  database_id                INT
	, database_name              SYSNAME
	, runtime_stats_id           BIGINT
	, plan_id                    BIGINT
	, query_id                   BIGINT
	, query_text_id              BIGINT
	, query_sql_text             NVARCHAR(MAX)
	, count_executions           BIGINT
	, max_duration_in_ms         DECIMAL(19, 0)
	, avg_duration_in_ms         DECIMAL(19, 0)
	, min_duration_in_ms         DECIMAL(19, 0)
	, stdev_duration_in_ms       DECIMAL(19, 0)
	, wait_category              INT
	, wait_category_desc         NVARCHAR(60)
	, total_query_wait_time_ms   BIGINT
	, avg_query_wait_time_ms     FLOAT
	, min_query_wait_time_ms     BIGINT
	, max_query_wait_time_ms     BIGINT
	, stdev_query_wait_time_ms   FLOAT
	, avg_logical_io_reads_mb	 BIGINT
	, last_logical_io_reads_mb	 BIGINT
	, min_logical_io_reads_mb    BIGINT
	, max_logical_io_reads_mb    BIGINT
	, stdev_logical_io_reads_mb  BIGINT
	, max_rowcount               BIGINT
	, avg_rowcount               DECIMAL(19, 0)
	, min_rowcount               BIGINT
	, rsi_start_time             NVARCHAR(30)
	, rsi_endtime                NVARCHAR(30)
	, last_execution_time        DATETIMEOFFSET(7)
);

DECLARE @db_name SYSNAME;
DECLARE @db_id INT;
DECLARE @sql NVARCHAR(MAX);

DECLARE db_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT
	  d.name
	, d.database_id
FROM sys.databases AS d
WHERE d.state_desc = 'ONLINE'
  AND d.name NOT IN ('master', 'tempdb', 'model', 'msdb')
  AND d.is_query_store_on = 1
ORDER BY d.name;

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @db_name, @db_id;

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @sql = N'
	INSERT INTO #query_store_waits
	(
		  database_id
		, database_name
		, runtime_stats_id
		, plan_id
		, query_id
		, query_text_id
		, query_sql_text
		, count_executions
		, max_duration_in_ms
		, avg_duration_in_ms
		, min_duration_in_ms
		, stdev_duration_in_ms
		, wait_category
		, wait_category_desc
		, total_query_wait_time_ms
		, avg_query_wait_time_ms
		, min_query_wait_time_ms
		, max_query_wait_time_ms
		, stdev_query_wait_time_ms
		, avg_logical_io_reads_mb
		, last_logical_io_reads_mb
		, min_logical_io_reads_mb
		, max_logical_io_reads_mb
		, stdev_logical_io_reads_mb
		, max_rowcount
		, avg_rowcount
		, min_rowcount
		, rsi_start_time
		, rsi_endtime
		, last_execution_time
	)
	SELECT
		  @db_id
		, @db_name
		, rs.runtime_stats_id
		, p.plan_id
		, q.query_id
		, qt.query_text_id
		, qt.query_sql_text
		, rs.count_executions
		, ROUND(rs.max_duration / 1000.0, 0) AS max_duration_in_ms
		, ROUND(rs.avg_duration / 1000.0, 0) AS avg_duration_in_ms
		, ROUND(rs.min_duration / 1000.0, 0) AS min_duration_in_ms
		, ROUND(rs.stdev_duration / 1000.0, 0) AS stdev_duration_in_ms
		, ws.wait_category
		, ws.wait_category_desc
		, ws.total_query_wait_time_ms
		, ws.avg_query_wait_time_ms
		, ws.min_query_wait_time_ms
		, ws.max_query_wait_time_ms
		, ws.stdev_query_wait_time_ms
		, ROUND(rs.avg_logical_io_reads * 8 / 1024, 0) AS avg_logical_io_reads_mb
		, ROUND(rs.last_logical_io_reads * 8 / 1024, 0) AS last_logical_io_reads_mb
		, ROUND(rs.min_logical_io_reads * 8 / 1024, 0) AS min_logical_io_reads_mb
		, ROUND(rs.max_logical_io_reads * 8 / 1024, 0) AS max_logical_io_reads_mb
		, ROUND(rs.stdev_logical_io_reads * 8 / 1024, 0) AS stdev_logical_io_reads_mb
		, rs.max_rowcount
		, ROUND(rs.avg_rowcount, 0) AS avg_rowcount
		, rs.min_rowcount
		, CONVERT(NVARCHAR(30), rsi.start_time, 120) AS rsi_start_time
		, CONVERT(NVARCHAR(30), rsi.end_time, 120) AS rsi_endtime
		, rs.last_execution_time
	FROM ' + QUOTENAME(@db_name) + N'.sys.query_store_runtime_stats AS rs
	INNER JOIN ' + QUOTENAME(@db_name) + N'.sys.query_store_runtime_stats_interval AS rsi
		ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
	INNER JOIN ' + QUOTENAME(@db_name) + N'.sys.query_store_plan AS p
		ON rs.plan_id = p.plan_id
	INNER JOIN ' + QUOTENAME(@db_name) + N'.sys.query_store_query AS q
		ON p.query_id = q.query_id
	INNER JOIN ' + QUOTENAME(@db_name) + N'.sys.query_store_query_text AS qt
		ON q.query_text_id = qt.query_text_id
	INNER JOIN ' + QUOTENAME(@db_name) + N'.sys.query_store_wait_stats AS ws
		ON rs.plan_id = ws.plan_id
	   AND rsi.runtime_stats_interval_id = ws.runtime_stats_interval_id
	   AND p.plan_id = ws.plan_id
	WHERE rs.execution_type = 0
	  AND rsi.start_time >= @start_time_utc
	  AND rsi.end_time <= @end_time_utc
	  AND rs.count_executions <> 1;
	';

	BEGIN TRY
		EXEC sys.sp_executesql
			  @sql
			, N'@start_time_utc DATETIMEOFFSET, @end_time_utc DATETIMEOFFSET, @db_id INT, @db_name SYSNAME'
			, @start_time_utc = @start_time_utc
			, @end_time_utc = @end_time_utc
			, @db_id = @db_id
			, @db_name = @db_name;
	END TRY
	BEGIN CATCH
		PRINT 'Skipping database ' + QUOTENAME(@db_name) + ': ' + ERROR_MESSAGE();
	END CATCH;

	FETCH NEXT FROM db_cursor INTO @db_name, @db_id;
END;

CLOSE db_cursor;
DEALLOCATE db_cursor;

SELECT
	  database_id
	, database_name
	, runtime_stats_id
	, plan_id
	, query_id
	, query_text_id
	, query_sql_text
	, count_executions
	, max_duration_in_ms
	, avg_duration_in_ms
	, min_duration_in_ms
	, stdev_duration_in_ms
	, wait_category
	, wait_category_desc
	, total_query_wait_time_ms
	, avg_query_wait_time_ms
	, min_query_wait_time_ms
	, max_query_wait_time_ms
	, stdev_query_wait_time_ms
	, avg_logical_io_reads_mb
	, last_logical_io_reads_mb
	, min_logical_io_reads_mb
	, max_logical_io_reads_mb
	, stdev_logical_io_reads_mb
	, max_rowcount
	, avg_rowcount
	, min_rowcount
	, rsi_start_time
	, rsi_endtime
	, last_execution_time
FROM #query_store_waits
ORDER BY
	  --max_duration_in_ms DESC
	  avg_logical_io_reads_mb DESC
	, database_name ASC;
```

## No waits

```sql
/*
 * Use this query to:
 *   - Find queries with>
 *		- long execution times
 *      - high logical reads
 *     across all online user databases with Query Store enabled.
 *
 * Name: QSNOWAITS-MULTIDB
 */

DECLARE @start_time_local DATETIME2 = '2026-06-04 00:00:00';
DECLARE @end_time_local   DATETIME2 = '2026-06-04 04:00:00';

DECLARE @start_time_utc DATETIMEOFFSET;
DECLARE @end_time_utc   DATETIMEOFFSET;

-- First: interpret local wall-clock time as Central Europe (handles CET/CEST automatically)
-- Second: convert that moment to UTC
SELECT
	@start_time_utc = (@start_time_local AT TIME ZONE 'Central European Standard Time') AT TIME ZONE 'UTC',
	@end_time_utc   = (@end_time_local   AT TIME ZONE 'Central European Standard Time') AT TIME ZONE 'UTC';

IF OBJECT_ID('tempdb..#query_store_nowaits') IS NOT NULL
	DROP TABLE #query_store_nowaits;

CREATE TABLE #query_store_nowaits
(
	  database_id                INT
	, database_name              SYSNAME
	, runtime_stats_id           BIGINT
	, plan_id                    BIGINT
	, query_id                   BIGINT
	, query_text_id              BIGINT
	, query_sql_text             NVARCHAR(MAX)
	, count_executions           BIGINT
	, max_duration_in_ms         DECIMAL(19, 0)
	, avg_duration_in_ms         DECIMAL(19, 0)
	, min_duration_in_ms         DECIMAL(19, 0)
	, stdev_duration_in_ms       DECIMAL(19, 0)
	, avg_logical_io_reads_mb	 BIGINT
	, last_logical_io_reads_mb	 BIGINT
	, min_logical_io_reads_mb    BIGINT
	, max_logical_io_reads_mb    BIGINT
	, stdev_logical_io_reads_mb  BIGINT
	, max_rowcount               BIGINT
	, avg_rowcount               DECIMAL(19, 0)
	, min_rowcount               BIGINT
	, rsi_start_time             NVARCHAR(30)
	, rsi_endtime                NVARCHAR(30)
	, last_execution_time        DATETIMEOFFSET(7)
);

DECLARE @db_name SYSNAME;
DECLARE @db_id INT;
DECLARE @sql NVARCHAR(MAX);

DECLARE db_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT
	  d.name
	, d.database_id
FROM sys.databases AS d
WHERE d.state_desc = 'ONLINE'
  AND d.name NOT IN ('master', 'tempdb', 'model', 'msdb')
  AND d.is_query_store_on = 1
ORDER BY d.name;

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @db_name, @db_id;

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @sql = N'
	INSERT INTO #query_store_nowaits
	(
		  database_id
		, database_name
		, runtime_stats_id
		, plan_id
		, query_id
		, query_text_id
		, query_sql_text
		, count_executions
		, max_duration_in_ms
		, avg_duration_in_ms
		, min_duration_in_ms
		, stdev_duration_in_ms
		, avg_logical_io_reads_mb
		, last_logical_io_reads_mb
		, min_logical_io_reads_mb
		, max_logical_io_reads_mb
		, stdev_logical_io_reads_mb
		, max_rowcount
		, avg_rowcount
		, min_rowcount
		, rsi_start_time
		, rsi_endtime
		, last_execution_time
	)
	SELECT
		  @db_id
		, @db_name
		, rs.runtime_stats_id
		, p.plan_id
		, q.query_id
		, qt.query_text_id
		, qt.query_sql_text
		, rs.count_executions
		, ROUND(rs.max_duration / 1000.0, 0) AS max_duration_in_ms
		, ROUND(rs.avg_duration / 1000.0, 0) AS avg_duration_in_ms
		, ROUND(rs.min_duration / 1000.0, 0) AS min_duration_in_ms
		, ROUND(rs.stdev_duration / 1000.0, 0) AS stdev_duration_in_ms
		, ROUND(rs.avg_logical_io_reads * 8 / 1024, 0) AS avg_logical_io_reads_mb
		, ROUND(rs.last_logical_io_reads * 8 / 1024, 0) AS last_logical_io_reads_mb
		, ROUND(rs.min_logical_io_reads * 8 / 1024, 0) AS min_logical_io_reads_mb
		, ROUND(rs.max_logical_io_reads * 8 / 1024, 0) AS max_logical_io_reads_mb
		, ROUND(rs.stdev_logical_io_reads * 8 / 1024, 0) AS stdev_logical_io_reads_mb
		, rs.max_rowcount
		, ROUND(rs.avg_rowcount, 0) AS avg_rowcount
		, rs.min_rowcount
		, CONVERT(NVARCHAR(30), rsi.start_time, 120) AS rsi_start_time
		, CONVERT(NVARCHAR(30), rsi.end_time, 120) AS rsi_endtime
		, rs.last_execution_time
	FROM ' + QUOTENAME(@db_name) + N'.sys.query_store_runtime_stats AS rs
	INNER JOIN ' + QUOTENAME(@db_name) + N'.sys.query_store_runtime_stats_interval AS rsi
		ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
	INNER JOIN ' + QUOTENAME(@db_name) + N'.sys.query_store_plan AS p
		ON rs.plan_id = p.plan_id
	INNER JOIN ' + QUOTENAME(@db_name) + N'.sys.query_store_query AS q
		ON p.query_id = q.query_id
	INNER JOIN ' + QUOTENAME(@db_name) + N'.sys.query_store_query_text AS qt
		ON q.query_text_id = qt.query_text_id
	WHERE rs.execution_type = 0
	  AND rsi.start_time >= @start_time_utc
	  AND rsi.end_time <= @end_time_utc
	  AND rs.count_executions <> 1;
	';

	BEGIN TRY
		EXEC sys.sp_executesql
			  @sql
			, N'@start_time_utc DATETIMEOFFSET, @end_time_utc DATETIMEOFFSET, @db_id INT, @db_name SYSNAME'
			, @start_time_utc = @start_time_utc
			, @end_time_utc = @end_time_utc
			, @db_id = @db_id
			, @db_name = @db_name;
	END TRY
	BEGIN CATCH
		PRINT 'Skipping database ' + QUOTENAME(@db_name) + ': ' + ERROR_MESSAGE();
	END CATCH;

	FETCH NEXT FROM db_cursor INTO @db_name, @db_id;
END;

CLOSE db_cursor;
DEALLOCATE db_cursor;

SELECT
	  database_id
	, database_name
	, runtime_stats_id
	, plan_id
	, query_id
	, query_text_id
	, query_sql_text
	, count_executions
	, max_duration_in_ms
	, avg_duration_in_ms
	, min_duration_in_ms
	, stdev_duration_in_ms
	, avg_logical_io_reads_mb
	, last_logical_io_reads_mb
	, min_logical_io_reads_mb
	, max_logical_io_reads_mb
	, stdev_logical_io_reads_mb
	, max_rowcount
	, avg_rowcount
	, min_rowcount
	, rsi_start_time
	, rsi_endtime
	, last_execution_time
FROM #query_store_nowaits
ORDER BY
	  --max_duration_in_ms DESC
	  avg_logical_io_reads_mb DESC
	, database_name ASC;
```