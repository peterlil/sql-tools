-- Use to find the query that:
--   - has been executed the most, not in number of invocations, but has been running the longest time (ORDER BY qs.total_elapsed_time DESC)
--   - has had the longest execution time for a single execution (ORDER BY qs.max_elapsed_time DESC)

SELECT [text], qp.[dbid], qs.total_elapsed_time, qs.max_elapsed_time, *
FROM sys.dm_exec_query_stats qs
OUTER APPLY sys.dm_exec_sql_text(sql_handle) st
OUTER APPLY sys.dm_exec_query_plan(plan_handle) qp 
ORDER BY qs.total_elapsed_time DESC
--ORDER BY qs.max_elapsed_time DESC


