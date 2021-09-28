SELECT TOP 10 
	qs.execution_count, 
	AvgPhysicalReads = isnull( qs.total_physical_reads/ qs.execution_count, 0 ), 
	MinPhysicalReads = qs.min_physical_reads, 
	MaxPhysicalReads = qs.max_physical_reads, 
	AvgPhysicalReads_kbsize = isnull( qs.total_physical_reads/ qs.execution_count, 0 ) *8, 
	MinPhysicalReads_kbsize = qs.min_physical_reads*8, 
	MaxPhysicalReads_kbsize = qs.max_physical_reads*8, 
	CreationDateTime = qs.creation_time, 
	SUBSTRING
	(
		qt.[text], qs.statement_start_offset/2, 
		( 
			CASE 
				WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.[text])) * 2 
				ELSE qs.statement_end_offset 
			END - qs.statement_start_offset)/2 
		) AS query_text, 
		qt.[dbid], 
		qt.objectid, 
		tp.query_plan, 
		tp.query_plan.exist
		(
			'declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan"; /ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes'
		) missing_index_info 
FROM 
	sys.dm_exec_query_stats qs 
	CROSS APPLY sys.dm_exec_sql_text (qs.[sql_handle]) AS qt 
	OUTER APPLY sys.dm_exec_query_plan(qs.plan_handle) tp 
ORDER BY AvgPhysicalReads DESC 
