using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}

$body = "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response."

if ($name) {
    $body = "Hello, $name. This HTTP triggered function executed successfully."
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
#Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
#    StatusCode = [HttpStatusCode]::OK
#    Body       = $body
#})

# Input bindings are passed in via param block.
#param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
#if ($Timer.IsPastDue) {
#    Write-Host "PowerShell timer is running late!"
#}
function Get-AzureActivityLogs {
    <#
    .Description
    Retrieves Azure Activity Logs using the Azure PowerShell module with Managed Identity
    .Functionality
    Internal
    #>
    try {
        # Connect using Managed Identity
        Connect-AzAccount -Identity

        # Define the time range for the activity logs
        $StartTime = (Get-Date).AddDays(-30) # For example, last 30 days
        $EndTime = Get-Date

        # Retrieve the activity logs
        $ActivityLogs = Get-AzActivityLog -StartTime $StartTime -EndTime $EndTime

        # Construct the output object
        $AzureActivityLogInfo = @{
            "LogCount" = $ActivityLogs.Count
            "Logs" = $ActivityLogs
        }

        # Convert to JSON format
        $AzureActivityLogInfo = ConvertTo-Json @($AzureActivityLogInfo) -Depth 4
        return $AzureActivityLogInfo
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

$envTenantId = $env:TenantId
Write-Output "TenantId: $envTenantId"
Write-Host "Connect AzAccount! TIME: $currentUTCtime"
Connect-AzAccount -Identity -TenantId $envTenantId -Environment AzureUSGovernment
Write-Host "Connect MgGraph TIME: $currentUTCtime"
Connect-MgGraph -Identity -Environment USGov
Write-Host "Get-AzureActivityLogs! TIME: $currentUTCtime"
$activity = Get-AzureActivityLogs
Write-Host "Disonnect-AzAccount! TIME: $currentUTCtime"
Disconnect-AzAccount

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body       = $activity
})