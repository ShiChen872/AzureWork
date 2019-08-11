<#
.Synopsis
   Backup the ADFS Farm.
.DESCRIPTION
   This script backups the current ADFS farm on which the script is running.

   This script should be run on the primary FS of the ADFS farm you want to backup.

   It uses ADFS Rapid Recreation Tool, this .msi has to be installed on the primary FS of the farm you want to backup.

   /!\ You cannot do a granular restore with it, if you do a restore, you have to restore the entire farm (it  done very quickly
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

[CmdletBinding()]
Param($BackupFolder = "\\server address\d$\Backups_ADFS")

$Today = Get-Date -Format yyyy-MM-dd
$DailyBackupFolder = "$BackupFolder\$Today"
$DailyFSBackupFolder = "$DailyBackupFolder\FS"
$DailyWAPBackupFolder = "$DailyBackupFolder\WAP"
$WAPServers = "server address"

# Function declaration
Function Initialize-EventLog()
    {
	New-EventLog -LogName BackupADFS -Source BackupADFS
	Write-EventLog -LogName BackupADFS -Source BackupADFS -EntryType Information -EventId 0 -Message "Log initialized"
    }

Function Check-EventLog()
    {
    Try
        {
        Get-EventLog -LogName BackupADFS -Source BackupADFS
        Write-Verbose "EventLog Initialized"
        }
    Catch
        {
        Initialize-EventLog
        }
    }

Check-EventLog

If ((Get-AdfsSyncProperties).Role -ne "PrimaryComputer")
    {
    Write-EventLog -LogName BackupADFS -Source BackupADFS -EntryType Error -EventId 123 -Message "This server is not the primary computer of the ADFS Farm, please run it on the PrimaryComputer. Aborting script..."
    Exit 123
    }
    

# Check if ADFS Recreation tool is present
If (Test-Path -Path 'C:\Program Files (x86)\ADFS Rapid Recreation Tool')
    {
    Try 
        {
        Import-Module 'C:\Program Files (x86)\ADFS Rapid Recreation Tool\ADFSRapidRecreationTool.dll' -ErrorAction Stop
        }
    Catch
        {
        Write-EventLog -LogName BackupADFS -Source BackupADFS -EntryType Error -EventId 123 -Message "Problem during ADFS Rapid Recreation tool module importation. Aborting script..."
        Exit 123
        }
    }
Else
    {
    Write-EventLog -LogName BackupADFS -Source BackupADFS -EntryType Error -EventId 123 -Message "Can't find ADFS Rapid Recreation tool module. Aborting script..."
    Exit 123
    }

# Check if the daily backup folder already exists or not

If (-not(Test-Path -Path $DailyBackupFolder))
    {
    Try
        {
        New-Item -Path $DailyBackupFolder -ItemType Directory -ErrorAction Stop
        New-Item -Path $DailyFSBackupFolder -ItemType Directory -ErrorAction Stop
        New-Item -Path $DailyWAPBackupFolder -ItemType Directory -ErrorAction Stop
        }
    Catch
        {
        Write-EventLog -LogName BackupADFS -Source BackupADFS -EntryType Error -EventId 123 -Message "Problem during the daily backup folder creation. Aborting script..."
        Exit 123
        }
    }
Else
    {
    Write-EventLog -LogName BackupADFS -Source BackupADFS -EntryType Error -EventId 123 -Message "Daily backup folder $DailyBackupFolder already exists, please remove it before. Aborting script..."
    Exit 123
    }

# Backup FS

    Try
        {
        Backup-ADFS -StorageType FileSystem -StoragePath $DailyFSBackupFolder -EncryptionPassword $EncryptionPassword -BackupDKM
        }
    Catch
        {
        Write-EventLog -LogName BackupADFS -Source BackupADFS -EntryType Error -EventId 123 -Message "Problem during FS backup, exiting script."
        Exit 123
        }

Write-EventLog -LogName BackupADFS -Source BackupADFS -EntryType Information -EventId 124 -Message "FS Backup executed successfully."

# Backup WAP
If (Invoke-Command -ComputerName $WAPServers -ScriptBlock {Get-WebApplicationProxyHealth})
    {
    Try
        {
        Invoke-Command -ComputerName ($WAPServers | Get-Random) -ScriptBlock {Get-WebApplicationProxyApplication} -ErrorAction Stop | Export-Csv -Path $DailyWAPBackupFolder\WapPublishedApps.csv -NoTypeInformation -ErrorAction Stop
        #$WAPServers | ForEach-Object {Get-ADComputer -Identity $_ -Properties msDS-AllowedToDelegateTo | Select-Object -ExpandProperty msDS-AllowedToDelegateTo | Out-File $DailyWAPBackupFolder\$_-SPNS.csv}
        }
    Catch
        {
        Write-EventLog -LogName BackupADFS -Source BackupADFS -EntryType Error -EventId 123 -Message "Problem during WAP Backup. Aborting script..."
        Exit 123
        }
    }
Else
    {
    Write-EventLog -LogName BackupADFS -Source BackupADFS -EntryType Error -EventId 123 -Message "Get-WebApplicationProxyHealth failed on one of the WAP servers. Aborting script..."
    Exit 123
    }

Write-EventLog -LogName BackupADFS -Source BackupADFS -EntryType Information -EventId 124 -Message "WAP Backup executed successfully."
