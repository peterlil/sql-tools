--------------------------------------------------------------------------------
-- Get detailed information about indexes for a table or view
--------------------------------------------------------------------------------

DECLARE @object_name sysname;

SET @object_name = N'' -- Name of table or view

SELECT object_name(p.object_id) AS name
	   , i.name AS index_name
       , partition_id
       , p.partition_number AS PartitionNumber
	   , p.data_compression_desc AS DataCompression
	   , p.index_id
       , partition_number AS pnum
       , rows
       , allocation_unit_id AS au_id
       , a.type_desc AS page_type_desc
       , total_pages AS pages
	   , a.total_pages  * 8 AS TotalIndexSizeKB
	   , a.used_pages  * 8 AS UsedIndexSizeKB
	   , a.data_pages  * 8 AS DataIndexSizeKB
FROM sys.partitions p
       INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
	   LEFT OUTER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
WHERE p.object_id=object_id(@object_name)
ORDER BY i.index_id ASC
GO

--------------------------------------------------------------------------------
-- Get the used index size in kB of an index
--------------------------------------------------------------------------------
DECLARE @object_name sysname;

SET @object_name = N'' -- Name of index

SELECT i.[name] AS IndexName
    ,SUM(s.[used_page_count]) * 8 AS UsedIndexSizeKB
FROM sys.dm_db_partition_stats AS s
INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id]
    AND s.[index_id] = i.[index_id]
WHERE i.[name] = @object_name
GROUP BY i.[name]
ORDER BY i.[name]
GO

--------------------------------------------------------------------------------
-- Check compression status of indexes and partitions
--------------------------------------------------------------------------------
SELECT t.[name] AS TableName, 
	i.[name] AS IndexName, 
	p.partition_number AS PartitionNumber,
	p.data_compression_desc AS DataCompression,
	i.*
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id -- Removes indexes for system tables
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
WHERE i.type_desc != 'HEAP'
--	AND i.[name] = ''
ORDER BY t.[name] ASC
GO
