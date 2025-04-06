# Script PowerShell pour le hook pre-push
# Ce script est exécuté automatiquement avant chaque push

param (
    [Parameter(Mandatory = $false)]
    [switch]$SkipTests,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$Verbose
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

# Fonction pour afficher un message verbose
function Write-VerboseMessage {
    param (
        [string]$Message
    )
    
    if ($Verbose) {
        Write-ColorMessage $Message -ForegroundColor "Gray"
    }
}

Write-ColorMessage "Exécution du hook pre-push PowerShell..." -ForegroundColor "Cyan"

# Liste des vérifications à effectuer
$checks = @(
    @{
        Name = "Vérification des conflits non résolus"
        Function = {
            $conflictFiles = git diff --name-only --diff-filter=U
            
            if (-not [string]::IsNullOrEmpty($conflictFiles)) {
                Write-ColorMessage "Des conflits non résolus ont été détectés dans les fichiers suivants:" -ForegroundColor "Red"
                $conflictFiles | ForEach-Object {
                    Write-ColorMessage "  - $_" -ForegroundColor "Red"
                }
                return $false
            }
            
            return $true
        }
    },
    @{
        Name = "Vérification des fichiers volumineux"
        Function = {
            $largeFiles = git status --porcelain | Where-Object { $_ -match '^\s*[AM]' } | ForEach-Object {
                $file = $_.Substring(3)
                $fileInfo = Get-Item $file -ErrorAction SilentlyContinue
                
                if ($fileInfo -and $fileInfo.Length -gt 5MB) {
                    return @{
                        Path = $file
                        Size = [math]::Round($fileInfo.Length / 1MB, 2)
                    }
                }
            }
            
            if ($largeFiles) {
                Write-ColorMessage "Des fichiers volumineux ont été détectés:" -ForegroundColor "Yellow"
                $largeFiles | ForEach-Object {
                    Write-ColorMessage "  - $($_.Path) ($($_.Size) MB)" -ForegroundColor "Yellow"
                }
                
                Write-ColorMessage "Considérez l'utilisation de Git LFS pour les fichiers volumineux" -ForegroundColor "Yellow"
                
                if (-not $Force) {
                    $confirmation = Read-Host "Voulez-vous continuer malgré les fichiers volumineux? (O/N)"
                    return ($confirmation -eq "O" -or $confirmation -eq "o")
                }
            }
            
            return $true
        }
    },
    @{
        Name = "Vérification des tests unitaires"
        Function = {
            if ($SkipTests) {
                Write-ColorMessage "Tests unitaires ignorés (option -SkipTests)" -ForegroundColor "Yellow"
                return $true
            }
            
            # Vérifier s'il y a des tests à exécuter
            $testFiles = Get-ChildItem -Path $projectRoot -Recurse -Include "*test*.py", "*Test*.ps1" -File
            
            if ($testFiles.Count -eq 0) {
                Write-ColorMessage "Aucun fichier de test trouvé" -ForegroundColor "Yellow"
                return $true
            }
            
            Write-ColorMessage "Exécution des tests unitaires..." -ForegroundColor "Cyan"
            
            # Exécuter les tests Python
            $pythonTestFiles = $testFiles | Where-Object { $_.Extension -eq ".py" }
            if ($pythonTestFiles.Count -gt 0) {
                Write-ColorMessage "Exécution des tests Python..." -ForegroundColor "Cyan"
                
                if (Get-Command pytest -ErrorAction SilentlyContinue) {
                    $testResult = $true
                    
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
                    
                    if (-not $testResult -and -not $Force) {
                        Write-ColorMessage "Corrigez les tests unitaires avant de pousser ou utilisez -Force pour ignorer" -ForegroundColor "Red"
                        return $false
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
                
                if (Get-Command Invoke-Pester -ErrorAction SilentlyContinue) {
                    $testResult = $true
                    
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
                    
                    if (-not $testResult -and -not $Force) {
                        Write-ColorMessage "Corrigez les tests unitaires avant de pousser ou utilisez -Force pour ignorer" -ForegroundColor "Red"
                        return $false
                    }
                }
                else {
                    Write-ColorMessage "Pester non installé. Installation recommandée : Install-Module -Name Pester -Force" -ForegroundColor "Yellow"
                }
            }
            
            return $true
        }
    },
    @{
        Name = "Vérification des informations sensibles"
        Function = {
            $sensitivePatterns = @(
                "password\s*=\s*['\"][^'\"]+['\"]",
                "apikey\s*=\s*['\"][^'\"]+['\"]",
                "api_key\s*=\s*['\"][^'\"]+['\"]",
                "secret\s*=\s*['\"][^'\"]+['\"]",
                "token\s*=\s*['\"][^'\"]+['\"]",
                "-----BEGIN RSA PRIVATE KEY-----",
                "-----BEGIN PRIVATE KEY-----"
            )
            
            $sensitiveFiles = @()
            
            $allFiles = git diff --name-only --cached
            
            foreach ($file in $allFiles) {
                $filePath = Join-Path $projectRoot $file
                
                if (Test-Path $filePath) {
                    $content = Get-Content $filePath -Raw
                    
                    foreach ($pattern in $sensitivePatterns) {
                        if ($content -match $pattern) {
                            $sensitiveFiles += $file
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
                
                if (-not $Force) {
                    $confirmation = Read-Host "Voulez-vous continuer malgré les informations sensibles? (O/N)"
                    return ($confirmation -eq "O" -or $confirmation -eq "o")
                }
            }
            
            return $true
        }
    }
)

# Exécuter les vérifications
$allPassed = $true

foreach ($check in $checks) {
    Write-VerboseMessage "Exécution de: $($check.Name)..."
    
    $result = & $check.Function
    
    if ($result) {
        Write-VerboseMessage "✓ $($check.Name): Réussi"
    }
    else {
        Write-ColorMessage "✗ $($check.Name): Échec" -ForegroundColor "Red"
        $allPassed = $false
        
        if (-not $Force) {
            break
        }
    }
}

# Afficher le résultat final
if ($allPassed) {
    Write-ColorMessage "`nToutes les vérifications ont réussi. Vous pouvez procéder au push." -ForegroundColor "Green"
    exit 0
}
else {
    if ($Force) {
        Write-ColorMessage "`nCertaines vérifications ont échoué, mais l'option -Force est activée." -ForegroundColor "Yellow"
        exit 0
    }
    else {
        Write-ColorMessage "`nCertaines vérifications ont échoué. Corrigez les problèmes avant de procéder au push." -ForegroundColor "Red"
        Write-ColorMessage "Vous pouvez utiliser l'option -Force pour ignorer ces vérifications." -ForegroundColor "Yellow"
        exit 1
    }
}
