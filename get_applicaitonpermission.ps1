#connect to Azure AD preview environment
##import azure ad preview module

Import-Module azureadpreview

##$Credential = Get-Credential

#connect to azure ad -Credential $Credential
Connect-AzureAD 

#retrive all service pricinial from directory

$AADServicePrincipal = Get-AzureADServicePrincipal -All $true

#retrive objectID 
$ServicePrincipalObjectID = $AADServicePrincipal.objectID

Write-Host 'Start to query AppGrantedPermission'

foreach($objectid in $ServicePrincipalObjectID)

    {
        #get applicaiton permission 
        $appprincialPermission = Get-AzureADServicePrincipalOAuth2PermissionGrant -ObjectId $objectid -ErrorAction SilentlyContinue
        
        if ($appprincialPermission -ne $null) 
            {
                $reports += $appprincialPermission
             }

        }
# export-report to path d:\Reports_ApplicaitonGrantedPermission.csv

$reports | export-csv -Path d:\Reports_ApplicaitonGrantedPermission.csv 
Write-Host 'Finish export to path d:\Reports_ApplicaitonGrantedPermission.csv'