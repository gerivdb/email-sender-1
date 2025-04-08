# Script PowerShell pour le hook pre-commit
# Ce script est exécuté automatiquement avant chaque commit

param (
    [Parameter(Mandatory = $false)]
    [switch]$SkipOrganize,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Obtenir le chemin racine du projet
$projectRoot = git rev-parse --show-toplevel
Set-Location $projectRoot

# Fonction pour afficher un message coloré
function Write-ColorMessage {
    param (
        [string]$Message,
        [string]$ForegroundColor = "White"
    )
    
    Write-Host $Message -ForegroundColor $ForegroundColor
}

Write-ColorMessage "Exécution du hook pre-commit PowerShell..." -ForegroundColor "Cyan"

# Étape 1: Organisation des fichiers (si non désactivée)
if (-not $SkipOrganize) {
    Write-ColorMessage "Étape 1: Organisation des fichiers..." -ForegroundColor "Cyan"
    
    $organizationScript = Join-Path $projectRoot "..\..\D"
    
    if (Test-Path $organizationScript) {
        try {
            & $organizationScript
            Write-ColorMessage "Organisation des fichiers terminée" -ForegroundColor "Green"
        }
        catch {
            Write-ColorMessage "Erreur lors de l'organisation des fichiers : $_" -ForegroundColor "Red"
            if (-not $Force) {
                Write-ColorMessage "Utilisez -Force pour continuer malgré les erreurs" -ForegroundColor "Yellow"
                exit 1
            }
        }
    }
    else {
        Write-ColorMessage "Script d'organisation non trouvé : $organizationScript" -ForegroundColor "Yellow"
        Write-ColorMessage "Le commit continuera sans organisation automatique" -ForegroundColor "Yellow"
    }
}
else {
    Write-ColorMessage "Étape 1: Organisation des fichiers ignorée (option -SkipOrganize)" -ForegroundColor "Yellow"
}

# Étape 2: Vérification du style de code
Write-ColorMessage "Étape 2: Vérification du style de code..." -ForegroundColor "Cyan"

# Vérifier les fichiers PowerShell avec PSScriptAnalyzer
$psFiles = git diff --cached --name-only --diff-filter=ACM | Where-Object { $_ -match '\.ps1$' }
if ($psFiles.Count -gt 0) {
    Write-ColorMessage "Vérification de $($psFiles.Count) fichiers PowerShell..." -ForegroundColor "Cyan"
    
    $hasErrors = $false
    
    foreach ($file in $psFiles) {
        $filePath = Join-Path $projectRoot $file
        
        if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) {
            $results = Invoke-ScriptAnalyzer -Path $filePath -Severity Error
            
            if ($results.Count -gt 0) {
                Write-ColorMessage "Erreurs de style dans $file :" -ForegroundColor "Red"
                $results | ForEach-Object {
                    Write-ColorMessage "  Ligne $($_.Line): $($_.Message)" -ForegroundColor "Red"
                }
                $hasErrors = $true
            }
        }
        else {
            Write-ColorMessage "PSScriptAnalyzer non installé. Installation recommandée : Install-Module -Name PSScriptAnalyzer -Force" -ForegroundColor "Yellow"
        }
    }
    
    if ($hasErrors -and -not $Force) {
        Write-ColorMessage "Corrigez les erreurs de style avant de commiter ou utilisez -Force pour ignorer" -ForegroundColor "Red"
        exit 1
    }
}

# Vérifier les fichiers Python avec flake8
$pyFiles = git diff --cached --name-only --diff-filter=ACM | Where-Object { $_ -match '\.py$' }
if ($pyFiles.Count -gt 0) {
    Write-ColorMessage "Vérification de $($pyFiles.Count) fichiers Python..." -ForegroundColor "Cyan"
    
    if (Get-Command flake8 -ErrorAction SilentlyContinue) {
        $hasErrors = $false
        
        foreach ($file in $pyFiles) {
            $filePath = Join-Path $projectRoot $file
            $output = & flake8 $filePath
            
            if ($output) {
                Write-ColorMessage "Erreurs de style dans $file :" -ForegroundColor "Red"
                $output | ForEach-Object {
                    Write-ColorMessage "  $_" -ForegroundColor "Red"
                }
                $hasErrors = $true
            }
        }
        
        if ($hasErrors -and -not $Force) {
            Write-ColorMessage "Corrigez les erreurs de style avant de commiter ou utilisez -Force pour ignorer" -ForegroundColor "Red"
            exit 1
        }
    }
    else {
        Write-ColorMessage "flake8 non installé. Installation recommandée : pip install flake8" -ForegroundColor "Yellow"
    }
}

# Étape 3: Vérification des informations sensibles
Write-ColorMessage "Étape 3: Vérification des informations sensibles..." -ForegroundColor "Cyan"

$sensitivePatterns = @(
    "password\s*=\s*['\"][^'\"]+['\"]",
    "apikey\s*=\s*['\"][^'\"]+['\"]",
    "api_key\s*=\s*['\"][^'\"]+['\"]",
    "secret\s*=\s*['\"][^'\"]+['\"]",
    "token\s*=\s*['\"][^'\"]+['\"]",
    "-----BEGIN RSA PRIVATE KEY-----",
    "-----BEGIN PRIVATE KEY-----"
)

$allFiles = git diff --cached --name-only --diff-filter=ACM
$hasSecrets = $false

foreach ($file in $allFiles) {
    $filePath = Join-Path $projectRoot $file
    
    if (Test-Path $filePath) {
        $content = Get-Content $filePath -Raw
        
        foreach ($pattern in $sensitivePatterns) {
            if ($content -match $pattern) {
                Write-ColorMessage "Information sensible détectée dans $file : $pattern" -ForegroundColor "Red"
                $hasSecrets = $true
            }
        }
    }
}

if ($hasSecrets -and -not $Force) {
    Write-ColorMessage "Retirez les informations sensibles avant de commiter ou utilisez -Force pour ignorer" -ForegroundColor "Red"
    exit 1
}

# Étape 4: Ajouter les fichiers déplacés au commit
Write-ColorMessage "Étape 4: Ajout des fichiers déplacés au commit..." -ForegroundColor "Cyan"

git add .

Write-ColorMessage "Hook pre-commit exécuté avec succès" -ForegroundColor "Green"
exit 0

