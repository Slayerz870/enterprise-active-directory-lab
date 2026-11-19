#Requires -Modules ActiveDirectory
<#
.SYNOPSIS
    Enterprise Active Directory Kerberos Security Audit
.DESCRIPTION
    Read-only audit of Kerberos policy, KRBTGT account,
    encryption support, audit configuration, and security events.
#>

$ErrorActionPreference = "Stop"

$ReportPath = "C:\Scripts\ADKerberos-Report.txt"
$Domain = Get-ADDomain
$DC = $env:COMPUTERNAME
$Now = Get-Date

$Report = [System.Collections.Generic.List[string]]::new()

function Add-Report {
    param([string]$Text = "")
    $Report.Add($Text)
}

function Get-KerberosEncryption {
    param([string]$Type)

    switch ($Type) {
        "0x11" { "AES128" }
        "0x12" { "AES256" }
        "0x17" { "RC4-HMAC" }
        "0x1"  { "DES-CBC-CRC" }
        "0x3"  { "DES-CBC-MD5" }
        default { "Unknown ($Type)" }
    }
}

Add-Report "=========================================="
Add-Report " ENTERPRISE ACTIVE DIRECTORY KERBEROS AUDIT"
Add-Report "=========================================="
Add-Report "Date: $Now"
Add-Report "Domain: $($Domain.DNSRoot)"
Add-Report "Domain Controller: $DC"
Add-Report ""

# KRBTGT account audit
Add-Report "[1] KRBTGT ACCOUNT"

$Krbtgt = Get-ADUser krbtgt -Properties PasswordLastSet,Enabled,PasswordNeverExpires

Add-Report "Enabled: $($Krbtgt.Enabled)"
Add-Report "Password Last Set: $($Krbtgt.PasswordLastSet)"
Add-Report "Password Never Expires: $($Krbtgt.PasswordNeverExpires)"

if ($Krbtgt.PasswordLastSet) {
    $PasswordAge = ((Get-Date) - $Krbtgt.PasswordLastSet).Days
    Add-Report "Password Age: $PasswordAge days"
}

Add-Report ""

# Kerberos encryption configuration
Add-Report "[2] DOMAIN CONTROLLER ENCRYPTION"

$DCComputer = Get-ADComputer $DC -Properties msDS-SupportedEncryptionTypes
$EncryptionValue = $DCComputer.'msDS-SupportedEncryptionTypes'

Add-Report "Supported Encryption Bitmask: $EncryptionValue"

if ($null -ne $EncryptionValue) {
    Add-Report "RC4 Advertised: $([bool]($EncryptionValue -band 4))"
    Add-Report "AES128 Advertised: $([bool]($EncryptionValue -band 8))"
    Add-Report "AES256 Advertised: $([bool]($EncryptionValue -band 16))"
} else {
    Add-Report "Encryption attribute not explicitly configured."
}

Add-Report ""

# Kerberos auditing configuration
Add-Report "[3] KERBEROS AUDIT POLICY"

$AuditPolicy = auditpol /get /subcategory:"Kerberos Authentication Service","Kerberos Service Ticket Operations"

foreach ($Line in $AuditPolicy) {
    Add-Report $Line
}

Add-Report ""

# Kerberos security event audit
Add-Report "[4] KERBEROS SECURITY EVENTS"
Add-Report "Review Period: Last 7 Days"

$StartTime = (Get-Date).AddDays(-7)

foreach ($EventID in @(4768,4769,4771)) {

    $Events = @(
        Get-WinEvent -FilterHashtable @{
            LogName = "Security"
            Id = $EventID
            StartTime = $StartTime
        } -ErrorAction SilentlyContinue
    )

    Add-Report ""
    Add-Report "Event ID: $EventID"
    Add-Report "Total Events: $($Events.Count)"

    $EncryptionSummary = @{}

    foreach ($Event in $Events) {

        [xml]$Xml = $Event.ToXml()
        $Data = @{}

        foreach ($Item in $Xml.Event.EventData.Data) {
            $Data[$Item.Name] = $Item.'#text'
        }

        $Type = $Data["TicketEncryptionType"]

        if ($Type) {
            $Name = Get-KerberosEncryption $Type

            if (-not $EncryptionSummary.ContainsKey($Name)) {
                $EncryptionSummary[$Name] = 0
            }

            $EncryptionSummary[$Name]++
        }
    }

    foreach ($Key in ($EncryptionSummary.Keys | Sort-Object)) {
        Add-Report "Encryption $Key : $($EncryptionSummary[$Key])"
    }
}

Add-Report ""
Add-Report "[5] SECURITY OBSERVATIONS"

if ($null -ne $EncryptionValue -and ($EncryptionValue -band 4)) {
    Add-Report "REVIEW: Domain controller advertises legacy RC4 compatibility."
}

Add-Report "INFO: Encryption support does not prove encryption usage."
Add-Report "INFO: Review Event IDs 4768 and 4769 for actual ticket encryption."
Add-Report "INFO: Event 4771 records Kerberos pre-authentication failures."
Add-Report "INFO: Audit results reflect available local Security log history."
Add-Report "INFO: This script does not modify Active Directory."

Add-Report ""
Add-Report "=========================================="
Add-Report " END OF KERBEROS SECURITY AUDIT"
Add-Report "=========================================="

$Report | Out-File -FilePath $ReportPath -Encoding UTF8

Write-Host ""
Write-Host "Kerberos security audit completed." -ForegroundColor Green
Write-Host "Report saved to: $ReportPath" -ForegroundColor Cyan
