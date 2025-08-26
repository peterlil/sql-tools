$stream = $null
$stream = new-object Microsoft.SqlServer.XEvent.Linq.QueryableXEventData`
	("Data Source = redsql1101.red.local; Initial Catalog = master; `
	Integrated Security = SSPI", "Continious events", `
	[Microsoft.SqlServer.XEvent.Linq.EventStreamSourceOptions]::EventStream, `
	[Microsoft.SqlServer.XEvent.Linq.EventStreamCacheOptions]::DoNotCache);

foreach ($event in $stream)
{
	Write-Host $event.Name

	foreach ($field in $event.Fields)
	{
		Write-Host([System.String]::Format("`tField: {0} = {1}", $field.Name, $field.Value));
	}

	foreach ($action in $event.Actions)
	{
		Write-Host([System.String]::Format("`tAction: {0} = {1}", $action.Name, $action.Value));
	} 
	
	if($event.Name -eq "errorlog_written")
	{
		switch -wildcard ($event.Fields("message")
	}
}

# Data disk offline

# Error: 823, Severity: 24, State: 2.
# The operating system returned error 21(The device is not ready)

# Error: 9001, Severity: 21, State: 5
# The log for database 'X' is not availbable


# Tlog disk offline
Error: 17053, Severity: 16, State: 1
SQLServerLogMgr::LogWriter: Operating system error 21(The device is not ready.)

Error: 9001, Severity: 21, State: 4.
The log for database 'DbOnMounts' is not available.
Database DbOnMounts was shutdown due to error 9001 in routine 'XdesRMFull::CommitInternal'.
Error: 17053, Severity: 16, State: 1.
fcb::close-flush: Operating system error (null) encountered.

#Recovery Pending
3	RECOVERY_PENDING
ALTER DATABASE DbOnMounts SET OFFLINE WITH ROLLBACK IMMEDIATE
ALTER DATABASE DbOnMounts SET ONLINE WITH ROLLBACK IMMEDIATE