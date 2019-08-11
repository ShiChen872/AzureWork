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
Used to bulk invite B2B users

.DESCRIPTION
The script is used to bulk invite B2B users.

.Contact

Author: Andy Shi
Email: v-anshi@outlook.com
#>

#Connect to Azure AD
$Creds = Get-Credential
Connect-AzureAD -Credential $creds -TenantId “aaaaa-bbbbb-ccccc-ddddd”
$messageInfo = New-Object Microsoft.Open.MSGraph.Model.InvitedUserMessageInfo
$messageInfo.customizedMessageBody = “welcome to my world!”
New-AzureADMSInvitation -InvitedUserEmailAddress “contoso@contoso.com” -InvitedUserDisplayName “contoso”  -InviteRedirectUrl https://myapps.microsoft.com -InvitedUserMessageInfo $messageInfo -SendInvitationMessage $false