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
Used to get All RBAC Role information by using CSV file

.DESCRIPTION
The script is used to capture all RBAC info from CSV file

.Contact

Author: Andy Shi
Email: shi.chen@microsoft.com
Email: v-anshi@microsoft.com

.EXAMPLE
Replace Path and file for CSV 

version 2 is supported mutiple domains
add feature to record logs

#>


##Init the EventLog 
Function Initialize-EventLog()
{
    New-EventLog -LogName Application -Source "Example_AAD"
    Write-EventLog -LogName Application -Source "Example_AAD" -EntryType Information -EventId 0 -Message "Log initialized"
}

function Check-EventLog()
{
Try
  {
    $test=Get-EventLog -LogName Application -Source "Example_AAD" -Newest 1 -ErrorAction Stop
    Write-Verbose "EventLog Initialized"
  }
  Catch
  {
    #if it gets here, event log has to be initialised
    Initialize-EventLog
  }
}

#Start to check
Check-EventLog


##load module
Import-Module AzureAD
##$Credential
$Crendential = Get-Credential

##Connect Azure AD
#Connect-AzureAD -Credential $Crendential
Connect-AzureAD
##Connect Azure RM resource
#Connect-AzureRmAccount -Credential $Crendential
Connect-AzAccount


#get all subscriptions
$azure_rm_subscription = Get-AzureRmSubscription
$att2=$azure_rm_subscription.Id
#make $RM_Sub_ID as array
$RM_Sub_ID = @()
$RM_Sub_ID += $azure_rm_subscription.Id

##Create new objects with required information for SG

$Data = New-Object PSObject
$Data | Add-Member -MemberType NoteProperty -Name DisplayName -Value NotSet
$Data | Add-Member -MemberType NoteProperty -Name ObjectID -Value Notset
$Data | Add-Member -MemberType NoteProperty -Name ResourceType -Value Notset
$Data | Add-Member -MemberType NoteProperty -Name Scope -Value Notset
$Data | Add-Member -MemberType NoteProperty -Name RoleDefinitionName -Value Notset
$Data | Add-Member -MemberType NoteProperty -Name ResourceDetails -Value Notset
$Data | Add-Member -MemberType NoteProperty -Name AzureRMSubscription -Value Notset


##Import CSV info
$CSV = Import-Csv -Path D:\work\AAD_Group.csv
$AADSG_ObjectId = $CSV.ObjectID

#loop to get search for all subscriptions:

Try
{
    foreach ($sub_id in $RM_Sub_ID)
    {
    #Select subscription
    $Selct_sub = Select-AzureRmSubscription -Subscription $sub_id

    Write-Host "searching for $Selct_sub.SubscriptionName"

    Foreach($ObjectID in $AADSG_ObjectId)
    {
    #Get RBAC role list for ObjectID
    $RBAC_list = Get-AzureRmRoleAssignment -ObjectId $ObjectID

    $AADSG_DisplayName = $RBAC_list.DisplayName
    $i=0

        Foreach($SG_Name in $AADSG_DisplayName)
        {
            #Output objects
            Write-Host "Get $SG_Name RBAC role info "
            $roleInfo = $RBAC_list[$i].RoleAssignmentId 
            $ResourceType = $roleInfo.Split("/")[3]

            #split 'providers info'

            $SplitProvderInfo = $RBAC_list[$i].RoleAssignmentId -split "providers"      
            
            $ResourceDetails = $SplitProvderInfo[1]
                
             
                 ##fill data into $Data
                    $Data.DisplayName = $SG_Name
                    $Data.ObjectID = $RBAC_list[$i].ObjectId
                    $Data.ResourceType = $ResourceType
                    $Data.ResourceDetails = $ResourceDetails
                    $Data.Scope = $RBAC_list[$i].Scope
                    $Data.RoleDefinitionName = $RBAC_list[$i].RoleDefinitionName
                    $Data.AzureRMSubscription = $Selct_sub.SubscriptionName

                    ##Output CSV
                    $Data | Out-File D:\work\AAD_Group_RBACRole2.csv -Append

                     #i++
                    $i++
            }  

        
        }

        Write-Host "finish search $Selct_sub.SubscriptionName"
        Write-EventLog -LogName Application -Source "Example_AAD" -EventID 30 -EntryType Information -Message "$Selct_sub.SubscriptionName was sucessful searched"
    }

    Write-Host "Finsh export All RBAC role info from SG CSV files"
    }
Catch
{
    Write-EventLog -LogName Application -Source "Example_AAD" -EventID 31 -EntryType Error -Message $_.Exception.Message
}

