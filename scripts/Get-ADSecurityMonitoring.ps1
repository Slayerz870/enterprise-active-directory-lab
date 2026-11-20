
# Get-ADSecurityMonitoring.ps1
# Milestone 149 - Active Directory Security Monitoring
# Windows Server 2025 | corp.example.test

$ReportPath = "C:\Scripts\ADSecurity-Monitoring-Report.txt"
$StartTime = (Get-Date).AddDays(-7)

$EventDefinitions = [ordered]@{
    4768 = "Kerberos Authentication Ticket Request"
    4769 = "Kerberos Service Ticket Request"
    4771 = "Kerberos Pre-Authentication Failure"
    4776 = "NTLM Credential Validation"
    4625 = "Failed Logon"
    4740 = "Account Lockout"
    4720 = "User Account Created"
    4726 = "User Account Deleted"
    4728 = "Member Added to Global Security Group"
    4732 = "Member Added to Local Security Group"
    4756 = "Member Added to Universal Security Group"
    1102 = "Security Audit Log Cleared"
}

$EventIDs = @($EventDefinitions.Keys | ForEach-Object { [int]$_ })

$Report = @(
    "ACTIVE DIRECTORY SECURITY MONITORING REPORT"
    "==========================================="
    "Domain: corp.example.test"
    "Domain Controller: $env:COMPUTERNAME"
    "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "Monitoring Period: Last 7 Days"
    ""
)

try {
    $Events = @(
        Get-WinEvent -FilterHashtable @{
            LogName   = "Security"
            ID        = $EventIDs
            StartTime = $StartTime
        } -ErrorAction Stop
    )
}
catch {
    if ($_.FullyQualifiedErrorId -like "NoMatchingEventsFound*") {
        $Events = @()
    }
    else {
        Write-Error "Unable to read Security event log: $_"
        return
    }
}

foreach ($EventID in $EventIDs) {

    $MatchingEvents = @(
        $Events | Where-Object { $_.Id -eq $EventID }
    )

    $Report += ""
    $Report += "EVENT $EventID - $($EventDefinitions[$EventID])"
    $Report += "Count: $($MatchingEvents.Count)"
    $Report += "-------------------------------------------"

    foreach ($Event in ($MatchingEvents | Sort-Object TimeCreated -Descending | Select-Object -First 10)) {
        $Report += "Time: $($Event.TimeCreated)"
        $Report += "Event ID: $($Event.Id)"
        $Report += "Details: $($Event.Message -replace '\r?\n', ' ')"
        $Report += ""
    }
}

$Report | Out-File -FilePath $ReportPath -Encoding UTF8

Write-Host "Security monitoring report generated successfully."
Write-Host "Report location: $ReportPath"
Write-Host "Total matching events: $($Events.Count)"
