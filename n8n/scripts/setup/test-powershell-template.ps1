<#
.SYNOPSIS
    Script de test du template Hygen pour les scripts PowerShell.

.DESCRIPTION
    Ce script teste le template Hygen pour les scripts PowerShell en générant un script de test
    et en vérifiant que le script généré est valide et conforme aux attentes.

.PARAMETER OutputFolder
    Dossier de sortie pour le script généré. Par défaut, le script sera généré dans le dossier standard.

.PARAMETER ScriptName
    Nom du script à générer. Par défaut, "Test-HygenTemplate".

.PARAMETER Category
    Catégorie du script à générer. Par défaut, "test".

.PARAMETER Description
    Description du script à générer. Par défaut, "Script de test pour valider le template Hygen".

.PARAMETER KeepGeneratedFiles
    Si spécifié, les fichiers générés ne seront pas supprimés après le test.

.EXAMPLE
    .\test-powershell-template.ps1
    Teste le template Hygen pour les scripts PowerShell avec les valeurs par défaut.

.EXAMPLE
    .\test-powershell-template.ps1 -ScriptName "My-TestScript" -Category "deployment" -Description "Mon script de test"
    Teste le template Hygen pour les scripts PowerShell avec des valeurs personnalisées.

.NOTES
    Auteur: Équipe n8n
    Date de création: 2023-05-09
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$false)]
    [string]$OutputFolder = "",
    
    [Parameter(Mandatory=$false)]
    [string]$ScriptName = "Test-HygenTemplate",
    
    [Parameter(Mandatory=$false)]
    [string]$Category = "test",
    
    [Parameter(Mandatory=$false)]
    [string]$Description = "Script de test pour valider le template Hygen",
    
    [Parameter(Mandatory=$false)]
    [switch]$KeepGeneratedFiles = $false
)

# Définir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

# Fonction pour afficher un message de succès
function Write-Success {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "✓ $Message" -ForegroundColor $successColor
}

# Fonction pour afficher un message d'erreur
function Write-Error {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "✗ $Message" -ForegroundColor $errorColor
}

# Fonction pour afficher un message d'information
function Write-Info {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "ℹ $Message" -ForegroundColor $infoColor
}

# Fonction pour afficher un message d'avertissement
function Write-Warning {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "⚠ $Message" -ForegroundColor $warningColor
}

# Fonction pour obtenir le chemin du projet
function Get-ProjectPath {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = (Get-Item $scriptPath).Parent.Parent.Parent.FullName
    return $projectRoot
}

# Fonction pour générer un script PowerShell avec Hygen
function New-PowerShellScript {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [string]$Category,
        
        [Parameter(Mandatory=$true)]
        [string]$Description,
        
        [Parameter(Mandatory=$false)]
        [string]$OutputFolder = ""
    )
    
    $projectRoot = Get-ProjectPath
    
    # Déterminer le dossier de sortie
    if ([string]::IsNullOrEmpty($OutputFolder)) {
        $outputFolder = Join-Path -Path $projectRoot -ChildPath "n8n\automation\$Category"
    } else {
        $outputFolder = $OutputFolder
    }
    
    # Vérifier si le dossier de sortie existe
    if (-not (Test-Path -Path $outputFolder)) {
        if ($PSCmdlet.ShouldProcess($outputFolder, "Créer le dossier")) {
            New-Item -Path $outputFolder -ItemType Directory -Force | Out-Null
            Write-Success "Dossier de sortie créé: $outputFolder"
        }
    }
    
    # Générer le script
    Write-Info "Génération du script PowerShell avec Hygen..."
    
    try {
        # Changer le répertoire courant
        $currentLocation = Get-Location
        Set-Location -Path $projectRoot
        
        # Préparer les réponses pour les prompts
        $responses = @(
            $Name,
            $Category,
            $Description
        )
        
        # Exécuter Hygen avec les réponses
        if ($PSCmdlet.ShouldProcess("Hygen", "Générer un script PowerShell")) {
            $process = Start-Process -FilePath "npx" -ArgumentList "hygen n8n-script new" -NoNewWindow -PassThru -RedirectStandardInput
            
            # Attendre que le processus soit prêt
            Start-Sleep -Seconds 1
            
            # Envoyer les réponses
            foreach ($response in $responses) {
                [System.IO.StreamWriter]::new($process.StandardInput.BaseStream).WriteLine($response)
                Start-Sleep -Milliseconds 500
            }
            
            # Attendre que le processus se termine
            $process.WaitForExit()
            
            # Vérifier le code de sortie
            if ($process.ExitCode -eq 0) {
                Write-Success "Script PowerShell généré avec succès"
                
                # Déterminer le chemin du script généré
                $scriptPath = Join-Path -Path $outputFolder -ChildPath "$Name.ps1"
                
                # Vérifier si le script a été généré
                if (Test-Path -Path $scriptPath) {
                    Write-Success "Script généré: $scriptPath"
                    
                    # Revenir au répertoire d'origine
                    Set-Location -Path $currentLocation
                    
                    return $scriptPath
                } else {
                    Write-Error "Le script n'a pas été généré à l'emplacement attendu: $scriptPath"
                    
                    # Revenir au répertoire d'origine
                    Set-Location -Path $currentLocation
                    
                    return $null
                }
            } else {
                Write-Error "Erreur lors de la génération du script PowerShell (code: $($process.ExitCode))"
                
                # Revenir au répertoire d'origine
                Set-Location -Path $currentLocation
                
                return $null
            }
        } else {
            # Revenir au répertoire d'origine
            Set-Location -Path $currentLocation
            
            return $null
        }
    }
    catch {
        Write-Error "Erreur lors de la génération du script PowerShell: $_"
        
        # Revenir au répertoire d'origine
        Set-Location -Path $currentLocation
        
        return $null
    }
}

# Fonction pour vérifier le contenu du script généré
function Test-ScriptContent {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [string]$Description
    )
    
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Error "Le script n'existe pas: $ScriptPath"
        return $false
    }
    
    $content = Get-Content -Path $ScriptPath -Raw
    $success = $true
    
    # Vérifier la présence du nom du script
    if ($content -match [regex]::Escape($Name)) {
        Write-Success "Le script contient le nom: $Name"
    } else {
        Write-Error "Le script ne contient pas le nom: $Name"
        $success = $false
    }
    
    # Vérifier la présence de la description
    if ($content -match [regex]::Escape($Description)) {
        Write-Success "Le script contient la description: $Description"
    } else {
        Write-Error "Le script ne contient pas la description: $Description"
        $success = $false
    }
    
    # Vérifier la présence des sections standard
    $sections = @(
        "SYNOPSIS",
        "DESCRIPTION",
        "PARAMETER",
        "EXAMPLE",
        "NOTES",
        "CmdletBinding",
        "param",
        "BEGIN",
        "PROCESS",
        "END"
    )
    
    foreach ($section in $sections) {
        if ($content -match $section) {
            Write-Success "Le script contient la section: $section"
        } else {
            Write-Error "Le script ne contient pas la section: $section"
            $success = $false
        }
    }
    
    return $success
}

# Fonction pour tester l'exécution du script généré
function Test-ScriptExecution {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath
    )
    
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Error "Le script n'existe pas: $ScriptPath"
        return $false
    }
    
    try {
        # Vérifier la syntaxe du script
        $errors = $null
        $tokens = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$tokens, [ref]$errors)
        
        if ($errors.Count -gt 0) {
            Write-Error "Le script contient des erreurs de syntaxe:"
            foreach ($error in $errors) {
                Write-Error "  - $($error.Message)"
            }
            return $false
        } else {
            Write-Success "Le script ne contient pas d'erreurs de syntaxe"
        }
        
        # Exécuter le script avec -WhatIf pour éviter les effets secondaires
        if ($PSCmdlet.ShouldProcess($ScriptPath, "Tester l'exécution")) {
            $output = & $ScriptPath -WhatIf 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Le script s'exécute sans erreurs"
                return $true
            } else {
                Write-Error "Erreur lors de l'exécution du script (code: $LASTEXITCODE)"
                return $false
            }
        } else {
            return $true
        }
    }
    catch {
        Write-Error "Erreur lors du test d'exécution du script: $_"
        return $false
    }
}

# Fonction pour nettoyer les fichiers générés
function Remove-GeneratedFiles {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath
    )
    
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Warning "Le script n'existe pas: $ScriptPath"
        return
    }
    
    if ($PSCmdlet.ShouldProcess($ScriptPath, "Supprimer")) {
        Remove-Item -Path $ScriptPath -Force
        Write-Success "Script supprimé: $ScriptPath"
    }
}

# Fonction principale
function Start-TemplateTest {
    Write-Info "Test du template Hygen pour les scripts PowerShell..."
    
    # Générer un script PowerShell
    $scriptPath = New-PowerShellScript -Name $ScriptName -Category $Category -Description $Description -OutputFolder $OutputFolder
    
    if (-not $scriptPath) {
        Write-Error "Impossible de générer le script PowerShell"
        return $false
    }
    
    # Vérifier le contenu du script
    $contentValid = Test-ScriptContent -ScriptPath $scriptPath -Name $ScriptName -Description $Description
    
    # Tester l'exécution du script
    $executionValid = Test-ScriptExecution -ScriptPath $scriptPath
    
    # Nettoyer les fichiers générés
    if (-not $KeepGeneratedFiles) {
        Remove-GeneratedFiles -ScriptPath $scriptPath
    } else {
        Write-Info "Les fichiers générés sont conservés: $scriptPath"
    }
    
    # Afficher le résultat global
    Write-Host "`nRésultat du test:" -ForegroundColor $infoColor
    if ($contentValid -and $executionValid) {
        Write-Success "Le template pour les scripts PowerShell est valide"
        return $true
    } else {
        Write-Error "Le template pour les scripts PowerShell est invalide"
        return $false
    }
}

# Exécuter le test
Start-TemplateTest
