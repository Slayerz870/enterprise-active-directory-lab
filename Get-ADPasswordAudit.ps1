# ============================================
# ACTIVE DIRECTORY PASSWORD SECURITY AUDIT
# Milestone 143
# Domain: corp.example.test
# Read-Only Security Assessment
# ============================================

Import-Module ActiveDirectory -ErrorAction Stop

$Domain = (Get-ADDomain).DNSRoot
$Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Output "========================================"
Write-Output " ACTIVE DIRECTORY PASSWORD SECURITY AUDIT"
Write-Output " Domain: $Domain"
Write-Output " Date: $Date"
Write-Output "========================================"

# 1. Default Domain Password Policy
Write-Output "`n[1] DEFAULT DOMAIN PASSWORD POLICY"

Get-ADDefaultDomainPasswordPolicy |
    Select-Object ComplexityEnabled,
                  MinPasswordLength,
                  PasswordHistoryCount,
                  MaxPasswordAge,
                  MinPasswordAge,
                  LockoutThreshold,
                  LockoutDuration,
                  LockoutObservationWindow |
    Format-List | Out-String | Write-Output

# 2. Fine-Grained Password Policies
Write-Output "`n[2] FINE-GRAINED PASSWORD POLICIES"

$FGPP = @(Get-ADFineGrainedPasswordPolicy -Filter *)

if ($FGPP.Count -eq 0) {
    Write-Output "No fine-grained password policies configured."
}
else {
    $FGPP |
        Select-Object Name, Precedence,
                      MinPasswordLength, LockoutThreshold |
        Format-Table -AutoSize | Out-String | Write-Output
}

# 3. Passwords Never Expire
Write-Output "`n[3] ENABLED ACCOUNTS - PASSWORD NEVER EXPIRES"

$Users = @(Get-ADUser -Filter 'Enabled -eq $true' `
    -Properties PasswordNeverExpires, PasswordNotRequired,
                pwdLastSet, DoesNotRequirePreAuth)

$NeverExpire = @($Users | Where-Object PasswordNeverExpires)

if ($NeverExpire.Count -eq 0) {
    Write-Output "No matching accounts."
}
else {
    $NeverExpire |
        Select-Object Name, SamAccountName, PasswordNeverExpires |
        Format-Table -AutoSize | Out-String | Write-Output
}

# 4. Password Not Required
Write-Output "`n[4] ENABLED ACCOUNTS - PASSWORD NOT REQUIRED"

$NoPassword = @($Users | Where-Object PasswordNotRequired)

if ($NoPassword.Count -eq 0) {
    Write-Output "No matching accounts."
}
else {
    $NoPassword |
        Select-Object Name, SamAccountName, PasswordNotRequired |
        Format-Table -AutoSize | Out-String | Write-Output
}

# 5. Must Change Password at Next Logon
Write-Output "`n[5] PASSWORD CHANGE REQUIRED AT NEXT LOGON"

$MustChange = @($Users | Where-Object { $_.pwdLastSet -eq 0 })

if ($MustChange.Count -eq 0) {
    Write-Output "No matching accounts."
}
else {
    $MustChange |
        Select-Object Name, SamAccountName, pwdLastSet |
        Format-Table -AutoSize | Out-String | Write-Output
}

# 6. Locked Accounts
Write-Output "`n[6] LOCKED-OUT ACCOUNTS"

$Locked = @(Search-ADAccount -LockedOut -UsersOnly)

if ($Locked.Count -eq 0) {
    Write-Output "No locked-out accounts."
}
else {
    $Locked |
        Select-Object Name, SamAccountName, LockedOut |
        Format-Table -AutoSize | Out-String | Write-Output
}

# 7. Expired Passwords
Write-Output "`n[7] EXPIRED PASSWORDS"

$Expired = @(Search-ADAccount -PasswordExpired -UsersOnly)

if ($Expired.Count -eq 0) {
    Write-Output "No expired passwords detected."
}
else {
    $Expired |
        Select-Object Name, SamAccountName, Enabled |
        Format-Table -AutoSize | Out-String | Write-Output
}

# 8. Disabled Accounts
Write-Output "`n[8] DISABLED USER ACCOUNTS"

$Disabled = @(Search-ADAccount -AccountDisabled -UsersOnly)

if ($Disabled.Count -eq 0) {
    Write-Output "No disabled accounts."
}
else {
    $Disabled |
        Select-Object Name, SamAccountName, Enabled |
        Format-Table -AutoSize | Out-String | Write-Output
}

# 9. Kerberos Pre-Authentication
Write-Output "`n[9] KERBEROS PRE-AUTHENTICATION DISABLED"

$NoPreAuth = @($Users | Where-Object DoesNotRequirePreAuth)

if ($NoPreAuth.Count -eq 0) {
    Write-Output "No enabled accounts with pre-authentication disabled."
}
else {
    $NoPreAuth |
        Select-Object Name, SamAccountName, DoesNotRequirePreAuth |
        Format-Table -AutoSize | Out-String | Write-Output
}

Write-Output "`n========================================"
Write-Output " PASSWORD SECURITY AUDIT COMPLETE"
Write-Output "========================================"
