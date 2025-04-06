# Script pour exécuter les vérifications CI/CD
# Ce script est conçu pour être exécuté dans un environnement CI/CD

param (
    [Parameter(Mandatory = $false)]
    [switch]$SkipTests,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipLint,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipSecurity,
    
    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

# Obtenir le chemin racine du projet
$projectRoot = $PSScriptRoot
if ($PSScriptRoot -match "scripts\\ci$") {
    $projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
}
else {
    $projectRoot = git rev-parse --show-toplevel
}
Set-Location $projectRoot

# Fonction pour afficher un message coloré
function Write-ColorMessage {
    param (
        [string]$Message,
        [string]$ForegroundColor = "White"
    )
    
    Write-Host $Message -ForegroundColor $ForegroundColor
}

# Fonction pour afficher un message verbose
function Write-VerboseMessage {
    param (
        [string]$Message
    )
    
    if ($Verbose) {
        Write-ColorMessage $Message -ForegroundColor "Gray"
    }
}

Write-ColorMessage "Exécution des vérifications CI/CD..." -ForegroundColor "Cyan"

$allPassed = $true

# Étape 1: Vérification du style de code
if (-not $SkipLint) {
    Write-ColorMessage "Étape 1: Vérification du style de code..." -ForegroundColor "Cyan"
    
    # Vérifier les fichiers PowerShell avec PSScriptAnalyzer
    $psFiles = Get-ChildItem -Path $projectRoot -Recurse -Include "*.ps1" -File
    if ($psFiles.Count -gt 0) {
        Write-ColorMessage "Vérification de $($psFiles.Count) fichiers PowerShell..." -ForegroundColor "Cyan"
        
        $hasErrors = $false
        
        if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) {
            foreach ($file in $psFiles) {
                Write-VerboseMessage "Vérification de $($file.Name)..."
                $results = Invoke-ScriptAnalyzer -Path $file.FullName -Severity Error
                
                if ($results.Count -gt 0) {
                    Write-ColorMessage "Erreurs de style dans $($file.Name) :" -ForegroundColor "Red"
                    $results | ForEach-Object {
                        Write-ColorMessage "  Ligne $($_.Line): $($_.Message)" -ForegroundColor "Red"
                    }
                    $hasErrors = $true
                }
            }
            
            if ($hasErrors) {
                Write-ColorMessage "Des erreurs de style ont été détectées dans les fichiers PowerShell" -ForegroundColor "Red"
                $allPassed = $false
            }
            else {
                Write-ColorMessage "Aucune erreur de style détectée dans les fichiers PowerShell" -ForegroundColor "Green"
            }
        }
        else {
            Write-ColorMessage "PSScriptAnalyzer non installé. Installation recommandée : Install-Module -Name PSScriptAnalyzer -Force" -ForegroundColor "Yellow"
        }
    }
    
    # Vérifier les fichiers Python avec flake8
    $pyFiles = Get-ChildItem -Path $projectRoot -Recurse -Include "*.py" -File
    if ($pyFiles.Count -gt 0) {
        Write-ColorMessage "Vérification de $($pyFiles.Count) fichiers Python..." -ForegroundColor "Cyan"
        
        $hasErrors = $false
        
        if (Get-Command flake8 -ErrorAction SilentlyContinue) {
            foreach ($file in $pyFiles) {
                Write-VerboseMessage "Vérification de $($file.Name)..."
                $output = & flake8 $file.FullName
                
                if ($output) {
                    Write-ColorMessage "Erreurs de style dans $($file.Name) :" -ForegroundColor "Red"
                    $output | ForEach-Object {
                        Write-ColorMessage "  $_" -ForegroundColor "Red"
                    }
                    $hasErrors = $true
                }
            }
            
            if ($hasErrors) {
                Write-ColorMessage "Des erreurs de style ont été détectées dans les fichiers Python" -ForegroundColor "Red"
                $allPassed = $false
            }
            else {
                Write-ColorMessage "Aucune erreur de style détectée dans les fichiers Python" -ForegroundColor "Green"
            }
        }
        else {
            Write-ColorMessage "flake8 non installé. Installation recommandée : pip install flake8" -ForegroundColor "Yellow"
        }
    }
}
else {
    Write-ColorMessage "Étape 1: Vérification du style de code ignorée (option -SkipLint)" -ForegroundColor "Yellow"
}

# Étape 2: Exécution des tests unitaires
if (-not $SkipTests) {
    Write-ColorMessage "Étape 2: Exécution des tests unitaires..." -ForegroundColor "Cyan"
    
    # Vérifier s'il y a des tests à exécuter
    $testFiles = Get-ChildItem -Path $projectRoot -Recurse -Include "*test*.py", "*Test*.ps1" -File
    
    if ($testFiles.Count -eq 0) {
        Write-ColorMessage "Aucun fichier de test trouvé" -ForegroundColor "Yellow"
    }
    else {
        # Exécuter les tests Python
        $pythonTestFiles = $testFiles | Where-Object { $_.Extension -eq ".py" }
        if ($pythonTestFiles.Count -gt 0) {
            Write-ColorMessage "Exécution des tests Python..." -ForegroundColor "Cyan"
            
            $testResult = $true
            
            if (Get-Command pytest -ErrorAction SilentlyContinue) {
                foreach ($testFile in $pythonTestFiles) {
                    Write-ColorMessage "  Exécution de $($testFile.Name)..." -ForegroundColor "Cyan"
                    $output = & pytest $testFile.FullName -v
                    
                    if ($LASTEXITCODE -ne 0) {
                        Write-ColorMessage "  Échec des tests dans $($testFile.Name)" -ForegroundColor "Red"
                        $output | ForEach-Object {
                            Write-ColorMessage "    $_" -ForegroundColor "Red"
                        }
                        $testResult = $false
                    }
                    else {
                        Write-ColorMessage "  Tests réussis dans $($testFile.Name)" -ForegroundColor "Green"
                    }
                }
                
                if (-not $testResult) {
                    Write-ColorMessage "Des tests Python ont échoué" -ForegroundColor "Red"
                    $allPassed = $false
                }
            }
            else {
                Write-ColorMessage "pytest non installé. Installation recommandée : pip install pytest" -ForegroundColor "Yellow"
            }
        }
        
        # Exécuter les tests PowerShell
        $powershellTestFiles = $testFiles | Where-Object { $_.Extension -eq ".ps1" }
        if ($powershellTestFiles.Count -gt 0) {
            Write-ColorMessage "Exécution des tests PowerShell..." -ForegroundColor "Cyan"
            
            $testResult = $true
            
            if (Get-Command Invoke-Pester -ErrorAction SilentlyContinue) {
                foreach ($testFile in $powershellTestFiles) {
                    Write-ColorMessage "  Exécution de $($testFile.Name)..." -ForegroundColor "Cyan"
                    $results = Invoke-Pester -Path $testFile.FullName -PassThru
                    
                    if ($results.FailedCount -gt 0) {
                        Write-ColorMessage "  Échec des tests dans $($testFile.Name): $($results.FailedCount) test(s) échoué(s)" -ForegroundColor "Red"
                        $testResult = $false
                    }
                    else {
                        Write-ColorMessage "  Tests réussis dans $($testFile.Name): $($results.PassedCount) test(s) réussi(s)" -ForegroundColor "Green"
                    }
                }
                
                if (-not $testResult) {
                    Write-ColorMessage "Des tests PowerShell ont échoué" -ForegroundColor "Red"
                    $allPassed = $false
                }
            }
            else {
                Write-ColorMessage "Pester non installé. Installation recommandée : Install-Module -Name Pester -Force" -ForegroundColor "Yellow"
            }
        }
    }
}
else {
    Write-ColorMessage "Étape 2: Exécution des tests unitaires ignorée (option -SkipTests)" -ForegroundColor "Yellow"
}

# Étape 3: Vérification de sécurité
if (-not $SkipSecurity) {
    Write-ColorMessage "Étape 3: Vérification de sécurité..." -ForegroundColor "Cyan"
    
    $sensitivePatterns = @(
        "password\s*=\s*['\"][^'\"]+['\"]",
        "apikey\s*=\s*['\"][^'\"]+['\"]",
        "api_key\s*=\s*['\"][^'\"]+['\"]",
        "secret\s*=\s*['\"][^'\"]+['\"]",
        "token\s*=\s*['\"][^'\"]+['\"]",
        "-----BEGIN RSA PRIVATE KEY-----",
        "-----BEGIN PRIVATE KEY-----"
    )
    
    $allFiles = Get-ChildItem -Path $projectRoot -Recurse -File | Where-Object { $_.Extension -match "\.(ps1|py|json|md|txt|config|yml|yaml)$" }
    $sensitiveFiles = @()
    
    foreach ($file in $allFiles) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        
        if ($content) {
            foreach ($pattern in $sensitivePatterns) {
                if ($content -match $pattern) {
                    $sensitiveFiles += $file.FullName
                    break
                }
            }
        }
    }
    
    if ($sensitiveFiles.Count -gt 0) {
        Write-ColorMessage "Des informations potentiellement sensibles ont été détectées:" -ForegroundColor "Red"
        $sensitiveFiles | ForEach-Object {
            Write-ColorMessage "  - $_" -ForegroundColor "Red"
        }
        
        Write-ColorMessage "Assurez-vous de ne pas commiter d'informations sensibles comme des mots de passe ou des clés API" -ForegroundColor "Red"
        $allPassed = $false
    }
    else {
        Write-ColorMessage "Aucune information sensible détectée" -ForegroundColor "Green"
    }
}
else {
    Write-ColorMessage "Étape 3: Vérification de sécurité ignorée (option -SkipSecurity)" -ForegroundColor "Yellow"
}

# Afficher le résultat final
if ($allPassed) {
    Write-ColorMessage "`nToutes les vérifications ont réussi." -ForegroundColor "Green"
    exit 0
}
else {
    Write-ColorMessage "`nCertaines vérifications ont échoué. Consultez les messages d'erreur ci-dessus." -ForegroundColor "Red"
    exit 1
}
