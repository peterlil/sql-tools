
/* ==========================================================================
   Lists all unused indexes that are not primary keys or unique constraints.
   "Unused" is a little bit misleading, this query shows all indexes that 
   are updated more than they are used in scans, seeks or lookups.
   ========================================================================== */
/*
Create an empty temp table
*/
SELECT 
	DatabaseName = DB_NAME(),
	CAST(sys_schemas.name AS varchar(15)) AS SchemaName, 
	CAST(sys_objects.name AS varchar(40)) AS TableName,
	CAST(i.name AS varchar(50)) AS IndexName, 
	i.index_id,
	reads=sum(user_seeks + user_scans + user_lookups),
	writes = sum(user_updates),
	[rows] = sum(p.rows), 
	sum(partition_stats.used_page_count) * 8 AS IndexSizeKB, 
	CAST(sum(partition_stats.used_page_count) * 8 / 1024.00 AS Decimal(10,3))AS IndexSizeMB, 
	CAST(sum(partition_stats.used_page_count) * 8 / 1048576.00 AS Decimal(10,3)) AS IndexSizeGB
INTO #MsIndexStage
FROM sys.dm_db_index_usage_stats s 
INNER JOIN sys.indexes i ON i.index_id = s.index_id AND s.OBJECT_ID = i.OBJECT_ID   
INNER JOIN sys.partitions p ON p.index_id = s.index_id AND s.OBJECT_ID = p.OBJECT_ID
INNER JOIN sys.dm_db_partition_stats partition_stats 
	ON partition_stats.[object_id] = i.[object_id] 
		AND partition_stats.index_id = i.index_id
		AND i.type_desc = 'nonclustered'
INNER JOIN sys.objects sys_objects
  ON sys_objects.[object_id] = partition_stats.[object_id] 
INNER JOIN sys.schemas sys_schemas  
  ON sys_objects.[schema_id] = sys_schemas.[schema_id] 
  AND sys_schemas.name <> 'SYS'
WHERE 1=0
GROUP BY CAST(sys_schemas.name AS varchar(15))
	, CAST(sys_objects.name AS varchar(40))
	, CAST(i.name AS varchar(50))
	, i.index_id;

exec sp_MSforeachdb 
'INSERT INTO #MsIndexStage
SELECT 
	DatabaseName = ''?'',
	CAST(sys_schemas.name AS varchar(15)) AS SchemaName, 
	CAST(sys_objects.name AS varchar(40)) AS TableName,
	CAST(i.name AS varchar(50)) AS IndexName, 
	i.index_id,
	reads=sum(user_seeks + user_scans + user_lookups),
	writes = sum(user_updates),
	[rows] = sum(p.rows), 
	sum(partition_stats.used_page_count) * 8 AS IndexSizeKB, 
	CAST(sum(partition_stats.used_page_count) * 8 / 1024.00 AS Decimal(10,3))AS IndexSizeMB, 
	CAST(sum(partition_stats.used_page_count) * 8 / 1048576.00 AS Decimal(10,3)) AS IndexSizeGB
FROM sys.dm_db_index_usage_stats s 
INNER JOIN sys.indexes i ON i.index_id = s.index_id AND s.OBJECT_ID = i.OBJECT_ID   
INNER JOIN sys.partitions p ON p.index_id = s.index_id AND s.OBJECT_ID = p.OBJECT_ID
INNER JOIN sys.dm_db_partition_stats partition_stats 
	ON partition_stats.[object_id] = i.[object_id] 
		AND partition_stats.index_id = i.index_id
		AND i.type_desc = ''nonclustered''
INNER JOIN sys.objects sys_objects
  ON sys_objects.[object_id] = partition_stats.[object_id] 
INNER JOIN sys.schemas sys_schemas  
  ON sys_objects.[schema_id] = sys_schemas.[schema_id] 
  AND sys_schemas.name <> ''SYS''
WHERE OBJECTPROPERTY(s.OBJECT_ID,''IsUserTable'') = 1   
	AND s.database_id = DB_ID()   
	AND i.type_desc = ''nonclustered''
GROUP BY CAST(sys_schemas.name AS varchar(15))
	, CAST(sys_objects.name AS varchar(40))
	, CAST(i.name AS varchar(50))
	, i.index_id
ORDER BY reads ASC, writes DESC, rows DESC;';

SELECT * FROM #MsIndexStage;

DROP TABLE #MsIndexStage;


