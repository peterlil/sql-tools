SET NOCOUNT ON;
GO
USE master;
GO 



/*Create two temp tables, one for current db VLF and one for the total VLFs collected*/
CREATE TABLE #VLF_temp (
	RecoverUnitId bigint,
	FileID varchar(3), 
	FileSize numeric(20,0),
	StartOffset bigint, 
	FSeqNo bigint, 
	[Status] char(1),
	Parity varchar(4), 
	CreateLSN numeric(25,0)
);

CREATE TABLE #VLF_db_total_temp (
	name sysname, 
	vlf_count int
);
 
/*Declare a cursor to loop through all current databases*/
DECLARE db_cursor CURSOR READ_ONLY
	FOR SELECT name FROM master.dbo.sysdatabases;
 
DECLARE @name sysname, @stmt varchar(40);

OPEN db_cursor;
 
FETCH NEXT FROM db_cursor INTO @name
 WHILE (@@fetch_status <> -1)
 BEGIN
	IF (@@fetch_status <> -2)
	BEGIN
		/*insert the results into the first temp table*/ 
		INSERT INTO #VLF_temp
			EXEC ('DBCC LOGINFO ([' + @name + ']) WITH NO_INFOMSGS');
			
		/*insert the db name and count into the second temp table*/
		INSERT INTO #VLF_db_total_temp
			SELECT @name, COUNT(*) FROM #VLF_temp;
			
		/*truncate the first table so we can get the count for the next db*/
		TRUNCATE TABLE #VLF_temp;
	END
	FETCH NEXT FROM db_cursor INTO @name;
 END
 
/*close and deallocate cursor*/
CLOSE db_cursor;
DEALLOCATE db_cursor;

/*we are only interested in the top ten rows because having more could look funky in an Excel graph*/
/*we are currently only interested in db's with more than 50 VLFs*/
SELECT --TOP 10
	@@servername as [ServerName], 
	name as [DBName], 
	vlf_count as [VLFCount]
FROM #VLF_db_total_temp
--WHERE vlf_count > 50
ORDER BY vlf_count DESC;

/*drop the tables*/
DROP TABLE [#VLF_temp];
DROP TABLE [#VLF_db_total_temp];


/*
To see how many VLFs you have solely look at the number of rows returned by DBCC LOGINFO. The number of rows returned equals the number of VLFs your transaction log file has. If you have more than 50, I would recommend fixing it and adjusting your autogrowth so that it doesn't occur as fequently. To get rid of all of the execessive VLFs, follow these easy steps to shrink off the fragmented chunk and add a new, clean chunk to your transaction log: 
1. Wait for an inactive time of day (ideally, it would be best to put the database into single user mode first) and then clear all transaction log activity through a regular transaction log backup. If you're using the simple recovery model then you don't need to do a log backup... Instead, just clear the transaction log by running a checkpoint. 
BACKUP LOG databasename TO devicename 
2. Shrink the log to as small a size as possible (truncateonly) 
DBCC SHRINKFILE(transactionloglogicalfilename, TRUNCATEONLY) 
NOTE: if you don't know the logical filename of your transaction log use sp_helpfile to list all of your database files. 
3. Alter the database to modify the transaction log file to the appropriate size - in one step 
ALTER DATABASE databasename
 MODIFY FILE 
( 
NAME = transactionloglogicalfilename 
, SIZE = newtotalsize
) 
NOTE: Depending on the total size desired, you might want to break this into multiple chunks. Be sure to read this post as well: Transaction Log VLFs too many or too few? after reading this one. Not only can you have too many small VLFs but if incorrectly sized, you can have too few! And... there's a bug referenced/mentioned there. You'll want to read that post as well!


Read more: http://sqlskills.com/blogs/kimberly/post/8-Steps-to-better-Transaction-Log-throughput.aspx#ixzz0zmvBjPWd
*/

/*
DBCC LOGINFO;
DBCC SQLPERF(logspace)
*/
