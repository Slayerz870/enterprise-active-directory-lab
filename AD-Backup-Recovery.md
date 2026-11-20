
# Active Directory Backup & Recovery

## Milestone 148 — Windows Server 2025

### Environment
- Domain: corp.example.test
- Domain Controller: DC01
- Operating System: Windows Server 2025
- Virtualization: VMware Workstation
- Backup Software: Windows Server Backup

### Backup Storage
- Disk: VMware Virtual SCSI Disk
- Capacity: 60 GB
- Drive Letter: E:
- Volume Label: AD_Backup
- File System: NTFS
- Health Status: Healthy

### Backup Configuration

Installed Windows Server Backup:

```powershell
Install-WindowsFeature Windows-Server-Backup -IncludeManagementTools
```

Created a dedicated GPT backup disk and formatted it as NTFS.

### System State Backup

Executed:

```powershell
wbadmin start systemstatebackup -backupTarget:E: -quiet
```

Result: Backup operation successfully completed.

Backup version: `11/20/2026-00:36`

### Backup Verification

Verified available recovery versions:

```powershell
wbadmin get versions -backupTarget:E:
```

Verified recoverable components:

```powershell
wbadmin get items -version:11/20/2026-00:36 -backupTarget:E:
```

Confirmed the backup includes:
- Active Directory database (NTDS)
- SYSVOL
- Windows Registry
- EFI System Partition
- Required system-state components

Verified backup directory:

`E:\WindowsImageBackup\DC01`

### Recovery Considerations

System State recovery can restore critical domain controller components after certain failures.

**A recovery operation has not been performed or tested.**

For an actual domain controller recovery:

1. Determine the failure and appropriate recovery method.
2. Verify the backup version and availability.
3. Follow Microsoft's supported Active Directory recovery procedure.
4. Perform recovery in the appropriate recovery environment.
5. Validate AD DS, DNS, SYSVOL, and authentication afterward.

### Limitations

- The backup resides on the same VMware host as DC01.
- Off-host backups are recommended for disaster recovery.
- Backup catalog verification does not guarantee successful restoration.
- A separate test restore is required to validate recoverability.

### Status

- System State Backup: SUCCESSFUL
- Backup Catalog Verification: PASSED
- Recovery Test: NOT PERFORMED
