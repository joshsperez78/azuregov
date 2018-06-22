<#
This runbook is designed to leverage Azure Automation's Classic Service Principal Account
and pass on Classic VM Names and either start or stop them
Depending on the $Shutdown Parameter passed
#>
   
    param (
        [Parameter(Mandatory=$true)]
        [String] $VMName,
        [Parameter(Mandatory=$false)]
        [Boolean] $Shutdown=$false
    )

    # Returns strings with status messages
    [OutputType([String])]

	# Connect to Azure and select the subscription to work against
    $ConnectionAssetName = "AzureClassicRunAsConnection"

# Get the connection
$connection = Get-AutomationConnection -Name $connectionAssetName        

# Authenticate to Azure with certificate
Write-Verbose "Get connection asset: $ConnectionAssetName" -Verbose
$Conn = Get-AutomationConnection -Name $ConnectionAssetName
if ($Conn -eq $null)
{
    throw "Could not retrieve connection asset: $ConnectionAssetName. Assure that this asset exists in the Automation account."
}

$CertificateAssetName = $Conn.CertificateAssetName
Write-Verbose "Getting the certificate: $CertificateAssetName" -Verbose
$AzureCert = Get-AutomationCertificate -Name $CertificateAssetName
if ($AzureCert -eq $null)
{
    throw "Could not retrieve certificate asset: $CertificateAssetName. Assure that this asset exists in the Automation account."
}

Write-Verbose "Authenticating to Azure with certificate." -Verbose
Set-AzureSubscription -SubscriptionName $Conn.SubscriptionName -SubscriptionId $Conn.SubscriptionID -Certificate $AzureCert -Environment AzureUSGovernment
Select-AzureSubscription -SubscriptionId $Conn.SubscriptionID

    #Get the VM passed from $VName
	$VMs = Get-AzureVM | where-object {$_.Name -eq $VMName}
	
    # Stop each of the started VMs
    foreach ($VM in $VMs)
    {
        if ($Shutdown) {
            write-output ("Stopping VM {0}" -f $VM.Name)
            Stop-AzureVM -Name $VM.Name -ServiceName $VM.ServiceName -Force -ErrorAction Continue
        } else {
            write-output ("Starting VM {0}" -f $VM.Name)
            Start-AzureVM -ServiceName $VM.ServiceName -Name $VM.Name
        }
    }
