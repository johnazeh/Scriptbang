# ==========================================
# Export DailyServerReport to CSV and Email via Internal SMTP Relay
# Overwrites existing CSV each run
# ==========================================

# Connection details
$Server = "DEV-SQL3"
$Database = "DBA_Inventory"
$OutputFile = "C:\SQLJobs\DailyServerReport.csv"  # Always overwritten

# Columns to include
$Columns = @(
    'ReportID','ReportDate','TotalDevJobs','TotalDevTables','TotalDevDB',
    'TotalDevDbSize','TotalDevServers','TotalDevDiskSize','ChangeDevJobs','ChangeDevTables',
    'ChangeDevDB','ChangeDevDbSize','ChangeDevServers','ChangeDevDisksize'
)

try {
    Write-Host "Exporting DailyServerReport from $Server..."

    # Fetch full data (for CSV)
    $FullData = Invoke-Sqlcmd -ServerInstance $Server -Database $Database -Query "
        SELECT * 
        FROM dbo.DailyServerReport
        ORDER BY ReportDate DESC
    " -TrustServerCertificate

    # Export only selected columns to CSV (overwrite)
    $FullData | Select-Object $Columns |
        Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8 -Force

    # Fetch top 10 rows for HTML preview
    $PreviewData = $FullData | Select-Object $Columns | Select-Object -First 10

    # Convert to HTML table
    $HtmlTable = $PreviewData | ConvertTo-Html -Fragment | Out-String

    # Add CSS styling for Outlook
    $StyledBody = @"
<html>
<head>
<style>
table {
    border-collapse: collapse;
    width: 100%;
    font-family: Arial;
    font-size: 12px;
}
th, td {
    border: 1px solid #ddd;
    padding: 6px;
    text-align: left;
}
th {
    background-color: #0078D7;
    color: white;
}
</style>
</head>
<body>
<h3>Monthly SQL Server Report for $Server</h3>
<p>Attached is the full CSV report. Here's a quick preview:</p>
$HtmlTable
<p>-- SQL Automation</p>
</body>
</html>
"@

    # Email parameters (Internal Relay with PSCredential)
    $ConfigPath = "C:\SQLJobs\ReportConfig.json"
    $Config = Get-Content $ConfigPath | ConvertFrom-Json

    $From = "no-reply@trupanion.com"
    $To = $Config.To
    $Subject = "Monthly SQL Server Report - $Server"
    $SMTP = "mail.trupanion.com"  # <- Internal SMTP relay
    $Port = 25                     # <- Standard internal relay port

    # Create anonymous PSCredential object
    $anonUsername = "anonymous"
    $anonPassword = ConvertTo-SecureString -String "anonymous" -AsPlainText -Force
    $anonCredentials = New-Object System.Management.Automation.PSCredential($anonUsername, $anonPassword)

    # Send email with HTML preview + CSV via internal relay
    Send-MailMessage -From $From -To $To -Subject $Subject `
        -Body $StyledBody -BodyAsHtml `
        -SmtpServer $SMTP -Port $Port `
        -Credential $anonCredentials `
        -Attachments $OutputFile

    Write-Host "CSV exported and email sent successfully via internal relay (anonymous credentials)."

} catch {
    Write-Host "? Error exporting or sending report: $_"
}
