SELECT a.database_id, sysdbs.name, 'Warning: Transaction log file resides on the same drive as database data file(s).', [path]
	FROM
	(
		SELECT 
			sysmsf.database_id, 
			[type],
			[path] = LEFT(sysmsf.physical_name, LEN(sysmsf.physical_name) - CHARINDEX(N'\', REVERSE(sysmsf.physical_name))),
			[bin_type] = CASE [type]
				WHEN 0 THEN 1
				WHEN 1 THEN 2
				ELSE 4
			END
			FROM sys.master_files sysmsf
			WHERE [type] in (0,1) 
	) a
	INNER JOIN sys.databases sysdbs ON a.database_id = sysdbs.database_id
	GROUP BY a.database_id, sysdbs.name, [path]
	HAVING 
		MAX([type]) = 1
	AND	COUNT(*) > 1;
