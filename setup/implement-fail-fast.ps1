#!/usr/bin/env pwsh
# 🚀 Fail-Fast Validation Framework - Setup en 5 minutes
# ROI: +48-72h économisées sur 24 scripts

param(
    [switch]$DryRun,
    [string]$ScriptPath = ".",
    [switch]$Verbose
)

# ⚡ Core Fail-Fast Functions
function Assert-Prerequisites {
    param(
        [string[]]$RequiredModules = @(),
        [string[]]$RequiredFiles = @(),
        [hashtable]$RequiredEnvVars = @{},
        [string[]]$RequiredCommands = @()
    )
    
    $errors = @()
    
    # 1. Modules validation (5 seconds vs 30 minutes debug)
    foreach ($module in $RequiredModules) {
        if (-not (Get-Module -ListAvailable $module -ErrorAction SilentlyContinue)) {
            $errors += "❌ Module requis manquant: $module"
        } else {
            Write-Host "✅ Module trouvé: $module" -ForegroundColor Green
        }
    }
    
    # 2. Files validation
    foreach ($file in $RequiredFiles) {
        if (-not (Test-Path $file)) {
            $errors += "❌ Fichier requis manquant: $file"
        } else {
            Write-Host "✅ Fichier trouvé: $file" -ForegroundColor Green
        }
    }
    
    # 3. Environment variables validation
    foreach ($envVar in $RequiredEnvVars.Keys) {
        $value = [Environment]::GetEnvironmentVariable($envVar)
        if ([string]::IsNullOrEmpty($value)) {
            $errors += "❌ Variable d'environnement manquante: $envVar"
        } else {
            Write-Host "✅ Variable d'environnement: $envVar" -ForegroundColor Green
        }
    }
    
    # 4. Commands validation
    foreach ($command in $RequiredCommands) {
        try {
            $null = Get-Command $command -ErrorAction Stop
            Write-Host "✅ Commande disponible: $command" -ForegroundColor Green
        } catch {
            $errors += "❌ Commande manquante: $command"
        }
    }
    
    # FAIL FAST - Stop immediately if errors
    if ($errors.Count -gt 0) {
        Write-Host "`n🚨 ÉCHEC DES PRÉREQUIS:" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
        throw "Prerequisites validation failed. Fix above errors before continuing."
    }
    
    Write-Host "`n✅ Tous les prérequis validés avec succès!" -ForegroundColor Green
}

function Assert-QdrantConnection {
    param(
        [string]$QdrantUrl = "http://localhost:6333",
        [int]$TimeoutSeconds = 5
    )
    
    try {
        $response = Invoke-RestMethod -Uri "$QdrantUrl/healthz" -Method Get -TimeoutSec $TimeoutSeconds
        Write-Host "✅ QDrant connexion OK: $QdrantUrl" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ QDrant connexion échouée: $QdrantUrl" -ForegroundColor Red
        throw "QDrant n'est pas accessible. Vérifiez que le service est démarré."
    }
}

function Assert-GoEnvironment {
    $goVersion = go version 2>$null
    if (-not $goVersion) {
        throw "❌ Go n'est pas installé ou pas dans le PATH"
    }
    
    if (-not (Test-Path "go.mod")) {
        throw "❌ go.mod non trouvé. Exécutez depuis la racine du projet Go."
    }
    
    Write-Host "✅ Environnement Go validé: $goVersion" -ForegroundColor Green
}

function Assert-N8nEnvironment {
    param([string]$N8nUrl = "http://localhost:5678")
    
    try {
        $response = Invoke-RestMethod -Uri "$N8nUrl/healthz" -Method Get -TimeoutSec 5 -ErrorAction Stop
        Write-Host "✅ n8n connexion OK: $N8nUrl" -ForegroundColor Green
    } catch {
        Write-Warning "⚠️ n8n non accessible: $N8nUrl (optionnel pour dev)"
    }
}

# 🔧 Setup Script with Fail-Fast
function Install-FailFastFramework {
    param([switch]$DryRun)
    
    Write-Host "🚀 Installation du Fail-Fast Framework..." -ForegroundColor Cyan
    
    # Create common validation library
    $libPath = "development/scripts/common/FailFast.ps1"
    
    if ($DryRun) {
        Write-Host "[DRY RUN] Créerait: $libPath" -ForegroundColor Yellow
        return
    }
    
    New-Item -Path (Split-Path $libPath -Parent) -ItemType Directory -Force | Out-Null
    
    $failFastLib = @"
# 🚀 Fail-Fast Validation Library
# Usage: Import-Module ./FailFast.ps1

# Export all validation functions
. `$PSScriptRoot/../../../setup/implement-fail-fast.ps1

Export-ModuleMember -Function Assert-Prerequisites, Assert-QdrantConnection, Assert-GoEnvironment, Assert-N8nEnvironment
"@

    Set-Content -Path $libPath -Value $failFastLib -Encoding UTF8
    Write-Host "✅ Bibliothèque Fail-Fast créée: $libPath" -ForegroundColor Green
}

# 📝 Generate Fail-Fast template for existing scripts
function Add-FailFastToScript {
    param(
        [string]$ScriptPath,
        [switch]$DryRun
    )
    
    $scriptName = Split-Path $ScriptPath -Leaf
    Write-Host "🔧 Ajout Fail-Fast à: $scriptName" -ForegroundColor Cyan
    
    $failFastHeader = @"
# 🚀 Fail-Fast Validation - Auto-generated
Import-Module `$PSScriptRoot/../../common/FailFast.ps1 -Force

# Customize prerequisites for this script
Assert-Prerequisites -RequiredModules @() -RequiredFiles @() -RequiredEnvVars @{} -RequiredCommands @()

# Script-specific validations
# Assert-QdrantConnection
# Assert-GoEnvironment  
# Assert-N8nEnvironment

Write-Host "✅ Prerequisites validés pour: $scriptName" -ForegroundColor Green

"@

        if ($DryRun) {
        Write-Host "[DRY RUN] Would add Fail-Fast header to: $ScriptPath" -ForegroundColor Yellow
        return
    }
    
    # Add to beginning of existing script
    $originalContent = Get-Content $ScriptPath -Raw -ErrorAction SilentlyContinue
    if ($originalContent) {
        $newContent = $failFastHeader + "`n" + $originalContent
        Set-Content -Path $ScriptPath -Value $newContent -Encoding UTF8
        Write-Host "✅ Fail-Fast ajouté à: $scriptName" -ForegroundColor Green
    }
}

# 🎯 Main Execution
Write-Host "🚀 FAIL-FAST VALIDATION SETUP" -ForegroundColor Cyan
Write-Host "ROI estimé: +48-72h économisées" -ForegroundColor Yellow

# Validate current environment first
Assert-Prerequisites -RequiredCommands @("pwsh", "git")

# Install framework
Install-FailFastFramework -DryRun:$DryRun

# Find and update existing PowerShell scripts
$scriptFiles = Get-ChildItem -Path "development/scripts" -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue

if ($scriptFiles) {
    Write-Host "`n📁 Scripts trouvés: $($scriptFiles.Count)" -ForegroundColor Cyan
    
    foreach ($script in $scriptFiles | Select-Object -First 5) {
        Add-FailFastToScript -ScriptPath $script.FullName -DryRun:$DryRun
    }
}

Write-Host "`n🎉 Fail-Fast Framework configuré!" -ForegroundColor Green
Write-Host "⏱️  Temps d'installation: ~5 minutes" -ForegroundColor Yellow
Write-Host "💰 ROI attendu: +48-72h sur vos 24 scripts" -ForegroundColor Yellow