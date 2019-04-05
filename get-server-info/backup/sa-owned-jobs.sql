SELECT 'Warning: The owner of SQL Agent job [' + sysjobs.[name] + '] is the user SA.' AS 'Checking for jobs owned by SA'
	FROM msdb.dbo.sysjobs
	INNER JOIN sys.server_principals sysspri ON sysjobs.owner_sid = sysspri.sid
	WHERE 
		sysspri.name = N'sa'