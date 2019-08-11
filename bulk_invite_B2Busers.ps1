#Connect to Azure AD
$Creds = Get-Credential
Connect-AzureAD -Credential $creds -TenantId “aaaaa-bbbbb-ccccc-ddddd”
$messageInfo = New-Object Microsoft.Open.MSGraph.Model.InvitedUserMessageInfo
$messageInfo.customizedMessageBody = “welcome to my world!”
New-AzureADMSInvitation -InvitedUserEmailAddress “contoso@contoso.com” -InvitedUserDisplayName “contoso”  -InviteRedirectUrl https://myapps.microsoft.com -InvitedUserMessageInfo $messageInfo -SendInvitationMessage $false