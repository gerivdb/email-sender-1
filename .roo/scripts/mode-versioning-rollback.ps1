# mode-versioning-rollback.ps1
# Script PowerShell Roo — Automatisation versioning, rollback et logs pour les modes Roo

param(
   [string]$ModeFile = ".roo/mode-template.md",
   [string]$LogFile = ".roo/logs/mode-actions.log",
   [string]$ReportFile = ".roo/logs/mode-rollback-report.md"
)

function Confirm-ModeChange {
   param([string]$Message)
   git add $ModeFile
   git commit -m "[Roo-Code][Mode:$ModeFile][Action:$Message][Mode:code]"
   Add-Content $LogFile "$(Get-Date -Format 's') | Confirm | $Message | $ModeFile"
}

function Restore-Mode {
   param([string]$CommitHash)
   git checkout $CommitHash -- $ModeFile
   Add-Content $LogFile "$(Get-Date -Format 's') | Restore | $CommitHash | $ModeFile"
   $report = @"
# Rapport Restore Mode Roo
- Date : $(Get-Date -Format 's')
- Fichier : $ModeFile
- Commit restauré : $CommitHash
- Utilisateur : $(whoami)
- Mode d’exécution : code
"@
   Set-Content $ReportFile $report
}

function Show-ModeHistory {
   git log --oneline -- $ModeFile
}

# Usage :
# Confirm-ModeChange "Modification du mode"
# Show-ModeHistory
# Restore-Mode "<commit_hash>"
