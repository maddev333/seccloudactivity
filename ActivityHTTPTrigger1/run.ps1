using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."


# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

function Get-AzureActivityLogs {
    <#
    .Description
    Retrieves Azure Activity Logs using the Azure PowerShell module with Managed Identity
    .Functionality
    Internal
    #>
    try {

        # Retrieve the activity logs
        $ActivityLogs = Get-AzActivityLog -MaxRecord 30
        # Construct the output object
        $AzureActivityLogInfo = @{
            "LogCount" = $ActivityLogs.Count
            "Logs" = @()  # Initialize as an empty array
        }

        # Populate the logs while ensuring unique keys
        foreach ($log in $ActivityLogs) {
            # Create a custom object to avoid key conflicts
            $logEntry = [PSCustomObject]@{
                "EventTime"      = $log.EventTime
                "Authorization"  = $log.Authorization  # Ensure this does not conflict
                "Caller"         = $log.Caller
                "ResourceGroup"  = $log.ResourceGroup
                "ResourceId"     = $log.ResourceId
                # Add other relevant properties as needed
            }
            $AzureActivityLogInfo["Logs"] += $logEntry
            Write-Host $logEntry
        }

        # Convert to JSON format with increased depth
        $AzureActivityLogInfoJson = ConvertTo-Json $AzureActivityLogInfo -Depth 10
        return $AzureActivityLogInfoJson
    }
    catch {
        Write-Warning "Error retrieving Azure Activity Logs using Get-AzureActivityLogs: $($_)"
        $AzureActivityLogInfo = @{
            "LogCount" = "Error retrieving log count"
            "Logs" = "Error retrieving logs"
        }

        # Convert to JSON format
        $AzureActivityLogInfo = ConvertTo-Json @($AzureActivityLogInfo) -Depth 4
        return $AzureActivityLogInfo
    }
}
$subscriptionId = $env:SubId
Write-Output "SubId: $subscriptionId"
$envTenantId = $env:TenantId
Write-Output "TenantId: $envTenantId"
Write-Host "Connect AzAccount! TIME: $currentUTCtime"
Connect-AzAccount -Identity -TenantId $envTenantId -Subscription $subscriptionId -Environment AzureUSGovernment

# Log the current context
$currentContext = Get-AzContext
Write-Host "Current Subscription ID: $($currentContext.Subscription.Id)"

# Fetch Azure Activity Logs
Write-Host "Retrieving Azure Activity Logs... TIME: $currentUTCtime"
$activity = Get-AzureActivityLogs

Write-Host "Disonnect-AzAccount! TIME: $currentUTCtime"
Disconnect-AzAccount

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body       = $activity
})