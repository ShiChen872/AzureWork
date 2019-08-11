<#
.Synopsis
Used to get Azure AD Application Key expired date
.DESCRIPTION
We cannot use AzureAD PowerShell to get info data directly. But we can get the metadata file and use file to get hashvalue of keyinfo

.EXAMPLE
Replace tenantID to replace your tenantID.

#>

#connect to Azure AD
Import-Module AzureAD
$Credential=Get-Credential
Connect-AzureAD -Credential $Credential
#create report objects
$AzureADAppReport= New-Object PSObject
$AzureADAppReport | Add-Member -MemberType NoteProperty -Name ApplicationName -Value NotSet
$AzureADAppReport | Add-Member -MemberType NoteProperty -Name CertCreatedDate -Value NotSet
$AzureADAppReport | Add-Member -MemberType NoteProperty -Name ExipredDate -Value NotSet

#get all enterprise app list
$enterpriseapp= Get-AzureADApplication

#get applicaiton parameters
$tenantid = "febaeed4-9f82-465d-ba53-fedccbd7e5c3" 
$appid = $enterpriseapp.appid
$i=0

Foreach ($app in $appid){ 
        
      $Uri = "https://login.microsoftonline.com/$tenantid/federationmetadata/2007-06/federationmetadata.xml?appid=$app"

      $appDisplayName = ((Get-AzureADApplication).DisplayName)[$i]

      #get CertHash from website
        $file = Invoke-RestMethod -Uri $Uri 
        $file2 = $file.Split('<')[21]
        $CertHash = $file2.Split('>')[1]
        #export certhashkey to cert to read expired date:
            $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
            $CertHash | Out-File "$appDisplayName.txt"
            $data = Get-Content "$appDisplayName.txt" -Raw
            $cert.Import([Convert]::FromBase64String($data))
                   
            # Output app certdata
            Write-Host "Get app:$appDisplayName Cert info"             
            #Fill AzureADAPPreport info
            $AzureADAppReport.ApplicationName = $appDisplayName
            $AzureADAppReport.CertCreatedDate = $cert.NotBefore
            $AzureADAppReport.ExipredDate = $cert.NotAfter
            
            #Output CSV
            $AzureADAppReport | Out-File d:\AzureAD_app_cert_info.csv -Append
            $i++
      }

Write-Host 'Finish export'
