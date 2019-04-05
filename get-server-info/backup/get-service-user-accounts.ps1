Get-WmiObject -Namespace root\cimv2 -Class Win32_Service -ComputerName plhpw801 `
	-Filter "Name='MSSQLSERVER' OR Name='SQLSERVERAGENT' OR 
		     Name='MSSQLFDLauncher' OR Name='MSSQLServerOLAPService' OR 
			 Name='SQLBrowser' OR Name='MsDtsServer110' OR 
			 Name='ReportServer' OR Name='SQLWriter'" `
	| Sort-Object Name, StartName, SystemName `
	| ft SystemName, Name, State, StartName;