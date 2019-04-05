SELECT a.database_id, sysdbs.name, 'Warning: Transaction log file might reside on the same drive as database data file(s). Check volume mount points', [path]
	FROM
	(
		SELECT 
			sysmsf.database_id, 
			[type],
			[path] = LEFT(sysmsf.physical_name, 2),
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