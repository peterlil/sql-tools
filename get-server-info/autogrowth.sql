SELECT 
	CASE 
		WHEN is_percent_growth = 1 THEN 
			'Warning: Growth is configured as a percentage.'
		ELSE
			CASE
				WHEN sysmsf.type = 0 THEN
					CASE 
						WHEN ((growth * 100) / size) < 10 THEN
							'Warning: Data file growth can be too small. (1/8 of file)'
						ELSE
							'Information: Growth seems ok.'
					END
				ELSE
					CASE
						WHEN ((growth * 8) / 1024) < 100 THEN
							'Warning: Log file growth can be too small.'
					END
			END
	END AS Comment,
	dbname = sysdbs.name, 
	filename = sysmsf.name, 
	[Size (MB)] = size * 8 / 1024, 
	[Max size(MB)] = CAST(max_size AS BIGINT) * 8 / 1024, 
	[growth (MB or %)] = 
		CASE 
			WHEN is_percent_growth = 1 THEN growth
			ELSE growth * 8 / 1024
		END,
	is_percent_growth
	FROM sys.master_files sysmsf
	INNER JOIN sys.databases sysdbs ON sysmsf.database_id = sysdbs.database_id
	WHERE sysdbs.name NOT IN ('master', 'tempdb', 'model', 'msdb')

