# ============================================
# Active Directory Privileged Access Audit
# Milestone 145 | Read-Only Security Assessment
# ============================================

Import-Module ActiveDirectory -ErrorAction Stop

$Domain = (Get-ADDomain).DNSRoot
$ReportPath = "C:\Scripts\ADPrivilegedAccess-Report.txt"
$Cutoff = (Get-Date).AddDays(-90)

$Groups = @(
    "Domain Admins",
    "Enterprise Admins",
    "Schema Admins",
    "Administrators",
    "Account Operators",
    "Backup Operators",
    "Server Operators",
    "Print Operators",
    "Protected Users"
)

$Report = [System.Collections.Generic.List[string]]::new()
$PrivilegedUsers = @{}

$Report.Add("========================================")
$Report.Add(" ACTIVE DIRECTORY PRIVILEGED ACCESS AUDIT")
$Report.Add(" Domain: $Domain")
$Report.Add(" Date: $(Get-Date)")
$Report.Add("========================================")

# 1. PRIVILEGED GROUP MEMBERSHIP
$Report.Add("`n[1] PRIVILEGED GROUP MEMBERSHIP")

foreach ($Group in $Groups) {
    $Report.Add("`nGROUP: $Group")

    try {
        $Members = @(Get-ADGroupMember -Identity $Group -Recursive -ErrorAction Stop)

        if ($Members.Count -eq 0) {
            $Report.Add("Members: 0")
            continue
        }

        foreach ($Member in $Members) {
            $Report.Add(
                "Member: $($Member.Name) | Type: $($Member.ObjectClass)"
            )

            if ($Member.ObjectClass -eq "user") {
                $PrivilegedUsers[$Member.DistinguishedName] = $Member
            }
        }
    }
    catch {
        $Report.Add("ERROR: $($_.Exception.Message)")
    }
}

# 2. PRIVILEGED ACCOUNT SECURITY
$Report.Add("`n[2] PRIVILEGED ACCOUNT SECURITY")

foreach ($DN in $PrivilegedUsers.Keys) {
    try {
        $User = Get-ADUser -Identity $DN -Properties `
            Enabled, PasswordNeverExpires, PasswordLastSet, `
            LastLogonDate, AdminCount -ErrorAction Stop

        $Inactive90Days = (
            !$User.LastLogonDate -or
            $User.LastLogonDate -lt $Cutoff
        )

        $Report.Add("`nAccount: $($User.SamAccountName)")
        $Report.Add("Enabled: $($User.Enabled)")
        $Report.Add("Password Never Expires: $($User.PasswordNeverExpires)")
        $Report.Add("Password Last Set: $($User.PasswordLastSet)")
        $Report.Add("Last Logon Date: $($User.LastLogonDate)")
        $Report.Add("Inactive 90 Days: $Inactive90Days")
        $Report.Add("AdminCount: $($User.AdminCount)")

        if ($User.Enabled -and $User.PasswordNeverExpires) {
            $Report.Add(
                "REVIEW: Enabled privileged account has a non-expiring password"
            )
        }

        if ($User.Enabled -and $Inactive90Days) {
            $Report.Add(
                "REVIEW: Enabled privileged account may be inactive"
            )
        }
    }
    catch {
        $Report.Add("ERROR: $($_.Exception.Message)")
    }
}

# 3. AUDIT SUMMARY
$Report.Add("`n[3] AUDIT SUMMARY")
$Report.Add("Privileged Groups Checked: $($Groups.Count)")
$Report.Add("Unique Privileged Users Found: $($PrivilegedUsers.Count)")
$Report.Add("Inactive Threshold: 90 Days")
$Report.Add("Audit Mode: READ ONLY")
$Report.Add("Completed: $(Get-Date)")

# Save and display report
$Report | Out-File -FilePath $ReportPath -Encoding UTF8
$Report
