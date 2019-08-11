#Connect to Azure AD environment
Import-Module MSOnline
$Credential = Get-Credential
Connect-MSOLService –credential $Credential 

#Create new object with requested information of the users.
$Data = New-Object PSObject
$Data | Add-Member -MemberType NoteProperty -name UserPrincipalName -value NotSet
$Data | Add-Member -MemberType NoteProperty -name Enforced -value NotSet
$Data | Add-Member -MemberType NoteProperty -name Default -value NotSet
$Data | Add-Member -MemberType NoteProperty -name AlternativePhoneNumber –value NotSet
$Data | Add-Member -MemberType NoteProperty -name Email –value NotSet
$Data | Add-Member -MemberType NoteProperty -name PhoneNumber –value NotSet
$Data | Add-Member -MemberType NoteProperty -name ProofupTime –value NotSet

#Get all users total
$AllUsers = Get-MSOLuser –all | Measure
$AllUsers = $AllUsers.Count

#Retrieve all enabled MFA users
$RawData = Get-MsolUser | Where{$_.StrongAuthenticationMethods -ne $null} | select UserPrincipalName,StrongAuthenticationMethods,StrongAuthenticationPhoneAppDetails,StrongAuthenticationRequirements,StrongAuthenticationUserDetails

#Get MFA User Total
$AllAzureMFAUsers = $Rawdata | Measure
$AllAzureMFAUsers = $AllAzureMFAUsers.Count

#Fill results object $Data with requested information
$Data = ForEach($User in $RawData){

    #Create new object for passing back the required information
    $Result = New-Object PSObject
    $Result | Add-Member -MemberType NoteProperty –name UserPrincipalName –value Notset
    $Result | Add-Member -MemberType NoteProperty –name Enforced –value NotSet
    $Result | Add-Member -MemberType NoteProperty –name Default –value NotSet
    $Result | Add-Member -MemberType NoteProperty –name AlternativePhoneNumber –value NotSet
    $Result | Add-Member -MemberType NoteProperty –name Email –value NotSet
    $Result | Add-Member -MemberType NoteProperty –name PhoneNumber –value NotSet
    $Result | Add-Member -MemberType NoteProperty –name ProofupTime –value NotSet

    #Fill the UserPrincipalName
    $Result.UserPrincipalName = $User.UserPrincipalName

    #Move object information one level up.
    $Temp = $User.StrongAuthenticationRequirements

    #Fill the value if the MFA is enforced.
    $Result.Enforced = $Temp.State

    #Move object information one level up.
    $Temp = $User.StrongAuthenticationMethods

    #Get preferred method and place it in $Temp.
    $Temp = $Temp | Where{$_.IsDefault -eq "True"} | Select MethodType

    #Fill the Preferred method to value Default
    $Result.Default = $Temp.MethodType

    #Move object information one level up.
    $Temp = $User.StrongAuthenticationUserDetails

    #Fill the values with retrieved information.
    $Result.AlternativePhoneNumber = $Temp.AlternativePhoneNumber
    $Result.Email = $Temp.Email
    $Result.PhoneNumber = $Temp.PhoneNumber

    #Convert last enrollment date
    $Result.Proofuptime = [datetime]($User.StrongAuthenticationProofupTime)

    #Passback the object to data
    $Result
}

#Create output string with user totals
$OutputUsers = "Total users in AzureAD: $AllUsers
Total users enabled for Azure MFA: $AllAzureMFAUsers"

#Output information to file
$OutputUsers | Out-File -FilePath ".\Result_Enabled_AzureMFA_Users.log"
$Data | export-csv -Path ".\Result_Enabled_AzureMFA_Users.csv" -delimiter ";"