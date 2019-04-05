
DECLARE @ErrorLogs TABLE
(
	[Archive #] int NOT NULL,
	[Date] datetime NOT NULL,
	[Log File Size (Byte)] bigint
);

DECLARE @SqlLogEntries TABLE
(
	LogDate datetime NOT NULL,
	ProcessInfo nvarchar(256),
	[Text] nvarchar(1024)
);

DECLARE @archiveNo int;

INSERT INTO @ErrorLogs
EXEC master..xp_enumerrorlogs;

--SELECT * FROM @ErrorLogs;

DECLARE logcurs CURSOR FOR 
	SELECT [Archive #] FROM @ErrorLogs;

OPEN logcurs;

FETCH NEXT FROM logcurs INTO @archiveNo;
WHILE @@FETCH_STATUS = 0
BEGIN
	
	INSERT INTO @SqlLogEntries
	EXEC master..xp_readerrorlog @archiveNo;

	FETCH NEXT FROM logcurs INTO @archiveNo;	
END;

CLOSE logcurs;
DEALLOCATE logcurs;

SELECT * FROM @SqlLogEntries;

