# Get-ADSecurityAudit.ps1
# Milestone 142 - Active Directory Security Audit
# Domain: corp.example.test
# Purpose: Read-only Active Directory security assessment

#Requires -Modules ActiveDirectory

$ErrorActionPreference = "Stop"
$AuditDate = Get-Date
$InactiveDays = 90

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " ACTIVE DIRECTORY SECURITY AUDIT" -ForegroundColor Cyan
Write-Host " Domain: $((Get-ADDomain).DNSRoot)"
Write-Host " Date: $AuditDate"
Write-Host "========================================" -ForegroundColor Cyan

# 1. Disabled Accounts
Write-Host "`n[1] DISABLED ACCOUNTS" -ForegroundColor Yellow

Get-ADUser -Filter 'Enabled -eq $false' |
    Select-Object Name, SamAccountName, Enabled |
    Format-Table -AutoSize

# 2. Passwords Never Expire
Write-Host "`n[2] PASSWORDS NEVER EXPIRE" -ForegroundColor Yellow

Get-ADUser -Filter 'PasswordNeverExpires -eq $true' `
    -Properties PasswordNeverExpires |
    Select-Object Name, SamAccountName, Enabled, PasswordNeverExpires |
    Format-Table -AutoSize

# 3. Inactive Accounts
Write-Host "`n[3] INACTIVE ACCOUNTS (90+ DAYS)" -ForegroundColor Yellow

Get-ADUser -Filter 'Enabled -eq $true' -Properties LastLogonDate |
    Where-Object {
        $_.LastLogonDate -and
        $_.LastLogonDate -lt (Get-Date).AddDays(-$InactiveDays)
    } |
    Select-Object Name, SamAccountName, LastLogonDate |
    Format-Table -AutoSize

# 4. Privileged Group Membership
$PrivilegedGroups = @(
    "Domain Admins",
    "Enterprise Admins",
    "Schema Admins"
)

foreach ($Group in $PrivilegedGroups) {

    Write-Host "`n[4] PRIVILEGED GROUP: $Group" -ForegroundColor Yellow

    Get-ADGroupMember -Identity $Group |
        Select-Object Name, SamAccountName, objectClass |
        Format-Table -AutoSize
}

# 5. User Accounts with SPNs
Write-Host "`n[5] USER ACCOUNTS WITH SPNs" -ForegroundColor Yellow

Get-ADUser -Filter * -Properties ServicePrincipalName |
    Where-Object { $_.ServicePrincipalName.Count -gt 0 } |
    Select-Object Name, SamAccountName, Enabled |
    Format-Table -AutoSize

# 6. Accounts Without Recorded Logons
Write-Host "`n[6] NO RECORDED LAST LOGON" -ForegroundColor Yellow

Get-ADUser -Filter 'Enabled -eq $true' -Properties LastLogonDate |
    Where-Object { $null -eq $_.LastLogonDate } |
    Select-Object Name, SamAccountName, Enabled |
    Format-Table -AutoSize

# 7. Password Not Required
Write-Host "`n[7] PASSWORD NOT REQUIRED" -ForegroundColor Yellow

Get-ADUser -Filter 'Enabled -eq $true' -Properties PasswordNotRequired |
    Where-Object { $_.PasswordNotRequired -eq $true } |
    Select-Object Name, SamAccountName, PasswordNotRequired |
    Format-Table -AutoSize

# 8. Kerberos Preauthentication Disabled
Write-Host "`n[8] KERBEROS PREAUTHENTICATION DISABLED" -ForegroundColor Yellow

Get-ADUser -Filter 'Enabled -eq $true' -Properties DoesNotRequirePreAuth |
    Where-Object { $_.DoesNotRequirePreAuth -eq $true } |
    Select-Object Name, SamAccountName, DoesNotRequirePreAuth |
    Format-Table -AutoSize

Write-Host "`n========================================" -ForegroundColor Green
Write-Host " AUDIT COMPLETE - NO CHANGES MADE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
