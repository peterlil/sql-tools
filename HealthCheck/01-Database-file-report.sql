/*=============================================================
Needs the following database rights:

USE master;
GO
GRANT VIEW SERVER STATE TO XXX;
GO
GRANT VIEW ANY DEFINITION TO XXX;
GO

Note: The user must also be a member of the public role in 
each database on the server.

Does not work on:
- Azure SQL Database

==============================================================*/


SET NOCOUNT ON;
GO

DECLARE @MsTempFilegroups TABLE (
	database_id int NOT NULL,
	filegroup_name sysname NOT NULL,
	data_space_id int NOT NULL,
	FilegroupType INT NOT NULL
);

DECLARE @dbname sysname;
DECLARE dbcurs CURSOR LOCAL FORWARD_ONLY DYNAMIC READ_ONLY FOR
	SELECT name FROM sys.databases;
	
OPEN dbcurs;

FETCH NEXT FROM dbcurs 
	INTO @dbname;
	
WHILE @@FETCH_STATUS = 0
BEGIN
	INSERT INTO @MsTempFilegroups
	EXECUTE(N'
		SELECT 
			db.database_id, 
			fg.name, 
			fg.data_space_id, 
			case fg.type 
				WHEN ''FG'' THEN 0 WHEN ''FD'' THEN 2 
				WHEN ''FX'' THEN 3 /*Memory optimized tables*/ 
				WHEN ''PS'' THEN 3 /*Partition Scheme*/ 
			END AS FilegroupType 
		FROM master.sys.databases db 
		INNER JOIN [' + @dbname + N'].sys.filegroups fg ON 1 = 1 
		WHERE db.name = ''' + @dbname + N''';');

	FETCH NEXT FROM dbcurs 
		INTO @dbname;	
END;

CLOSE dbcurs;
DEALLOCATE dbcurs;

SELECT 
	db.name AS DatabaseName, 
	fg.filegroup_name,
	mf.name AS LogicalFilename,
	mf.file_id AS FileID,
	mf.physical_name AS PhysicalName,
	CASE mf.type WHEN 1 THEN '<N/A>' ELSE fg.filegroup_name END AS Filegroup,
	mf.size * 8 AS [Size in kB],
	ROUND((CAST((mf.size * 8) AS float) / (CAST((1024*1024) AS float))), 2) AS [Size in GB],
	CASE mf.max_size 
		WHEN 0 THEN CAST(mf.size AS BIGINT) * 8
		WHEN -1 THEN -1 -- Unlimited
		ELSE CAST(mf.max_size AS BIGINT) * 8
	END AS [MaxSize kB)],
	CASE mf.is_percent_growth
		WHEN 0 THEN mf.growth * 8
		WHEN 1 THEN mf.growth
	END AS Growth,
	CASE mf.is_percent_growth
		WHEN 0 THEN 'kB'
		WHEN 1 THEN '%'
	END AS GrowthUnit
--	,db.*, mf.*
FROM sys.databases db
INNER JOIN sys.master_files mf on db.database_id = mf.database_id
LEFT OUTER JOIN @MsTempFilegroups fg ON db.database_id = fg.database_id AND mf.data_space_id = fg.data_space_id
ORDER BY DatabaseName ASC, fg.filegroup_name, mf.type ASC, LogicalFilename ASC;


--select * from sys.master_files
-- select * from sys.data_spaces
-- select * from AdventureWorks2008.sys.filegroups
-- select * from master.sys.databases
-- select * from mstempfilegroups

