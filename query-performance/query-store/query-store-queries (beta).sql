
-- Top 25 regressed queries using Stockholm local time
WITH QueryStats AS (
    SELECT 
        q.query_id,
        qt.query_sql_text,
        p.plan_id,
        rs.execution_type_desc,
        rs.count_executions,
        rs.avg_duration,
        rs.runtime_stats_interval_id,
        i.start_time AT TIME ZONE 'UTC' AT TIME ZONE 'Central European Standard Time' AS local_start_time,
        i.end_time AT TIME ZONE 'UTC' AT TIME ZONE 'Central European Standard Time' AS local_end_time
    FROM 
        sys.query_store_query q
        JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
        JOIN sys.query_store_plan p ON q.query_id = p.query_id
        JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
        JOIN sys.query_store_runtime_stats_interval i ON rs.runtime_stats_interval_id = i.runtime_stats_interval_id
    WHERE 
        i.start_time >= DATEADD(DAY, -7, SYSUTCDATETIME())
)
, Aggregated AS (
    SELECT 
        query_id,
        query_sql_text,
        AVG(CASE WHEN local_start_time < DATEADD(day, -1, SYSDATETIMEOFFSET()) THEN avg_duration END) AS prev_avg_duration,
        AVG(CASE WHEN local_start_time >= DATEADD(day, -1, SYSDATETIMEOFFSET()) THEN avg_duration END) AS recent_avg_duration
    FROM QueryStats
    GROUP BY query_id, query_sql_text
)
SELECT TOP 25 
    query_id,
    query_sql_text,
    prev_avg_duration,
    recent_avg_duration,
    recent_avg_duration - prev_avg_duration AS duration_delta
FROM Aggregated
WHERE 
    prev_avg_duration IS NOT NULL AND
    recent_avg_duration IS NOT NULL AND
    recent_avg_duration > prev_avg_duration
ORDER BY duration_delta DESC;
GO





WITH ExecutionStats AS (
    SELECT 
        q.query_id,
        qt.query_sql_text,
        rs.avg_duration,
        rs.count_executions,
        rs.runtime_stats_interval_id,
        i.start_time AT TIME ZONE 'UTC' AT TIME ZONE 'Central European Standard Time' AS local_start_time
    FROM 
        sys.query_store_query q
        JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
        JOIN sys.query_store_plan p ON q.query_id = p.query_id
        JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
        JOIN sys.query_store_runtime_stats_interval i ON rs.runtime_stats_interval_id = i.runtime_stats_interval_id
    WHERE 
        i.start_time >= DATEADD(DAY, -1, SYSUTCDATETIME())
        --AND q.query_id = 7520
)
, RankedStats AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY query_id ORDER BY local_start_time DESC) AS rn_recent,
        ROW_NUMBER() OVER (PARTITION BY query_id ORDER BY avg_duration DESC) AS rn_longest
    FROM ExecutionStats
)
, MostRecent AS (
    SELECT query_id, query_sql_text, avg_duration AS recent_duration
    FROM RankedStats
    WHERE rn_recent = 1
)
, LongestExecution AS (
    SELECT query_id, avg_duration AS longest_duration
    FROM RankedStats
    WHERE rn_longest = 1
)
, ExecutionCounts AS (
    SELECT query_id, SUM(count_executions) AS total_executions
    FROM ExecutionStats
    GROUP BY query_id
)
SELECT TOP 25 
    r.query_id,
    r.query_sql_text,
    l.longest_duration,
    r.recent_duration,
    l.longest_duration - r.recent_duration AS duration_delta,
    ec.total_executions
FROM MostRecent r
JOIN LongestExecution l ON r.query_id = l.query_id
JOIN ExecutionCounts ec ON r.query_id = ec.query_id
WHERE r.recent_duration < l.longest_duration
ORDER BY duration_delta DESC;



GO