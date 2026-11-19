# ============================================
# Active Directory Attack Surface Audit
# Milestone 146 | Read-Only Security Assessment
# ============================================

Import-Module ActiveDirectory -ErrorAction Stop

$Domain = (Get-ADDomain).DNSRoot
$ReportPath = "C:\Scripts\ADAttackSurface-Report.txt"

$Report = [System.Collections.Generic.List[string]]::new()

$Report.Add("========================================")
$Report.Add(" ACTIVE DIRECTORY ATTACK SURFACE AUDIT")
$Report.Add(" Domain: $Domain")
$Report.Add(" Date: $(Get-Date)")
$Report.Add("========================================")

# Helper function for audit sections
function Add-AuditSection {
    param(
        [string]$Title,
        [array]$Results
    )

    $Report.Add("`n$Title")
    $Report.Add("Objects Found: $($Results.Count)")

    foreach ($Item in $Results) {
        $Report.Add(
            "Name: $($Item.Name) | Type: $($Item.ObjectClass)"
        )
    }
}

# 1. KERBEROS PREAUTHENTICATION DISABLED
$PreAuthDisabled = @(
    Get-ADObject `
        -LDAPFilter "(userAccountControl:1.2.840.113556.1.4.803:=4194304)"
)

Add-AuditSection `
    "[1] KERBEROS PREAUTHENTICATION DISABLED" `
    $PreAuthDisabled

# 2. USER ACCOUNTS WITH SPNs
$SPNAccounts = @(
    Get-ADUser -Filter {
        ServicePrincipalName -like "*"
    } -Properties ServicePrincipalName
)

Add-AuditSection `
    "[2] USER ACCOUNTS WITH SERVICE PRINCIPAL NAMES" `
    $SPNAccounts

foreach ($Account in $SPNAccounts) {
    $Report.Add(
        "SPNs: $($Account.ServicePrincipalName -join ', ')"
    )
}

# 3. UNCONSTRAINED DELEGATION - COMPUTERS
$UnconstrainedComputers = @(
    Get-ADComputer -Filter {
        TrustedForDelegation -eq $true
    } -Properties TrustedForDelegation
)

Add-AuditSection `
    "[3] COMPUTERS WITH UNCONSTRAINED DELEGATION" `
    $UnconstrainedComputers

# 4. TRADITIONAL CONSTRAINED DELEGATION
$ConstrainedDelegation = @(
    Get-ADObject `
        -LDAPFilter "(msDS-AllowedToDelegateTo=*)" `
        -Properties msDS-AllowedToDelegateTo
)

Add-AuditSection `
    "[4] TRADITIONAL CONSTRAINED DELEGATION" `
    $ConstrainedDelegation

foreach ($Object in $ConstrainedDelegation) {
    $Report.Add(
        "Targets: $($Object.'msDS-AllowedToDelegateTo' -join ', ')"
    )
}

# 5. RESOURCE-BASED CONSTRAINED DELEGATION
$RBCD = @(
    Get-ADObject `
        -LDAPFilter "(msDS-AllowedToActOnBehalfOfOtherIdentity=*)"
)

Add-AuditSection `
    "[5] RESOURCE-BASED CONSTRAINED DELEGATION" `
    $RBCD

# 6. DES-ONLY USER ACCOUNTS
$DESAccounts = @(
    Get-ADUser -Filter {
        UseDESKeyOnly -eq $true
    }
)

Add-AuditSection `
    "[6] DES-ONLY KERBEROS ACCOUNTS" `
    $DESAccounts

# 7. USER ACCOUNTS TRUSTED FOR DELEGATION
$DelegatedUsers = @(
    Get-ADUser -Filter {
        TrustedForDelegation -eq $true -or
        TrustedToAuthForDelegation -eq $true
    }
)

Add-AuditSection `
    "[7] USER ACCOUNTS TRUSTED FOR DELEGATION" `
    $DelegatedUsers

# 8. USERS PROTECTED AGAINST DELEGATION
$ProtectedUsers = @(
    Get-ADUser -Filter {
        AccountNotDelegated -eq $true
    }
)

Add-AuditSection `
    "[8] USERS MARKED AS NON-DELEGABLE" `
    $ProtectedUsers

# 9. PRIVILEGED ACCOUNT DELEGATION PROTECTION
$Administrator = Get-ADUser Administrator `
    -Properties AccountNotDelegated, Enabled

$Report.Add("`n[9] ADMINISTRATOR DELEGATION PROTECTION")
$Report.Add("Account: $($Administrator.SamAccountName)")
$Report.Add("Enabled: $($Administrator.Enabled)")
$Report.Add(
    "AccountNotDelegated: $($Administrator.AccountNotDelegated)"
)

if ($Administrator.Enabled -and
    -not $Administrator.AccountNotDelegated) {

    $Report.Add(
        "REVIEW: Administrator is not explicitly protected against delegation"
    )
}

# 10. AUDIT SUMMARY
$Report.Add("`n[10] AUDIT SUMMARY")
$Report.Add("Domain: $Domain")
$Report.Add("Preauthentication Disabled: $($PreAuthDisabled.Count)")
$Report.Add("User Accounts with SPNs: $($SPNAccounts.Count)")
$Report.Add("Unconstrained Delegation Computers: $($UnconstrainedComputers.Count)")
$Report.Add("Constrained Delegation Objects: $($ConstrainedDelegation.Count)")
$Report.Add("RBCD Objects: $($RBCD.Count)")
$Report.Add("DES-Only User Accounts: $($DESAccounts.Count)")
$Report.Add("Delegation-Trusted User Accounts: $($DelegatedUsers.Count)")
$Report.Add("Non-Delegable User Accounts: $($ProtectedUsers.Count)")
$Report.Add("Audit Mode: READ ONLY")
$Report.Add("Completed: $(Get-Date)")

# Save and display the report
$Report | Out-File -FilePath $ReportPath -Encoding UTF8
$Report
