SET NOCOUNT ON;
GO
DBCC TRACEON (3604); 
GO

DECLARE curs CURSOR LOCAL
	FORWARD_ONLY READ_ONLY STATIC
	FOR
		SELECT name FROM sys.databases ORDER BY name;
		
DECLARE @dbname sysname;
DECLARE @tmp1 TABLE (
	name sysname,
	dbcc_last_known_good datetime,
	comment nvarchar(255)
);
DECLARE @tmp2 TABLE (
	ParentObject nvarchar(255),
	Object nvarchar(255),
	Field nvarchar(255),
	VALUE nvarchar(255)
);

DECLARE @buf varchar(max);
DECLARE @last_known_good DATETIME;

OPEN curs;
FETCH NEXT FROM curs INTO @dbname;
WHILE (@@FETCH_STATUS = 0)
BEGIN
	
	INSERT INTO @tmp2
		EXECUTE('DBCC PAGE (''' + @dbname + ''', 1, 9, 3) WITH TABLERESULTS;');	
	
	SELECT @last_known_good = CAST(VALUE AS DATETIME)
		FROM @tmp2 
		WHERE Field = N'dbi_dbccLastKnownGood';

	INSERT INTO @tmp1 
		VALUES 
		(
			@dbname, 
			@last_known_good,
			CASE
				WHEN @last_known_good <= DATEADD(DAY, -7, GETDATE()) THEN
					'Warning: DBCC CHECKDB is not executing frequently enough or has not been successful for a week.'
				ELSE
					'Information: DBCC CHECKDB ok.'
			END
		);
	
	DELETE FROM @tmp2;
		
	FETCH NEXT FROM curs INTO @dbname;
END

CLOSE curs;
DEALLOCATE curs;

DBCC TRACEOFF(3604);

SELECT * FROM @tmp1;