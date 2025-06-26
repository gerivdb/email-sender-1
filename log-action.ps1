param (
    [string]$Message
)

$LogFile = "gemini_session_log.md"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$LogEntry = @"

- **Action :** $Message
- **Date :** $Timestamp
"@

Add-Content -Path $LogFile -Value $LogEntry