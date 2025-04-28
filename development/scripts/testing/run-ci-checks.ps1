# Script pour exÃ©cuter les vÃ©rifications CI/CD
# Ce script est conÃ§u pour Ãªtre exÃ©cutÃ© dans un environnement CI/CD

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

# Fonction pour afficher un message colorÃ©
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

Write-ColorMessage "ExÃ©cution des vÃ©rifications CI/CD..." -ForegroundColor "Cyan"

$allPassed = $true

# Ã‰tape 1: VÃ©rification du style de code
if (-not $SkipLint) {
    Write-ColorMessage "Ã‰tape 1: VÃ©rification du style de code..." -ForegroundColor "Cyan"
    
    # VÃ©rifier les fichiers PowerShell avec PSScriptAnalyzer
    $psFiles = Get-ChildItem -Path $projectRoot -Recurse -Include "*.ps1" -File
    if ($psFiles.Count -gt 0) {
        Write-ColorMessage "VÃ©rification de $($psFiles.Count) fichiers PowerShell..." -ForegroundColor "Cyan"
        
        $hasErrors = $false
        
        if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) {
            foreach ($file in $psFiles) {
                Write-VerboseMessage "VÃ©rification de $($file.Name)..."
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
                Write-ColorMessage "Des erreurs de style ont Ã©tÃ© dÃ©tectÃ©es dans les fichiers PowerShell" -ForegroundColor "Red"
                $allPassed = $false
            }
            else {
                Write-ColorMessage "Aucune erreur de style dÃ©tectÃ©e dans les fichiers PowerShell" -ForegroundColor "Green"
            }
        }
        else {
            Write-ColorMessage "PSScriptAnalyzer non installÃ©. Installation recommandÃ©e : Install-Module -Name PSScriptAnalyzer -Force" -ForegroundColor "Yellow"
        }
    }
    
    # VÃ©rifier les fichiers Python avec flake8
    $pyFiles = Get-ChildItem -Path $projectRoot -Recurse -Include "*.py" -File
    if ($pyFiles.Count -gt 0) {
        Write-ColorMessage "VÃ©rification de $($pyFiles.Count) fichiers Python..." -ForegroundColor "Cyan"
        
        $hasErrors = $false
        
        if (Get-Command flake8 -ErrorAction SilentlyContinue) {
            foreach ($file in $pyFiles) {
                Write-VerboseMessage "VÃ©rification de $($file.Name)..."
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
                Write-ColorMessage "Des erreurs de style ont Ã©tÃ© dÃ©tectÃ©es dans les fichiers Python" -ForegroundColor "Red"
                $allPassed = $false
            }
            else {
                Write-ColorMessage "Aucune erreur de style dÃ©tectÃ©e dans les fichiers Python" -ForegroundColor "Green"
            }
        }
        else {
            Write-ColorMessage "flake8 non installÃ©. Installation recommandÃ©e : pip install flake8" -ForegroundColor "Yellow"
        }
    }
}
else {
    Write-ColorMessage "Ã‰tape 1: VÃ©rification du style de code ignorÃ©e (option -SkipLint)" -ForegroundColor "Yellow"
}

# Ã‰tape 2: ExÃ©cution des tests unitaires
if (-not $SkipTests) {
    Write-ColorMessage "Ã‰tape 2: ExÃ©cution des tests unitaires..." -ForegroundColor "Cyan"
    
    # VÃ©rifier s'il y a des tests Ã  exÃ©cuter
    $testFiles = Get-ChildItem -Path $projectRoot -Recurse -Include "*test*.py", "*Test*.ps1" -File
    
    if ($testFiles.Count -eq 0) {
        Write-ColorMessage "Aucun fichier de test trouvÃ©" -ForegroundColor "Yellow"
    }
    else {
        # ExÃ©cuter les tests Python
        $pythonTestFiles = $testFiles | Where-Object { $_.Extension -eq ".py" }
        if ($pythonTestFiles.Count -gt 0) {
            Write-ColorMessage "ExÃ©cution des tests Python..." -ForegroundColor "Cyan"
            
            $testResult = $true
            
            if (Get-Command pytest -ErrorAction SilentlyContinue) {
                foreach ($testFile in $pythonTestFiles) {
                    Write-ColorMessage "  ExÃ©cution de $($testFile.Name)..." -ForegroundColor "Cyan"
                    $output = & pytest $testFile.FullName -v
                    
                    if ($LASTEXITCODE -ne 0) {
                        Write-ColorMessage "  Ã‰chec des tests dans $($testFile.Name)" -ForegroundColor "Red"
                        $output | ForEach-Object {
                            Write-ColorMessage "    $_" -ForegroundColor "Red"
                        }
                        $testResult = $false
                    }
                    else {
                        Write-ColorMessage "  Tests rÃ©ussis dans $($testFile.Name)" -ForegroundColor "Green"
                    }
                }
                
                if (-not $testResult) {
                    Write-ColorMessage "Des tests Python ont Ã©chouÃ©" -ForegroundColor "Red"
                    $allPassed = $false
                }
            }
            else {
                Write-ColorMessage "pytest non installÃ©. Installation recommandÃ©e : pip install pytest" -ForegroundColor "Yellow"
            }
        }
        
        # ExÃ©cuter les tests PowerShell
        $powershellTestFiles = $testFiles | Where-Object { $_.Extension -eq ".ps1" }
        if ($powershellTestFiles.Count -gt 0) {
            Write-ColorMessage "ExÃ©cution des tests PowerShell..." -ForegroundColor "Cyan"
            
            $testResult = $true
            
            if (Get-Command Invoke-Pester -ErrorAction SilentlyContinue) {
                foreach ($testFile in $powershellTestFiles) {
                    Write-ColorMessage "  ExÃ©cution de $($testFile.Name)..." -ForegroundColor "Cyan"
                    $results = Invoke-Pester -Path $testFile.FullName -PassThru
                    
                    if ($results.FailedCount -gt 0) {
                        Write-ColorMessage "  Ã‰chec des tests dans $($testFile.Name): $($results.FailedCount) test(s) Ã©chouÃ©(s)" -ForegroundColor "Red"
                        $testResult = $false
                    }
                    else {
                        Write-ColorMessage "  Tests rÃ©ussis dans $($testFile.Name): $($results.PassedCount) test(s) rÃ©ussi(s)" -ForegroundColor "Green"
                    }
                }
                
                if (-not $testResult) {
                    Write-ColorMessage "Des tests PowerShell ont Ã©chouÃ©" -ForegroundColor "Red"
                    $allPassed = $false
                }
            }
            else {
                Write-ColorMessage "Pester non installÃ©. Installation recommandÃ©e : Install-Module -Name Pester -Force" -ForegroundColor "Yellow"
            }
        }
    }
}
else {
    Write-ColorMessage "Ã‰tape 2: ExÃ©cution des tests unitaires ignorÃ©e (option -SkipTests)" -ForegroundColor "Yellow"
}

# Ã‰tape 3: VÃ©rification de sÃ©curitÃ©
if (-not $SkipSecurity) {
    Write-ColorMessage "Ã‰tape 3: VÃ©rification de sÃ©curitÃ©..." -ForegroundColor "Cyan"
    
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
        Write-ColorMessage "Des informations potentiellement sensibles ont Ã©tÃ© dÃ©tectÃ©es:" -ForegroundColor "Red"
        $sensitiveFiles | ForEach-Object {
            Write-ColorMessage "  - $_" -ForegroundColor "Red"
        }
        
        Write-ColorMessage "Assurez-vous de ne pas commiter d'informations sensibles comme des mots de passe ou des clÃ©s API" -ForegroundColor "Red"
        $allPassed = $false
    }
    else {
        Write-ColorMessage "Aucune information sensible dÃ©tectÃ©e" -ForegroundColor "Green"
    }
}
else {
    Write-ColorMessage "Ã‰tape 3: VÃ©rification de sÃ©curitÃ© ignorÃ©e (option -SkipSecurity)" -ForegroundColor "Yellow"
}

# Afficher le rÃ©sultat final
if ($allPassed) {
    Write-ColorMessage "`nToutes les vÃ©rifications ont rÃ©ussi." -ForegroundColor "Green"
    exit 0
}
else {
    Write-ColorMessage "`nCertaines vÃ©rifications ont Ã©chouÃ©. Consultez les messages d'erreur ci-dessus." -ForegroundColor "Red"
    exit 1
}
