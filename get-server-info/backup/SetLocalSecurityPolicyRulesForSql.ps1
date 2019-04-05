param([string]$sqlServiceAccount)

function Update-SecurityPolicy([string]$DomainAccount) {

	$TemporaryFolderPath = $PWD.Path.ToString()

	# Evaluate whether the ApplyUserRights.inf file exists and if it does delete it
	if(Test-Path $TemporaryFolderPath\ApplyUserRights.inf){           
		Write-Host -ForegroundColor White " - Removing $TemporaryFolderPath`\ApplyUserRights.inf"            
		Remove-Item $TemporaryFolderPath\ApplyUserRights.inf -Force -WhatIf:$false        
	}

	Write-Host -ForegroundColor White " - Exporting current security template to: $TemporaryFolderPath"    
	$SeceditResults = secedit /export /areas USER_RIGHTS /cfg $TemporaryFolderPath\UserRightsAsTheyExist.inf

	# Make sure the export was successful
	# In the log you might get "No mapping between account names and security IDs was done." this is due to built in accounts

	if($SeceditResults[$SeceditResults.Count-2] -eq "The task has completed successfully."){
		Write-Host -ForegroundColor White " - Secedit export was successful, proceeding to re-import"        
		
		#Save out the header of the file to be imported
		Write-Host -ForegroundColor White " - Save out header for $TemporaryFolderPath`\ApplyUserRights.inf"
	
"[Unicode]
Unicode=yes
[Version]
signature=`"`$CHICAGO`$`"
Revision=1
[Privilege Rights]" | Out-File $TemporaryFolderPath\ApplyUserRights.inf -Force -WhatIf:$false

		# Bring the exported config file in as an array        
		Write-Host -ForegroundColor White " - Importing the exported secedit file."        
		$SecurityPolicyExport = Get-Content $TemporaryFolderPath\UserRightsAsTheyExist.inf
		
		# enumerate over each of these files, looking for the Perform Volume Maintenance Tasks privilege        
		[Boolean]$isFound = $false
		
		# This is the priviliges that needs to be updated
		#$Privileges = "SeTcbPrivilege","SeImpersonatePrivilege","SeServiceLogonRight"
		$Privileges = "SeLockMemoryPrivilege","SeManageVolumePrivilege"
		
			# Loop through the priviliges
			foreach($Privilege in $Privileges) {
			
				[Boolean]$isFound = $false
				# Check each line in the exported security template and update the outputfile with the new account.
				foreach($line in $SecurityPolicyExport){
					
					if($line -like "$Privilege`*"){
						Write-Host -ForegroundColor White " - Line with the $Privilege found in export, appending $DomainAccount to it"
						# Add the user account to the list                            
						$line = $line + ",$DomainAccount"                                                 
						$line | Out-File $TemporaryFolderPath\ApplyUserRights.inf -Append -WhatIf:$false                            
						$isFound = $true            
					}
				
				}
				if($isFound -eq $false){
					# If the security privilige does not exists we create it 
					Write-Host -ForegroundColor White " - No line found for $Privilege - Adding new line for $DomainAccount"            
					"$Privilege`=$DomainAccount" | Out-File $TemporaryFolderPath\ApplyUserRights.inf -Append -WhatIf:$false
					
				}
				
			}	
		          
		Write-Host -ForegroundColor White "Importing $TemporaryfolderPath\ApplyUserRighs.inf"            
		$SeceditApplyResults = SECEDIT /configure /db secedit.sdb /cfg $TemporaryFolderPath\ApplyUserRights.inf
	
		# Verify that update was successful
		if($SeceditApplyResults[$SeceditApplyResults.Count-2] -eq "The task has completed successfully."){
			Write-Host -ForegroundColor White "Local Security Policy updated successfully"
		}
		else{
			#Import failed for some reason                
			Write-Host -ForegroundColor White "Import from $TemporaryFolderPath\ApplyUserRights.inf failed."                
			Write-Error -Message "The import from$TemporaryFolderPath\ApplyUserRights using secedit failed. Full Text Below:$SeceditApplyResults)"            
		}
		
	}
	else{
		#Export failed for some reason.        
		Write-Host -ForegroundColor White "Export to $TemporaryFolderPath\UserRightsAsTheyExist.inf failed."        
		Write-Error -Message "The export to $TemporaryFolderPath\UserRightsAsTheyExist.inf from secedit failed. Full Text Below:$SeceditResults)"        
	}

}

Update-SecurityPolicy $sqlServiceAccount