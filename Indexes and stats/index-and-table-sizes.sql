DECLARE @object_name sysname;
SET @object_name = N'dbo.Staging_Item_VariantStoppedItemInstruction'

SELECT object_name(p.object_id) AS name
	   , i.name AS index_name
       , partition_id
	   , p.index_id
       , partition_number AS pnum
       , rows
       , allocation_unit_id AS au_id
       , a.type_desc AS page_type_desc
       , total_pages AS pages
	   , total_pages  * 8 AS IndexSizeKB
FROM sys.partitions p
       INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
	   LEFT OUTER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
WHERE p.object_id=object_id(@object_name)


SELECT i.[name] AS IndexName
    ,SUM(s.[used_page_count]) * 8 AS IndexSizeKB
FROM sys.dm_db_partition_stats AS s
INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id]
    AND s.[index_id] = i.[index_id]
WHERE i.[name] = 'PK_Staging_Item_VariantStoppedItemInstruction'
	OR i.[name] = 'IX_StagingItemVariantStoppedItemInstruction_1'
GROUP BY i.[name]
ORDER BY i.[name]