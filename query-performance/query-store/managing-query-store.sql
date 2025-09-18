-- Check if Query Store is enabled for a specific database
-- Run the query in the context of the database you want to check
SELECT actual_state_desc, desired_state_desc
FROM sys.database_query_store_options
GO

-- Enable Query Store for a specific database
-- Run the query in the context of the database you want to check
ALTER DATABASE [YourDbName] -- Change to your database name
SET QUERY_STORE = ON
(
    OPERATION_MODE = READ_WRITE,
    CLEANUP_POLICY = ( STALE_QUERY_THRESHOLD_DAYS = 30 ),
    DATA_FLUSH_INTERVAL_SECONDS = 900,
    MAX_STORAGE_SIZE_MB = 2000,
    INTERVAL_LENGTH_MINUTES = 30,
    SIZE_BASED_CLEANUP_MODE = AUTO,
    QUERY_CAPTURE_MODE = AUTO,
    MAX_PLANS_PER_QUERY = 200,
    WAIT_STATS_CAPTURE_MODE = ON
);
GO

DECLARE @dbs TABLE
(
    [name] sysname,
    [id] int
);

/* !Add all of the databases you want to enable query store on here! */
INSERT INTO @dbs ([name]) 
VALUES
    (N'cLASession'); -- Syntaz for more dbs: (N'<name of db1>'), (N'<name of db2>'), (N'<name of dbn>');


UPDATE @dbs
SET 
    [id] = sysdbs.[database_id]
FROM 
    @dbs dbs
JOIN sys.databases sysdbs ON dbs.name COLLATE SQL_Latin1_General_CP1_CI_AS = sysdbs.name

-- Cursor to loop through each database
DECLARE db_cursor CURSOR FOR
SELECT [name] FROM @dbs;

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @dbName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'
    ALTER DATABASE [' + QUOTENAME(@dbName) + N']
    SET QUERY_STORE = ON
    (
        OPERATION_MODE = READ_WRITE,
        QUERY_CAPTURE_MODE = ALL,
        MAX_STORAGE_SIZE_MB = 1000,
        INTERVAL_LENGTH_MINUTES = 30
    );';

    EXEC sp_executesql @sql;

    FETCH NEXT FROM db_cursor INTO @dbName;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;
GO


