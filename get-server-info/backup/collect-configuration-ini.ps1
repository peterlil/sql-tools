# *****************************************************************************
# * Collect the configuration.ini files
# * Look into 'C:\Program Files\Microsoft SQL Server\<version>\Setup Bootstrap\Log'
# * for folders named 00000000_000000.
# *****************************************************************************


	$sqlServerSetupLogPath = "C:\Program Files\Microsoft SQL Server\" + $sqlServerVersion `
		+ "\Setup Bootstrap\Log";
	
	$folderSearchTerm = $sqlServerSetupLogPath + "\????????_??????";
	
	$folderlist = Get-ChildItem $folderSearchTerm
    foreach ($folder in $folderlist) `
	{
        if((Test-Path ($folder.PSPath + '\ConfigurationFile.ini')) -eq $true)
        {
            Write-Host ("Copy: '" + ($folder.PSPath + '\ConfigurationFile.ini') + "' -> '" + ('C:\temp\ConfigurationFile_' + $folder.Name + '.ini') + "'...") -NoNewline -ForegroundColor Green
            Copy-Item ($folder.PSPath + '\ConfigurationFile.ini') ('C:\temp\ConfigurationFile_' + $folder.Name + '.ini')
            Write-Host "OK" -ForegroundColor Green
        }
	}
