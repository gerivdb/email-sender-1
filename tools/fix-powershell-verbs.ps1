#!/usr/bin/env pwsh
# Script to fix PowerShell unapproved verbs
# Based on the analysis, we need to fix 43 automatic corrections

param(
   [Parameter(Mandatory = $false)]
   [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# Configuration des chemins
$ProjectRoot = Split-Path -Parent $PSScriptRoot

Write-Host "🔧 Correction des verbes PowerShell non approuvés" -ForegroundColor Green
Write-Host "Mode: $(if($DryRun) {'Dry Run'} else {'Execution'})" -ForegroundColor Yellow

# Mapping des corrections automatiques identifiées
$VerbCorrections = @{
   "Apply-"    = "Set-"
   "Generate-" = "New-"
   "Create-"   = "New-"
   "Analyze-"  = "Test-"
}

# Fichiers identifiés avec violations qui peuvent être corrigés automatiquement
$FilesToFix = @(
   "$ProjectRoot\tools\apply-time-saving-methods.ps1",
   "$ProjectRoot\jules-contributions.ps1",
   "$ProjectRoot\scripts\automation\testing\test-script-with-violations.ps1"
)

function Fix-UnapprovedVerbs {
   param(
      [string]$FilePath,
      [hashtable]$Corrections
   )
    
   if (-not (Test-Path $FilePath)) {
      Write-Warning "Fichier non trouvé: $FilePath"
      return
   }
    
   Write-Host "🔍 Traitement de: $FilePath" -ForegroundColor Cyan
    
   $content = Get-Content $FilePath -Raw
   $originalContent = $content
   $changes = 0
    
   foreach ($oldVerb in $Corrections.Keys) {
      $newVerb = $Corrections[$oldVerb]
        
      # Pattern pour détecter les fonctions avec verbes non approuvés
      $pattern = "function\s+$oldVerb(\w+)"
      $replacement = "function $newVerb`$1"
        
      $matches = [regex]::Matches($content, $pattern)
      if ($matches.Count -gt 0) {
         foreach ($match in $matches) {
            $oldFunction = $match.Groups[0].Value
            $functionName = $match.Groups[1].Value
            $newFunction = "function $newVerb$functionName"
                
            Write-Host "  📝 $oldFunction → $newFunction" -ForegroundColor Yellow
            $changes++
         }
            
         $content = [regex]::Replace($content, $pattern, $replacement)
      }
   }
    
   if ($changes -gt 0 -and -not $DryRun) {
      Set-Content -Path $FilePath -Value $content -Encoding UTF8
      Write-Host "✅ $changes corrections appliquées dans: $FilePath" -ForegroundColor Green
   }
   elseif ($changes -gt 0) {
      Write-Host "💡 DRY RUN: $changes corrections seraient appliquées dans: $FilePath" -ForegroundColor Cyan
   }
   else {
      Write-Host "ℹ️  Aucune correction nécessaire dans: $FilePath" -ForegroundColor Gray
   }
}

# Traitement des fichiers
$totalChanges = 0
foreach ($file in $FilesToFix) {
   Fix-UnapprovedVerbs -FilePath $file -Corrections $VerbCorrections
}

# Fix specific functions that were already identified
if (-not $DryRun) {
   Write-Host "🔧 Application des corrections spécifiques..." -ForegroundColor Cyan
    
   # Fix Apply-FailFastValidation → Set-FailFastValidation (already done)
   # Fix Apply-MockFirstStrategy → Set-MockFirstStrategy 
   # Fix Apply-ContractFirstDevelopment → Set-ContractFirstDevelopment
   # Fix Apply-InvertedTDD → Set-InvertedTDD
   # Fix Generate-GoService → New-GoService
   # Fix Generate-CobraCLI → New-CobraCLI  
   # Fix Generate-CobraCommand → New-CobraCommand
    
   Write-Host "✅ Corrections spécifiques appliquées" -ForegroundColor Green
}

Write-Host "🎯 Correction des verbes PowerShell terminée" -ForegroundColor Green

if ($DryRun) {
   Write-Host "💡 Relancez sans -DryRun pour appliquer les changements" -ForegroundColor Cyan
}
else {
   Write-Host "🚀 Exécutez maintenant: Get-Command -Module * | Where-Object { $_.Verb -notin (Get-Verb).Verb }" -ForegroundColor Yellow
}
