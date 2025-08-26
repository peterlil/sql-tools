/*
 * Quick way to check how much data is allocated in a db. 
 */

/* Azure SQL DB */
-- Connect to master
-- Database data space used in MB
SELECT TOP 1 storage_in_megabytes AS DatabaseDataSpaceUsedInMB
FROM sys.resource_stats
WHERE database_name = 'aw'
ORDER BY end_time DESC


/* SQL Server */
-- Connect to database
-- Database data space allocated in MB and database data space allocated unused in MB
SELECT
	type_desc AS TypeOfData,
	SUM(size/128.0) AS SpaceAllocatedInMB,
	SUM(size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0) AS SpaceAllocatedUnusedInMB
FROM sys.database_files
GROUP BY type_desc


/* SQL Server */
-- Connect to database
-- Database data max size in bytes
SELECT DATABASEPROPERTYEX('aw', 'MaxSizeInBytes') AS DatabaseDataMaxSizeInBytes,
	CAST(DATABASEPROPERTYEX('aw', 'MaxSizeInBytes') as bigint) / (1024) AS DatabaseDataMaxSizeInkB,
	CAST(DATABASEPROPERTYEX('aw', 'MaxSizeInBytes') as bigint) / (1024*1024) AS DatabaseDataMaxSizeInMB,
	CAST(DATABASEPROPERTYEX('aw', 'MaxSizeInBytes') as bigint) / (1024*1024*1024) AS DatabaseDataMaxSizeInGB
