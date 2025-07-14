# Script PowerShell pour automatiser l’audit initial Go (gapanalyzer)
param (
   [string]$InputFile = "modules.json",
   [string]$OutputFile = "gap-analysis.json",
   [string]$MarkdownFile = "gap-analysis.md",
   [string]$LogFile = "audit-log.txt"
)

Write-Host "🟢 Démarrage de l’audit Go avec gapanalyzer..."

# Exécution du binaire Go
go run cmd/gapanalyzer/gapanalyzer.go --input $InputFile --output $OutputFile --markdown $MarkdownFile | Tee-Object -FilePath $LogFile

# Vérification des livrables
if (!(Test-Path $OutputFile)) { Write-Error "Rapport JSON non généré." }
if (!(Test-Path $MarkdownFile)) { Write-Warning "Rapport Markdown non généré." }
if (!(Test-Path $LogFile)) { Write-Warning "Log d’audit non généré." }

# Archivage des livrables
$archiveDir = "_templates/backup/plan-dev/new/"
if (!(Test-Path $archiveDir)) { New-Item -ItemType Directory -Path $archiveDir }
Copy-Item $OutputFile -Destination $archiveDir -Force
Copy-Item $MarkdownFile -Destination $archiveDir -Force
Copy-Item $LogFile -Destination $archiveDir -Force

Write-Host "✅ Audit Go terminé. Rapports et logs archivés dans $archiveDir."