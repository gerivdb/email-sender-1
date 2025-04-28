# Script PowerShell pour le hook pre-push
# Ce script est exÃ©cutÃ© automatiquement avant chaque push

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

Write-ColorMessage "ExÃ©cution du hook pre-push PowerShell..." -ForegroundColor "Cyan"

# Liste des vÃ©rifications Ã  effectuer
$checks = @(
    @{
        Name = "VÃ©rification des conflits non rÃ©solus"
        Function = {
            $conflictFiles = git diff --name-only --diff-filter=U
            
            if (-not [string]::IsNullOrEmpty($conflictFiles)) {
                Write-ColorMessage "Des conflits non rÃ©solus ont Ã©tÃ© dÃ©tectÃ©s dans les fichiers suivants:" -ForegroundColor "Red"
                $conflictFiles | ForEach-Object {
                    Write-ColorMessage "  - $_" -ForegroundColor "Red"
                }
                return $false
            }
            
            return $true
        }
    },
    @{
        Name = "VÃ©rification des fichiers volumineux"
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
                Write-ColorMessage "Des fichiers volumineux ont Ã©tÃ© dÃ©tectÃ©s:" -ForegroundColor "Yellow"
                $largeFiles | ForEach-Object {
                    Write-ColorMessage "  - $($_.Path) ($($_.Size) MB)" -ForegroundColor "Yellow"
                }
                
                Write-ColorMessage "ConsidÃ©rez l'utilisation de Git LFS pour les fichiers volumineux" -ForegroundColor "Yellow"
                
                if (-not $Force) {
                    $confirmation = Read-Host "Voulez-vous continuer malgrÃ© les fichiers volumineux? (O/N)"
                    return ($confirmation -eq "O" -or $confirmation -eq "o")
                }
            }
            
            return $true
        }
    },
    @{
        Name = "VÃ©rification des tests unitaires"
        Function = {
            if ($SkipTests) {
                Write-ColorMessage "Tests unitaires ignorÃ©s (option -SkipTests)" -ForegroundColor "Yellow"
                return $true
            }
            
            # VÃ©rifier s'il y a des tests Ã  exÃ©cuter
            $testFiles = Get-ChildItem -Path $projectRoot -Recurse -Include "*test*.py", "*Test*.ps1" -File
            
            if ($testFiles.Count -eq 0) {
                Write-ColorMessage "Aucun fichier de test trouvÃ©" -ForegroundColor "Yellow"
                return $true
            }
            
            Write-ColorMessage "ExÃ©cution des tests unitaires..." -ForegroundColor "Cyan"
            
            # ExÃ©cuter les tests Python
            $pythonTestFiles = $testFiles | Where-Object { $_.Extension -eq ".py" }
            if ($pythonTestFiles.Count -gt 0) {
                Write-ColorMessage "ExÃ©cution des tests Python..." -ForegroundColor "Cyan"
                
                if (Get-Command pytest -ErrorAction SilentlyContinue) {
                    $testResult = $true
                    
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
                    
                    if (-not $testResult -and -not $Force) {
                        Write-ColorMessage "Corrigez les tests unitaires avant de pousser ou utilisez -Force pour ignorer" -ForegroundColor "Red"
                        return $false
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
                
                if (Get-Command Invoke-Pester -ErrorAction SilentlyContinue) {
                    $testResult = $true
                    
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
                    
                    if (-not $testResult -and -not $Force) {
                        Write-ColorMessage "Corrigez les tests unitaires avant de pousser ou utilisez -Force pour ignorer" -ForegroundColor "Red"
                        return $false
                    }
                }
                else {
                    Write-ColorMessage "Pester non installÃ©. Installation recommandÃ©e : Install-Module -Name Pester -Force" -ForegroundColor "Yellow"
                }
            }
            
            return $true
        }
    },
    @{
        Name = "VÃ©rification des informations sensibles"
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
                Write-ColorMessage "Des informations potentiellement sensibles ont Ã©tÃ© dÃ©tectÃ©es:" -ForegroundColor "Red"
                $sensitiveFiles | ForEach-Object {
                    Write-ColorMessage "  - $_" -ForegroundColor "Red"
                }
                
                Write-ColorMessage "Assurez-vous de ne pas commiter d'informations sensibles comme des mots de passe ou des clÃ©s API" -ForegroundColor "Red"
                
                if (-not $Force) {
                    $confirmation = Read-Host "Voulez-vous continuer malgrÃ© les informations sensibles? (O/N)"
                    return ($confirmation -eq "O" -or $confirmation -eq "o")
                }
            }
            
            return $true
        }
    }
)

# ExÃ©cuter les vÃ©rifications
$allPassed = $true

foreach ($check in $checks) {
    Write-VerboseMessage "ExÃ©cution de: $($check.Name)..."
    
    $result = & $check.Function
    
    if ($result) {
        Write-VerboseMessage "âœ“ $($check.Name): RÃ©ussi"
    }
    else {
        Write-ColorMessage "âœ— $($check.Name): Ã‰chec" -ForegroundColor "Red"
        $allPassed = $false
        
        if (-not $Force) {
            break
        }
    }
}

# Afficher le rÃ©sultat final
if ($allPassed) {
    Write-ColorMessage "`nToutes les vÃ©rifications ont rÃ©ussi. Vous pouvez procÃ©der au push." -ForegroundColor "Green"
    exit 0
}
else {
    if ($Force) {
        Write-ColorMessage "`nCertaines vÃ©rifications ont Ã©chouÃ©, mais l'option -Force est activÃ©e." -ForegroundColor "Yellow"
        exit 0
    }
    else {
        Write-ColorMessage "`nCertaines vÃ©rifications ont Ã©chouÃ©. Corrigez les problÃ¨mes avant de procÃ©der au push." -ForegroundColor "Red"
        Write-ColorMessage "Vous pouvez utiliser l'option -Force pour ignorer ces vÃ©rifications." -ForegroundColor "Yellow"
        exit 1
    }
}
