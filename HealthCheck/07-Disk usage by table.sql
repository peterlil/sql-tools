SELECT 
	p.[Table Name],
	SUM (
		CASE
			WHEN (p.index_id < 2) THEN p.row_count
			ELSE 0
		END
		) AS [# Records],
	SUM (p.reserved_page_count) * 8192 / 1024 AS [Reserved (kB)],
	SUM (p.data_pages) * 8192 / 1024 AS [Data (kB)],
	(
		CASE 
			WHEN SUM (p.used_page_count) > SUM (p.data_pages) THEN (SUM (p.used_page_count) - SUM (p.data_pages)) 
			ELSE 0 
		END
	) * 8192 / 1024 AS [Indexes (kB)] ,
	(
		CASE 
			WHEN SUM (p.reserved_page_count) > SUM (p.used_page_count) THEN (SUM(p.reserved_page_count) - SUM (p.used_page_count)) 
			ELSE 0 
		END
	) * 8192 / 1024 AS [Unused (kB)]
FROM
(	
	SELECT
		sch.[name] + N'.' + t.[name] AS [Table Name],
		ps.object_id,
		ps.index_id,
		ps.reserved_page_count,
		sub_ps.data_pages,
		ps.used_page_count,
		ps.row_count
	FROM sys.dm_db_partition_stats ps
		INNER JOIN sys.tables t ON ps.object_id = t.object_id
		INNER JOIN sys.schemas sch ON t.schema_id = sch.schema_id
		INNER JOIN 
		(
			SELECT partition_id, 
				CASE
					WHEN (ps.index_id < 2) THEN (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count)
					ELSE ps.lob_used_page_count + ps.row_overflow_used_page_count
				END	AS data_pages
				FROM sys.dm_db_partition_stats ps
		) sub_ps ON ps.partition_id = sub_ps.partition_id
UNION
	SELECT
		sch.[name] + N'.' + t.[name] AS [Table Name], 
		it.parent_id AS object_id,
		0 AS index_id,
		sum(reserved_page_count) AS reserved_page_count,
		0 AS data_pages,
		sum(used_page_count) AS used_page_count,
		0 AS row_count
	FROM sys.dm_db_partition_stats ps
	INNER JOIN sys.internal_tables it ON ps.object_id = it.object_id AND it.internal_type IN (202,204,211,212,213,214,215,216)
	INNER JOIN sys.tables t on it.parent_id = t.object_id
	INNER JOIN sys.schemas sch on t.schema_id = sch.schema_id
	GROUP BY sch.name, t.name, it.parent_id
) P
GROUP BY [Table Name]
ORDER BY[Table Name];
