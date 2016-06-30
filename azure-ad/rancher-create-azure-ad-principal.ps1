# Original code from ; http://docs.octopusdeploy.com/display/OD/Creating+an+Azure+Service+Principal+Account

Param( 
    [parameter(mandatory=$False,HelpMessage='Subscription ID')] 
    $subscriptionId,
    [parameter(mandatory=$False,HelpMessage='Tenant ID')] 
    $tenantId,
    [parameter(mandatory=$False,HelpMessage='Password for Service Principal')] 
    $password

)


# Generate a random password, quick & dirty ;  http://blog.oddbit.com/2012/11/04/powershell-random-passwords/
Function random-password ($length = 15)
{
    $punc = 46..46
    $digits = 48..57
    $letters = 65..90 + 97..122

    # Thanks to
    # https://blogs.technet.com/b/heyscriptingguy/archive/2012/01/07/use-pow
    $password = get-random -count $length `
        -input ($punc + $digits + $letters) |
            % -begin { $aa = $null } `
            -process {$aa += [char]$_} `
            -end {$aa}

    return $password
}

if(!$password) {
    $password = random-password 32
}
 
# Login to your Azure Subscription
Login-AzureRMAccount

# If the Subscription ID is not set, prompt user for it
if(!$subscriptionId) {
    $subscription = Get-AzureRmSubscription | Out-GridView -Title "Select the Subscription" -PassThru
    $subscriptionId = $subscription.SubscriptionId
}

# If the Tentant ID is not set, prompt user for it
if(!$tenantId) {
    $tenant = Get-AzureRmTenant | Out-GridView -Title "Select the Tenant" -PassThru
    $tenantId = $tenant.TenantId
}

# Select Subscription 
Set-AzureRMContext -SubscriptionId $subscriptionId -TenantId $tenantId

# Create an Rancher application in Active Directory
Write-Output "Creating AAD application..."
$azureAdApplication = New-AzureRmADApplication -DisplayName "Rancher UI" -HomePage "http://rancher.com" -IdentifierUris "http://rancher.com" -Password $password
$azureAdApplication | Format-Table
 
# Create the Service Principal
Write-Output "Creating AAD service principal..."
$servicePrincipal = New-AzureRmADServicePrincipal -ApplicationId $azureAdApplication.ApplicationId
$servicePrincipal | Format-Table
 
# Sleep, to ensure the Service Principal is actually created
Write-Output "Sleeping for 30s to give the service principal a chance to finish creating..."
Start-Sleep -s 30
  
# Assign the Service Principal the Contributor role to the subscription.
# Roles can be granted at the Resource Group level if desired.
Write-Output "Assigning the Contributor role to the service principal..."
New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $azureAdApplication.ApplicationId
 
# The Application ID (aka Client ID) will be required when creating the Account in Octopus Deploy
Write-Output "Tenant ID: $($tenant.TenantId)"
Write-Output "Client ID: $($azureAdApplication.ApplicationId)"
Write-Output "Domain: $($tenant.Domain)"
Write-Output "Password: $password"
