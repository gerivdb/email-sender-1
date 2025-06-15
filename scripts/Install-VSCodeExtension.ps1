#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Installe l'extension VS Code Smart Email Sender Workspace

.DESCRIPTION
    Script pour installer et configurer l'extension VS Code personnalisée
    qui gère l'auto-start et le monitoring de l'infrastructure.

.EXAMPLE
    .\Install-VSCodeExtension.ps1
    
.EXAMPLE
    .\Install-VSCodeExtension.ps1 -Force
#>

param(
   [switch]$Force,
   [switch]$Verbose
)

$ErrorActionPreference = "Stop"

Write-Host "🔧 Installation de l'extension VS Code Smart Email Sender Workspace" -ForegroundColor Green

# Chemin de l'extension
$extensionPath = Join-Path $PSScriptRoot ".." ".vscode" "extension"
$outPath = Join-Path $extensionPath "out"

# Vérifier que l'extension est compilée
if (-not (Test-Path $outPath)) {
   Write-Host "⚠️  Extension non compilée. Compilation en cours..." -ForegroundColor Yellow
    
   Push-Location $extensionPath
   try {
      # Installer les dépendances si nécessaire
      if (-not (Test-Path "node_modules")) {
         Write-Host "📦 Installation des dépendances..." -ForegroundColor Cyan
         npm install
      }
        
      # Compiler
      Write-Host "🔨 Compilation de l'extension..." -ForegroundColor Cyan
      npm run compile
        
      if ($LASTEXITCODE -ne 0) {
         throw "Échec de la compilation de l'extension"
      }
   }
   finally {
      Pop-Location
   }
}

# Vérifier que VS Code est installé
try {
   $vscodeVersion = code --version
   Write-Host "✅ VS Code détecté : $(($vscodeVersion -split "`n")[0])" -ForegroundColor Green
}
catch {
   Write-Error "❌ VS Code n'est pas installé ou pas dans le PATH"
   exit 1
}

# Créer un package VSIX temporaire
$packageName = "smart-email-sender-workspace-1.0.0.vsix"
$packagePath = Join-Path $extensionPath $packageName

Write-Host "📦 Création du package VSIX..." -ForegroundColor Cyan

Push-Location $extensionPath
try {
   # Installer vsce si nécessaire
   if (-not (Get-Command vsce -ErrorAction SilentlyContinue)) {
      Write-Host "📦 Installation de vsce..." -ForegroundColor Cyan
      npm install -g vsce
   }
    
   # Créer le package
   if (Test-Path $packagePath) {
      Remove-Item $packagePath -Force
   }
    
   vsce package --out $packagePath
    
   if ($LASTEXITCODE -ne 0) {
      throw "Échec de la création du package VSIX"
   }
}
finally {
   Pop-Location
}

# Installer l'extension
Write-Host "🚀 Installation de l'extension..." -ForegroundColor Cyan

$installArgs = @("--install-extension", $packagePath)
if ($Force) {
   $installArgs += "--force"
}

& code @installArgs

if ($LASTEXITCODE -ne 0) {
   Write-Error "❌ Échec de l'installation de l'extension"
   exit 1
}

# Nettoyer le package temporaire
Remove-Item $packagePath -Force -ErrorAction SilentlyContinue

Write-Host "✅ Extension VS Code installée avec succès !" -ForegroundColor Green
Write-Host ""
Write-Host "🎯 L'extension sera activée automatiquement au démarrage de VS Code" -ForegroundColor Cyan
Write-Host "📋 Commandes disponibles :" -ForegroundColor Cyan
Write-Host "   • Ctrl+Shift+P > Smart Email Sender: Start Infrastructure Stack" -ForegroundColor White
Write-Host "   • Ctrl+Shift+P > Smart Email Sender: Stop Infrastructure Stack" -ForegroundColor White
Write-Host "   • Ctrl+Shift+P > Smart Email Sender: Show Infrastructure Status" -ForegroundColor White
Write-Host "   • Ctrl+Shift+P > Smart Email Sender: Enable Auto-Healing" -ForegroundColor White
Write-Host ""
Write-Host "🔄 Redémarrez VS Code pour activer l'extension" -ForegroundColor Yellow
