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

        # Retrieve the activity logs
        $ActivityLogs = Get-AzActivityLog -MaxRecord 30

        return $ActivityLogs
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