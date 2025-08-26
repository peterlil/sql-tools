
/* ==========================================================

	DBCC LogInfo requires membership in the sysadmin server
	role.

   ========================================================== */
DECLARE @product_version nvarchar(128);
SET NOCOUNT ON;
SELECT @product_version = CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(128));

CREATE TABLE #stage2012(
	RecoveryUnitId  INT
	, FileID			INT
	, FileSize		BIGINT
	, StartOffset		BIGINT
	, FSeqNo			BIGINT
	, [Status]		BIGINT
	, Parity			BIGINT
	, CreateLSN		NUMERIC(38)
);

CREATE TABLE #stage2008(
	FileID      INT
	, FileSize    BIGINT
	, StartOffset BIGINT
	, FSeqNo      BIGINT
	, [Status]    BIGINT
	, Parity      BIGINT
	, CreateLSN   NUMERIC(38)
);

CREATE TABLE #result(
    Database_Name   sysname
  , VLF_count       INT 
);

IF(@product_version>=N'11.0.2100.60')
BEGIN
	EXEC sp_msforeachdb N'Use [?]; 
		Insert Into #stage2012 
		Exec sp_executeSQL N''DBCC LogInfo([?])''; 
 
		Insert Into #result 
		Select DB_Name(), Count(*) 
		From #stage2012; 
 
		Truncate Table #stage2012;'
END
ELSE
BEGIN 
	EXEC sp_msforeachdb N'Use [?]; 
		Insert Into #stage2008 
		Exec sp_executeSQL N''DBCC LogInfo([?])''; 
 
		Insert Into #result 
		Select DB_Name(), Count(*) 
		From #stage2008; 
 
		Truncate Table #stage2008;'
END;

 
SELECT * 
FROM #result
ORDER BY VLF_count DESC;
 
DROP TABLE #stage2008;
DROP TABLE #stage2012;
DROP TABLE #result;

