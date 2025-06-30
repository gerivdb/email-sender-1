# Script PowerShell — capture_terminal.ps1
# Capture stdout/stderr d'une commande et envoie à l'API CacheManager

param(
  [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
  [string[]]$Command
)

if (-not $Command) {
  Write-Host "Usage: .\capture_terminal.ps1 <commande> [args...]"
  exit 1
}

$output = & $Command 2>&1
$status = $LASTEXITCODE

$level = "INFO"
$msg = "Commande exécutée avec succès"
if ($status -ne 0) {
  $level = "ERROR"
  $msg = "Erreur d'exécution"
}

$log = @{
  timestamp = (Get-Date -Format "o")
  level     = $level
  source    = "capture_terminal.ps1"
  message   = $msg
  context   = @{ output = $output }
}

$json = $log | ConvertTo-Json -Compress

Invoke-RestMethod -Uri "http://localhost:8080/logs" -Method Post -ContentType "application/json" -Body $json | Out-Null

Write-Output $output
exit $status
