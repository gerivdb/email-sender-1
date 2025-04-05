# Script de vérification avant push
# Ce script effectue une série de vérifications pour s'assurer que les changements sont cohérents

param (
    [Parameter(Mandatory = $false)]
    [switch]$Verbose,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Obtenir le chemin racine du projet
$projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
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

# Vérifier si nous sommes dans un dépôt Git
if (-not (Test-Path "$projectRoot\.git")) {
    Write-ColorMessage "Ce dossier n'est pas un dépôt Git" -ForegroundColor "Red"
    exit 1
}

Write-ColorMessage "Exécution des vérifications avant push..." -ForegroundColor "Cyan"

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
        Name = "Vérification des fichiers binaires"
        Function = {
            $binaryExtensions = @(".exe", ".dll", ".pdb", ".zip", ".7z", ".rar", ".jpg", ".jpeg", ".png", ".gif", ".ico", ".pdf")
            
            $binaryFiles = git status --porcelain | Where-Object { $_ -match '^\s*[AM]' } | ForEach-Object {
                $file = $_.Substring(3)
                $extension = [System.IO.Path]::GetExtension($file)
                
                if ($binaryExtensions -contains $extension.ToLower()) {
                    return $file
                }
            }
            
            if ($binaryFiles) {
                Write-ColorMessage "Des fichiers binaires ont été détectés:" -ForegroundColor "Yellow"
                $binaryFiles | ForEach-Object {
                    Write-ColorMessage "  - $_" -ForegroundColor "Yellow"
                }
                
                Write-ColorMessage "Assurez-vous que ces fichiers sont nécessaires et considérez l'utilisation de Git LFS" -ForegroundColor "Yellow"
                
                if (-not $Force) {
                    $confirmation = Read-Host "Voulez-vous continuer malgré les fichiers binaires? (O/N)"
                    return ($confirmation -eq "O" -or $confirmation -eq "o")
                }
            }
            
            return $true
        }
    },
    @{
        Name = "Vérification des fins de ligne"
        Function = {
            # Cette vérification est informative seulement
            $mixedLineEndings = git grep -l $'\r' -- "*.ps1" "*.py" "*.md" "*.json"
            
            if (-not [string]::IsNullOrEmpty($mixedLineEndings)) {
                Write-ColorMessage "Des fichiers avec des fins de ligne mixtes ont été détectés:" -ForegroundColor "Yellow"
                $mixedLineEndings -split "`n" | ForEach-Object {
                    if (-not [string]::IsNullOrEmpty($_)) {
                        Write-ColorMessage "  - $_" -ForegroundColor "Yellow"
                    }
                }
                
                Write-ColorMessage "Considérez l'utilisation de 'git config --global core.autocrlf true' pour standardiser les fins de ligne" -ForegroundColor "Yellow"
            }
            
            return $true
        }
    },
    @{
        Name = "Vérification des fichiers temporaires"
        Function = {
            $tempPatterns = @("*.tmp", "*.temp", "*~", "*.swp", "*.bak")
            $tempFiles = @()
            
            foreach ($pattern in $tempPatterns) {
                $found = git ls-files $pattern
                if (-not [string]::IsNullOrEmpty($found)) {
                    $tempFiles += $found -split "`n"
                }
            }
            
            if ($tempFiles) {
                Write-ColorMessage "Des fichiers temporaires ont été détectés:" -ForegroundColor "Yellow"
                $tempFiles | Where-Object { -not [string]::IsNullOrEmpty($_) } | ForEach-Object {
                    Write-ColorMessage "  - $_" -ForegroundColor "Yellow"
                }
                
                Write-ColorMessage "Considérez l'ajout de ces patterns à votre .gitignore" -ForegroundColor "Yellow"
                
                if (-not $Force) {
                    $confirmation = Read-Host "Voulez-vous continuer malgré les fichiers temporaires? (O/N)"
                    return ($confirmation -eq "O" -or $confirmation -eq "o")
                }
            }
            
            return $true
        }
    },
    @{
        Name = "Vérification des informations sensibles"
        Function = {
            $sensitivePatterns = @(
                "password\s*=",
                "apikey\s*=",
                "api_key\s*=",
                "secret\s*=",
                "token\s*=",
                "-----BEGIN RSA PRIVATE KEY-----",
                "-----BEGIN PRIVATE KEY-----"
            )
            
            $sensitiveFiles = @()
            
            foreach ($pattern in $sensitivePatterns) {
                $found = git diff --staged -G"$pattern" --name-only
                if (-not [string]::IsNullOrEmpty($found)) {
                    $sensitiveFiles += $found -split "`n"
                }
            }
            
            if ($sensitiveFiles) {
                Write-ColorMessage "Des informations potentiellement sensibles ont été détectées:" -ForegroundColor "Red"
                $sensitiveFiles | Where-Object { -not [string]::IsNullOrEmpty($_) } | ForEach-Object {
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
    
    # Afficher un résumé des changements
    Write-ColorMessage "`nRésumé des changements:" -ForegroundColor "Cyan"
    git diff --staged --stat
    
    # Demander confirmation pour le push
    $doPush = Read-Host "`nVoulez-vous effectuer le push maintenant? (O/N)"
    
    if ($doPush -eq "O" -or $doPush -eq "o") {
        git push
        Write-ColorMessage "Push effectué avec succès" -ForegroundColor "Green"
    }
    else {
        Write-ColorMessage "Push annulé par l'utilisateur" -ForegroundColor "Yellow"
    }
}
else {
    if ($Force) {
        Write-ColorMessage "`nCertaines vérifications ont échoué, mais l'option -Force est activée." -ForegroundColor "Yellow"
        
        $doPush = Read-Host "Voulez-vous quand même effectuer le push? (O/N)"
        
        if ($doPush -eq "O" -or $doPush -eq "o") {
            git push
            Write-ColorMessage "Push effectué avec succès (malgré les avertissements)" -ForegroundColor "Yellow"
        }
        else {
            Write-ColorMessage "Push annulé par l'utilisateur" -ForegroundColor "Yellow"
        }
    }
    else {
        Write-ColorMessage "`nCertaines vérifications ont échoué. Corrigez les problèmes avant de procéder au push." -ForegroundColor "Red"
        Write-ColorMessage "Vous pouvez utiliser l'option -Force pour ignorer ces vérifications." -ForegroundColor "Yellow"
    }
}

# Afficher l'aide si demandé
if ($args -contains "-help" -or $args -contains "--help" -or $args -contains "/?") {
    Write-ColorMessage "`nUtilisation: .\git-pre-push-check.ps1 [options]" -ForegroundColor "Cyan"
    Write-ColorMessage "`nOptions:" -ForegroundColor "Cyan"
    Write-ColorMessage "  -Verbose  Afficher des informations détaillées sur les vérifications" -ForegroundColor "Cyan"
    Write-ColorMessage "  -Force    Ignorer les échecs de vérification et continuer" -ForegroundColor "Cyan"
    Write-ColorMessage "`nExemples:" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\git-pre-push-check.ps1" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\git-pre-push-check.ps1 -Verbose" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\git-pre-push-check.ps1 -Force" -ForegroundColor "Cyan"
}
