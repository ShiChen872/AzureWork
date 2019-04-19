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
.Synopsis
Used to get All AAD Sign-in and Audit reports information by using CSV file

.DESCRIPTION
The script is used to capture AAD Sign-in and Audit info from CSV file

.Contact

Author: Andy Shi
Email: v-anshi@outlook.com

.EXAMPLE
Replace Path and file for CSV 
Replace the domain name
To use Graph app, you need to prepare the following:
https://www.sunilchauhan.info/2019/02/working-with-microsoft-graph-api-using.html 

#>

Connect-AzureAD
Set-Location "c:\Work\Tools\msgraph\Graph_Script"
$tenantdomain = "chshi.msftonlinelab.com"
$application = Get-AzureADApplication -SearchString "Graph_API"

# MS Graph token
$ClientID_MSG       = $application.appid
$ClientSecret_MSG   = (Get-Content .\key.txt)[3]
$loginURL_MSG       = "https://login.microsoftonline.com"
$resource_MSG       = "https://graph.microsoft.com"
$Cred_MSG           = @{grant_type="client_credentials";resource=$resource_MSG;client_id=$ClientID_MSG;client_secret=$ClientSecret_MSG}
$oauth_MSG          = Invoke-RestMethod -Method Post -Uri $loginURL_MSG/$tenantdomain/oauth2/token?api-version=1.0 -Body $Cred_MSG
$headerParams_MSG   = @{'Authorization'="$($oauth_MSG.token_type) $($oauth_MSG.access_token)"}

# List users
Invoke-RestMethod -Uri $resource_MSG/v1.0/users/ -Method get -Headers $headerParams_MSG | ConvertTo-Json

# List groups
Invoke-RestMethod -Uri $resource_MSG/v1.0/groups/ -Method get -Headers $headerParams_MSG | ConvertTo-Json

# List devices
Invoke-RestMethod -Uri $resource_MSG/v1.0/devices/ -Method get -Headers $headerParams_MSG | ConvertTo-Json

# List Applications
Invoke-RestMethod -Uri $resource_MSG/beta/applications -Method Get -Headers $headerParams_MSG | ConvertTo-Json

# List service Principals
Invoke-RestMethod -Uri $resource_MSG/beta/servicePrincipals -Method Get -Headers $headerParams_MSG | ConvertTo-Json

# list subscriptions
Invoke-RestMethod -Uri $resource_MSG/beta/subscribedSkus -Method get -Headers $headerParams_MSG | ConvertTo-Json

# list policies
Invoke-RestMethod -Uri $resource_MSG/beta/policies -Method get -Headers $headerParams_MSG | ConvertTo-Json

# org information
Invoke-RestMethod -Uri $resource_MSG/beta/organization -Method get -Headers $headerParams_MSG | ConvertTo-Json

# list of directoryroletemplate objects
Invoke-RestMethod -Uri $resource_MSG/beta/directoryRoleTemplates -Method get -Headers $headerParams_MSG | ConvertTo-Json

# list directory roles
Invoke-RestMethod -Uri $resource_MSG/beta/directoryRoles -Method get -Headers $headerParams_MSG | ConvertTo-Json

# list of oauth2PermissionGrant objects
Invoke-RestMethod -Uri $resource_MSG/beta/oauth2PermissionGrants -Method get -Headers $headerParams_MSG | ConvertTo-Json


# write the extension attribute to group
$body1 = @{
    extension_6c0a03010d604c35b82ef0b00dc0168a_Groupattr1 = "123"
} | ConvertTo-Json
Invoke-RestMethod -Uri $resource_MSG/v1.0/groups/1eac68a3-00f4-46fb-bff6-693f3cfda36a -Method patch -Headers $headerParams_MSG -ContentType "application/json" -Body $body1

# remove the extension attribute to group
$body2 = @{
    extension_6c0a03010d604c35b82ef0b00dc0168a_Groupattr1 = ""
} | ConvertTo-Json
Invoke-RestMethod -Uri $resource_MSG/v1.0/groups/1eac68a3-00f4-46fb-bff6-693f3cfda36a -Method patch -Headers $headerParams_MSG -ContentType "application/json" -Body $body2


# Download Audit report and convert to CSV format
function Export-AADAudit
{
    $i=0
    Do{
        $myReport = (Invoke-RestMethod -Uri $resource_MSG/beta/auditLogs/directoryAudits -Method Get -Headers $headerParams_MSG)
        $XMLReportValues += $myreport.value
        $XMLReportValues | select * | Export-csv c:\AADAudit$i.csv -NoTypeInformation -Force -append 
        $url = $myReport.'@odata.nextLink'
        $i = $i+1
     } while($url -ne $null)
}

# Download sign-in report and convert to CSV format
function Export-AADSignin
{
    $i=0
    Do{
          $myReport = (Invoke-RestMethod -Uri $resource_MSG/beta/auditLogs/signIns -Method Get -Headers $headerParams_MSG)
          $XMLReportValues += $myreport.value
          $XMLReportValues | select * | Export-csv c:\AADSingins$i.csv -NoTypeInformation -Force -append 
          $url = $myReport.'@odata.nextLink'
        $i = $i+1
     } while($url -ne $null)
}


# Download risk sign-in report and convert to CSV format
function Export-AADRisk
{
    $i=0
    Do{
        $myReport = (Invoke-RestMethod -Uri $resource_MSG/beta/identityRiskEvents -Method Get -Headers $headerParams_MSG)
        $XMLReportValues += $myreport.value
        $XMLReportValues | select * | Export-csv c:\AADRisk$i.csv -NoTypeInformation -Force -append 
        $url = $myReport.'@odata.nextLink'
        $i = $i+1
     } while($url -ne $null)
 }