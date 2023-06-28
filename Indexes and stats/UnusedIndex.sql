
SELECT objectname=OBJECT_NAME(s.OBJECT_ID) 
    , indexname=i.name
    , i.index_id   
    , reads=user_seeks + user_scans + user_lookups   
    , writes =  user_updates   
    , p.rows
FROM sys.dm_db_index_usage_stats s 
    JOIN sys.indexes i ON i.index_id = s.index_id AND s.OBJECT_ID = i.OBJECT_ID   
    JOIN sys.partitions p ON p.index_id = s.index_id AND s.OBJECT_ID = p.OBJECT_ID
WHERE OBJECTPROPERTY(s.OBJECT_ID,'IsUserTable') = 1   
    AND s.database_id = DB_ID()   
    AND i.type_desc = 'nonclustered'
    AND i.is_primary_key = 0
    AND i.is_unique_constraint = 0
    AND p.rows > 10000
    AND (user_seeks + user_scans + user_lookups) < user_updates
ORDER BY reads, rows DESC




SELECT
    objects.name AS Table_name,
    indexes.name AS Index_name,
    dm_db_index_usage_stats.user_seeks,
    dm_db_index_usage_stats.user_scans,
    dm_db_index_usage_stats.user_updates
FROM
    sys.dm_db_index_usage_stats
    INNER JOIN sys.objects ON dm_db_index_usage_stats.OBJECT_ID = objects.OBJECT_ID
    INNER JOIN sys.indexes ON indexes.index_id = dm_db_index_usage_stats.index_id AND dm_db_index_usage_stats.OBJECT_ID = indexes.OBJECT_ID
WHERE
	objects.name = 'Item'
    AND
    dm_db_index_usage_stats.user_lookups = 0
    AND
    dm_db_index_usage_stats.user_seeks = 0
    AND
    dm_db_index_usage_stats.user_scans = 0
ORDER BY
    dm_db_index_usage_stats.user_updates DESC

