# move-files.ps1
# Auteur : Roo (IA)
# Version : 1.0
# Date : 2025-08-01
# Description : Script PowerShell multiplateforme pour déplacer des fichiers selon une configuration YAML, avec support dry-run, log, rollback, audit.
# Usage : .\move-files.ps1 [-Config 'file-moves.yaml'] [-DryRun] [-Rollback] [-Log 'move-files.log']

param(
   [string]$Config = "file-moves.yaml",
   [switch]$DryRun,
   [switch]$Rollback,
   [string]$Log = "move-files.log"
)

function Write-Log($msg) {
   $entry = "$(Get-Date -Format o) $msg"
   Add-Content -Path $Log -Value $entry
   Write-Output $entry
}

function Get-Yaml($path) {
   # Nécessite powershell-yaml (Install-Module powershell-yaml) ou conversion manuelle
   if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
      Write-Log "ERREUR : powershell-yaml non installé. Installez-le ou convertissez le YAML en JSON."
      exit 1
   }
   Import-Module powershell-yaml
   return ConvertFrom-Yaml (Get-Content $path -Raw)
}

function Test-Schema($yaml) {
   # Validation manuelle minimale (pour schéma avancé, utiliser un validateur externe)
   if (-not $yaml.moves) {
      Write-Log "ERREUR : Section 'moves' manquante dans la config."
      exit 1
   }
}

function Invoke-Move($src, $dst) {
   Write-Log "[LOG] Invoke-Move appelé avec src='$src' dst='$dst'"
   if ($DryRun) {
      Write-Log "DRY-RUN : $src => $dst"
   }
   else {
      if (Test-Path $src) {
         Move-Item -Path $src -Destination $dst -Force
         Write-Log "MOVE : $src => $dst"
      }
      else {
         Write-Log "ERREUR : Source introuvable $src"
      }
   }
}

function Invoke-Rollback($logPath) {
   Write-Log "[LOG] Invoke-Rollback appelé avec logPath='$logPath'"
   $lines = Get-Content $logPath | Select-String "MOVE :"
   foreach ($line in $lines) {
      if ($line -match "MOVE : (.+) => (.+)$") {
         $src = $Matches[2]
         $dst = $Matches[1]
         if (Test-Path $src) {
            Move-Item -Path $src -Destination $dst -Force
            Write-Log "ROLLBACK : $src => $dst"
         }
      }
   }
}

Write-Log "=== Début du script move-files.ps1 ==="
if ($Rollback) {
   Invoke-Rollback $Log
   Write-Log "Rollback terminé."
   exit 0
}

$yaml = Load-Yaml $Config
Validate-Schema $yaml

foreach ($move in $yaml.moves) {
   Do-Move $move.source $move.destination
}

Write-Log "=== Fin du script move-files.ps1 ==="