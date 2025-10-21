# ==========================================
# Export DailyServerReport to CSV and Email
# Overwrites existing CSV each run
# ==========================================

# Load SQL Server module if not already loaded
#Import-Module SqlServer -ErrorAction SilentlyContinue

# Connection details
$Server = "DEV-SQL3"
$Database = "DBA_Inventory"
$OutputFile = "C:\SQLJobs\DailyServerReport.csv"  # Always overwritten

# Columns to include
$Columns = @(
    'ReportID','ReportDate','TotalDevJobs','TotalDevTables','TotalDevDB',
    'TotalDevDbSize','TotalDevServers','ChangeDevJobs','ChangeDevTables',
    'ChangeDevDB','ChangeDevDbSize','ChangeDevServers'
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

    # Email parameters
    $ConfigPath = "C:\SQLJobs\ReportConfig.json"
$Config = Get-Content $ConfigPath | ConvertFrom-Json

    $From = $Config.From
    $To = $Config.To
    $Subject = "Monthly SQL Server Report - $Server"
    $SMTP = $Config.SMTP

    # Send email with HTML preview + CSV
    Send-MailMessage -From $From -To $To -Subject $Subject `
        -Body $StyledBody -BodyAsHtml `
        -SmtpServer $SMTP -Attachments $OutputFile

    Write-Host "CSV exported and email sent successfully."

} catch {
    Write-Host "? Error exporting or sending report: $_"
}
