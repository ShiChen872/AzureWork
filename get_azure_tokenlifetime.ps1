Import-Module AzureADPreview

Connect-AzureAD

$aadtokenlifetime = Get-AzureADPolicy | Where-Object {$_.type -eq 'tokenlifetimepolicy'} | Select-Object displayname,type,IsOranazationDefault,Definition

$aadtokenlifetime.definition |ConvertFrom-Json | Select-Object -ExcludeProperty tokenlifetimepolicy | Select-Object $aadtokenlifetime.displayname,MaxInactiveTime,MaxAgeSingleFactor,MaxAgeMultifactor,MaxAgeSessionSingleFactor,MaxAgeSessionMultiFactor
