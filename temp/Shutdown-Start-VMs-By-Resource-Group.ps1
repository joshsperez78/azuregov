workflow Shutdown-Start-VMs-By-Resource-Group
{
	Param
    (   
        [Parameter(Mandatory=$true)]
        [String]
        $AzureResourceGroup,
		[Parameter(Mandatory=$true)]
        [Boolean]
		$Shutdown
    )
	
	#The name of the Automation Credential Asset this runbook will use to authenticate to Azure.
    $CredentialAssetName = "DefaultAzureCredential";
	
	#Get the credential with the above name from the Automation Asset store
    $Cred = Get-AutomationPSCredential -Name $CredentialAssetName
    if(!$Cred) {
        Throw "Could not find an Automation Credential Asset named '${CredentialAssetName}'. Make sure you have created one in this Automation Account."
    }

    #Connect to your Azure Account   	
	Add-AzureRmAccount -Credential $Cred
	Add-AzureAccount -Credential $Cred
	
	if($Shutdown -eq $true){
		Write-Output "Stopping VMs in '$($AzureResourceGroup)' resource group";
	}
	else{
		Write-Output "Starting VMs in '$($AzureResourceGroup)' resource group";
	}
	
	#ARM VMs
	Write-Output "ARM VMs:";
	  
	Get-AzureRmVM -ResourceGroupName $AzureResourceGroup | ForEach-Object {
	
		if($Shutdown -eq $true){
			
				Write-Output "Stopping '$($_.Name)' ...";
				Stop-AzureRmVM -ResourceGroupName $AzureResourceGroup -Name $_.Name -Force;
		}
		else{
			Write-Output "Starting '$($_.Name)' ...";			
			Start-AzureRmVM -ResourceGroupName $AzureResourceGroup -Name $_.Name;			
		}			
	};
	
	
	
	#ASM VMs
	Write-Output "ASM VMs:";
	
	Get-AzureRmResource | where { $_.ResourceGroupName -match $AzureResourceGroup -and $_.ResourceType -eq "Microsoft.ClassicCompute/VirtualMachines"} | ForEach-Object {
		
		$vmName = $_.Name;
		if($Shutdown -eq $true){
			
			Get-AzureVM | where {$_.Name -eq $vmName} | ForEach-Object {
				Write-Output "The machine '$($_.Name)' is $($_.PowerState)";
				
				if($_.PowerState -eq "Started"){
					Write-Output "Stopping '$($_.Name)' ...";		
					Stop-AzureVM -ServiceName $_.ServiceName -Name $_.Name -Force;
				}
			}
		}
		else{
			
			Get-AzureVM | where {$_.Name -eq $vmName} | ForEach-Object {
				Write-Output "The machine '$($_.Name)' is $($_.PowerState)";
								
				if($_.PowerState -eq "Stopped"){
					Write-Output "Starting '$($_.Name)' ...";		
					Start-AzureVM -ServiceName $_.ServiceName -Name $_.Name;
				}
			}
		}		
	};
}

