#!/usr/bin/env pwsh
# Script de vérification des violations PowerShell restantes
# Utilisation: ./tools/check-remaining-violations.ps1

param(
   [Parameter(Mandatory = $false)]
   [switch]$Detailed
)

$ErrorActionPreference = "Stop"

Write-Host "🔍 Vérification des violations PowerShell restantes dans EMAIL_SENDER_1" -ForegroundColor Green

# Configuration des chemins
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ScriptFiles = Get-ChildItem -Path $ProjectRoot -Filter "*.ps1" -Recurse | Where-Object { $_.Name -ne $MyInvocation.MyCommand.Name }

$UnapprovedVerbs = @(
   "Apply", "Generate", "Create", "Analyze", "Process", "Execute", "Run", 
   "Build", "Make", "Configure", "Setup", "Init", "Launch", "Start", "Fire"
)

$ViolationCount = 0
$TotalFiles = 0
$FilesWithViolations = @()

Write-Host "📋 Analyse des fichiers PowerShell..." -ForegroundColor Cyan

foreach ($file in $ScriptFiles) {
   $TotalFiles++
   $content = Get-Content $file.FullName -Raw
   $fileViolations = 0
    
   # Recherche des fonctions avec verbes non approuvés
   foreach ($verb in $UnapprovedVerbs) {
      $pattern = "function\s+$verb-\w+"
      $matches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        
      if ($matches.Count -gt 0) {
         if ($fileViolations -eq 0) {
            $FilesWithViolations += $file.FullName
            Write-Host "🚨 $($file.Name):" -ForegroundColor Red
         }
            
         foreach ($match in $matches) {
            $functionName = $match.Value -replace "function\s+", ""
            Write-Host "  ❌ $functionName (verbe '$verb' non approuvé)" -ForegroundColor Yellow
            $ViolationCount++
            $fileViolations++
         }
      }
   }
    
   if ($fileViolations -eq 0) {
      Write-Host "✅ $($file.Name)" -ForegroundColor Green
   }
}

Write-Host "`n" + "="*60 -ForegroundColor Gray
Write-Host "📊 RÉSUMÉ DE L'ANALYSE" -ForegroundColor White
Write-Host "="*60 -ForegroundColor Gray
Write-Host "📁 Fichiers analysés: $TotalFiles" -ForegroundColor Cyan
Write-Host "🚨 Violations trouvées: $ViolationCount" -ForegroundColor $(if ($ViolationCount -eq 0) { 'Green' } else { 'Red' })
Write-Host "📄 Fichiers avec violations: $($FilesWithViolations.Count)" -ForegroundColor $(if ($FilesWithViolations.Count -eq 0) { 'Green' } else { 'Yellow' })

if ($ViolationCount -eq 0) {
   Write-Host "`n🎉 AUCUNE VIOLATION DÉTECTÉE! Tous les verbes PowerShell sont conformes." -ForegroundColor Green
   Write-Host "✅ Phase PowerShell Optimization RÉUSSIE" -ForegroundColor Green
}
else {
   Write-Host "`n📋 Actions recommandées:" -ForegroundColor Yellow
   Write-Host "1. Remplacer les verbes non approuvés par des verbes standards (Get, Set, New, Remove, etc.)" -ForegroundColor White
   Write-Host "2. Utiliser Get-Verb pour voir la liste des verbes approuvés" -ForegroundColor White
   Write-Host "3. Suivre les conventions PowerShell pour la compatibilité" -ForegroundColor White
}

if ($Detailed) {
   Write-Host "`n📋 VERBES APPROUVÉS RECOMMANDÉS:" -ForegroundColor Cyan
   Write-Host "Apply → Set, Install" -ForegroundColor White
   Write-Host "Generate → New" -ForegroundColor White  
   Write-Host "Create → New" -ForegroundColor White
   Write-Host "Analyze → Test, Measure" -ForegroundColor White
   Write-Host "Process → Convert, Format" -ForegroundColor White
   Write-Host "Execute → Invoke" -ForegroundColor White
   Write-Host "Build → New, Build (si Module.Build)" -ForegroundColor White
}

Write-Host "="*60 -ForegroundColor Gray