Import-Module GroupPolicy -ErrorAction Stop
Import-Module ActiveDirectory -ErrorAction Stop

# ============================================
# Active Directory Group Policy Security Audit
# Domain: Automatically detected
# Purpose: Read-only GPO security assessment
# ============================================

$Domain = (Get-ADDomain).DNSRoot
$ReportPath = "C:\Scripts\ADGPOAudit-Report.txt"

$Report = @()
$Report += "========================================"
$Report += " ACTIVE DIRECTORY GPO SECURITY AUDIT"
$Report += " Domain: $Domain"
$Report += " Date: $(Get-Date)"
$Report += "========================================"

$GPOs = @(Get-GPO -All)

# 1. GPO INVENTORY
$Report += "`n[1] GROUP POLICY INVENTORY"

foreach ($GPO in $GPOs) {
    $Report += "Name: $($GPO.DisplayName)"
    $Report += "Status: $($GPO.GpoStatus)"
    $Report += "Modified: $($GPO.ModificationTime)"
    $Report += "----------------------------------------"
}

# 2. GPO LINKS
$Report += "`n[2] GROUP POLICY LINKS"

foreach ($GPO in $GPOs) {
    $Xml = [xml](Get-GPOReport -Guid $GPO.Id -ReportType Xml)
    $Links = @($Xml.GPO.LinksTo | Where-Object { $null -ne $_ })

    $Report += "GPO: $($GPO.DisplayName)"

    if ($Links.Count -eq 0) {
        $Report += "WARNING: No GPO links found"
    }
    else {
        foreach ($Link in $Links) {
            $Report += "Linked To: $($Link.SOMPath)"
            $Report += "Enabled: $($Link.Enabled)"
            $Report += "Enforced: $($Link.NoOverride)"
        }
    }

    $Report += "----------------------------------------"
}

# 3. GPO PERMISSIONS
$Report += "`n[3] GROUP POLICY PERMISSIONS"

foreach ($GPO in $GPOs) {
    $Report += "GPO: $($GPO.DisplayName)"

    $Permissions = Get-GPPermission -Guid $GPO.Id -All

    foreach ($Entry in $Permissions) {
        $Report += "Trustee: $($Entry.Trustee.Name)"
        $Report += "Permission: $($Entry.Permission)"
        $Report += "Inherited: $($Entry.Inherited)"
        $Report += "----------------------------------------"
    }
}

# 4. CUSTOM PERMISSIONS
$Report += "`n[4] CUSTOM GPO PERMISSIONS"

foreach ($GPO in $GPOs) {
    $Custom = @(Get-GPPermission -Guid $GPO.Id -All |
        Where-Object { $_.Permission -eq 'GpoCustom' })

    foreach ($Entry in $Custom) {
        $Report += "REVIEW: $($GPO.DisplayName)"
        $Report += "Trustee: $($Entry.Trustee.Name)"
        $Report += "Permission: GpoCustom"
        $Report += "----------------------------------------"
    }
}

# 5. DISABLED GPO SETTINGS
$Report += "`n[5] DISABLED GPO SETTINGS"

foreach ($GPO in $GPOs) {
    if ($GPO.GpoStatus -ne 'AllSettingsEnabled') {
        $Report += "REVIEW: $($GPO.DisplayName)"
        $Report += "Status: $($GPO.GpoStatus)"
    }
}

# 6. SUMMARY
$Report += "`n[6] AUDIT SUMMARY"
$Report += "Total GPOs: $($GPOs.Count)"
$Report += "Audit Completed: $(Get-Date)"
$Report += "Mode: READ ONLY"

$Report | Out-File -FilePath $ReportPath -Encoding UTF8
$Report
