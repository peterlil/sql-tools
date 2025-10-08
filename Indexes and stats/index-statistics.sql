--=========================================
-- Find the top 10 hottest tables
--=========================================
SELECT TOP 10
    OBJECT_NAME(s.object_id) AS TableName,
    SUM(user_seeks + user_scans + user_lookups) AS TotalReads,
    SUM(user_updates) AS TotalWrites
FROM sys.dm_db_index_usage_stats AS s
JOIN sys.indexes AS i
    ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE s.database_id = DB_ID()
GROUP BY s.object_id
ORDER BY TotalReads DESC;
