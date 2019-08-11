<#
Disclaimer: The sample scripts are not supported under any Microsoft standard support program or service. 
The sample scripts are provided AS IS without warranty of any kind. Microsoft further disclaims all implied 
warranties including, without limitation, any implied warranties of merchantability or of fitness for a 
particular purpose. The entire risk arising out of the use or performance of the sample scripts and 
documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the 
creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without 
limitation, damages for loss of business profits, business interruption, loss of business information, or 
other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, 
even if Microsoft has been advised of the possibility of such damages. 


.Contact

Author: Andy Shi
Email: v-anshi@outlook.com

#How to use the script:

1. create a new native app in Azure AD registration.
2. add your account as app owner
3. add graph permission and choose 'Read and write directory data' 
4. modify the value, before running the script:

a. $ClientID as application ID of the new native app
b. $TenantName as your own one
c. $redirectUri  
d. userPrincipalName

5. run this script directly, and you will find the count of all return and csv with all results.

#>


Function Get-AccessToken ($TenantName, $ClientID, $redirectUri, $resourceAppIdURI, $CredPrompt){
    Write-Host "Checking for AzureAD module..."
    if (!$CredPrompt){$CredPrompt = 'Auto'}
    $AadModule = Get-Module -Name "AzureAD" -ListAvailable
    if ($AadModule -eq $null) {$AadModule = Get-Module -Name "AzureADPreview" -ListAvailable}
    if ($AadModule -eq $null) {write-host "AzureAD Powershell module is not installed. The module can be installed by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt. Stopping." -f Yellow;exit}
    if ($AadModule.count -gt 1) {
        $Latest_Version = ($AadModule | select version | Sort-Object)[-1]
        $aadModule      = $AadModule | ? { $_.version -eq $Latest_Version.version }
        $adal           = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms      = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
        }
    else {
        $adal           = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms      = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
        }
    [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
    [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null
    $authority          = "https://login.microsoftonline.com/$TenantName"
    $authContext        = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
    $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters"    -ArgumentList $CredPrompt
    $authResult         = $authContext.AcquireTokenAsync($resourceAppIdURI, $clientId, $redirectUri, $platformParameters).Result
    return $authResult
    }

Function Invoke-MSGraphQuery($AccessToken, $Uri, $Method, $Body){
    Write-Progress -Id 1 -Activity "Executing query: $Uri" -CurrentOperation "Invoking MS Graph API"
    $Header = @{
        'Content-Type'  = 'application\json'
        'Authorization' = $AccessToken.CreateAuthorizationHeader()
        }
    $QueryResults = @()
    if($Method -eq "Get"){
        do{
            $Results =  Invoke-RestMethod -Headers $Header -Uri $Uri -UseBasicParsing -Method $Method -ContentType "application/json"
            if ($Results.value -ne $null){$QueryResults += $Results.value}
            else{$QueryResults += $Results}
            write-host "Method: $Method | URI $Uri | Found:" ($QueryResults).Count
            $uri = $Results.'@odata.nextlink'
            }until ($uri -eq $null)
        }
    if($Method -eq "Patch"){
        $Results =  Invoke-RestMethod -Headers $Header -Uri $Uri -Method $Method -ContentType "application/json" -Body $Body
        write-host "Method: $Method | URI $Uri | Executing"
        }
    Write-Progress -Id 1 -Activity "Executing query: $Uri" -Completed
    Return $QueryResults
    
    }

$resourceAppIdURI = "https://graph.microsoft.com"
$ClientID         = "XXXXXXX"   #AKA Application ID "89d46938-c368-4c47-9b04-5050ed29b7e8"
$TenantName       = "cotoso.onmicrosoft.com"             #Your Tenant Name
$CredPrompt       = "Auto"                                   #Auto, Always, Never, RefreshSession
$redirectUri      = "https://yoururl"                #Your Application's Redirect URI
$Uri              = "https://graph.microsoft.com/beta/oauth2PermissionGrants" #The query you want to issue to Invoke a REST command with
$Method           = "Get"                                    #GET or PATCH
$AccessToken      = Get-AccessToken -TenantName $TenantName -ClientID $ClientID -redirectUri $redirectUri -resourceAppIdURI $resourceAppIdURI -CredPrompt $CredPrompt
$JSON = @" 
    {
    "userPrincipalName": "example@microsoft.com"
    }
"@ #JSON Syntax if you are performing a PATCH

$permission_result = Invoke-MSGraphQuery -AccessToken $AccessToken -Uri $Uri -Method $Method -Body $JSON

$permission_result | Export-Csv -Path d:\all_oauth2permission_list.csv -NoTypeInformation 
