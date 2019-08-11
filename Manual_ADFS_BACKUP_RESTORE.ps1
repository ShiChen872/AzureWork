<#
.Synopsis
   Backup/Restore ADFS/WAP server for DR.
.DESCRIPTION
   This script uses define function to backups the current ADFS/WAP servers manually.

   This script should be run on the primary FS of the ADFS farm you want to backup.

   It uses ADFS Rapid Recreation Tool, this .msi has to be installed on the primary FS of the farm you want to backup.
   
   The script supports on ADFS v3 or later version

   /!\ You cannot do a granular restore with it, if you do a restore, you have to restore the entire farm (it  done very quickly)
   !! all references refer to the following articles:
   https://docs.microsoft.com/en-us/windows-server/identity/ad-fs/operations/ad-fs-rapid-restore-tool#encryption-information
   https://blog.auth360.net/2016/10/02/backup-and-recovery-with-the-ad-fs-rapid-restore-tool/
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Backup the ADFS farm manually (commands have to be run on the primary FS server of the farm) :
   1) Launch the following command (be sure to have the ADFS Rapid Recreation Tool module imported before (Import-Module 'C:\Program Files (x86)\ADFS Rapid Recreation Tool\ADFSRapidRecreationTool.dll') :
   Backup-ADFS -StorageType FileSystem -StoragePath '\\server_name\d$\Backups_ADFS\2017-10-18' -EncryptionPassword (Get-ADFSEncryptionSecretFromGNSPassword) -BackupDKM
   2) Your backup is done.

   Restore the ADFS farm manually (commands have to be run on the primary FS server of the farm) :
   /!\ When you run that command, it will restore the entire farm, even if you just want one Relying Party Trust to be restored /!\
   The restore takes approximately 1min
   1) Launch the following command (be sure to have the ADFS Rapid Recreation Tool module imported before (Import-Module 'C:\Program Files (x86)\ADFS Rapid Recreation Tool\ADFSRapidRecreationTool.dll') :
   Restore-ADFS -StorageType FileSystem -StoragePath '\\server_name\d$\Backups_ADFS\2017-10-18\FS\' -DecryptionPassword (Get-ADFSEncryptionSecretFromGNSPassword)
   Start-Service adfssrv
   2) Your ADFS farm is restored and functional.

   Backup WAP apps :
   Invoke-Command -ComputerName XXX -ScriptBlock {Get-WebApplicationProxyApplication} | Export-Csv -Path .\WapPublishedApps.csv -NoTypeInformation

   Restore WAP apps :
   Import-Csv -Path C:\Temp\WapPublishedApps.csv | ForEach-Object {Invoke-Command -ComputerName $_.PSComputerName -ScriptBlock {Add-WebApplicationProxyApplication -Name $Using:_.Name -ExternalUrl $Using:_.ExternalUrl -BackendServerUrl $Using:_.BackendServerUrl -ExternalCertificateThumbprint $Using:_.ExternalCertificateThumbprint -ExternalPreauthentication $Using:_.ExternalPreauthentication -BackendServerAuthenticationSPN $Using:_.BackendServerAuthenticationSPN -ADFSRelyingPartyName $Using:_.ADFSRelyingPartyName -Verbose}}

   Restore Kerberos delegation on the WAP Computer object :
   Import-Csv -Path C:\Temp\WapPublishedApps.csv | ForEach-Object {Set-ADcomputer –Identity $_.PSComputerName -add @{"msDS-AllowedToDelegateTo"="$($_.BackendServerAuthenticationSPN)"} -ErrorAction SilentlyContinue} | Out-Null
#>

