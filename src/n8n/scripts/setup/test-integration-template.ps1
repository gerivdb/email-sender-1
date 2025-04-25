<#
.SYNOPSIS
    Script de test du template Hygen pour les intégrations.

.DESCRIPTION
    Ce script teste le template Hygen pour les intégrations en générant un script d'intégration de test
    et en vérifiant que le script généré est valide et conforme aux attentes.

.PARAMETER OutputFolder
    Dossier de sortie pour le script généré. Par défaut, le script sera généré dans le dossier standard.

.PARAMETER IntegrationName
    Nom du script d'intégration à générer. Par défaut, "Test-Integration".

.PARAMETER System
    Système d'intégration. Par défaut, "mcp".

.PARAMETER Description
    Description du script d'intégration à générer. Par défaut, "Script d'intégration de test pour valider le template Hygen".

.PARAMETER KeepGeneratedFiles
    Si spécifié, les fichiers générés ne seront pas supprimés après le test.

.EXAMPLE
    .\test-integration-template.ps1
    Teste le template Hygen pour les intégrations avec les valeurs par défaut.

.EXAMPLE
    .\test-integration-template.ps1 -IntegrationName "My-TestIntegration" -System "api" -Description "Mon script d'intégration de test"
    Teste le template Hygen pour les intégrations avec des valeurs personnalisées.

.NOTES
    Auteur: Équipe n8n
    Date de création: 2023-05-09
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$false)]
    [string]$OutputFolder = "",
    
    [Parameter(Mandatory=$false)]
    [string]$IntegrationName = "Test-Integration",
    
    [Parameter(Mandatory=$false)]
    [string]$System = "mcp",
    
    [Parameter(Mandatory=$false)]
    [string]$Description = "Script d'intégration de test pour valider le template Hygen",
    
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

# Fonction pour générer un script d'intégration avec Hygen
function New-IntegrationScript {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [string]$System,
        
        [Parameter(Mandatory=$true)]
        [string]$Description,
        
        [Parameter(Mandatory=$false)]
        [string]$OutputFolder = ""
    )
    
    $projectRoot = Get-ProjectPath
    
    # Déterminer le dossier de sortie
    if ([string]::IsNullOrEmpty($OutputFolder)) {
        $outputFolder = Join-Path -Path $projectRoot -ChildPath "n8n\integrations\$System"
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
    
    # Générer le script d'intégration
    Write-Info "Génération du script d'intégration avec Hygen..."
    
    try {
        # Changer le répertoire courant
        $currentLocation = Get-Location
        Set-Location -Path $projectRoot
        
        # Préparer les réponses pour les prompts
        $responses = @(
            $Name,
            $System,
            $Description
        )
        
        # Exécuter Hygen avec les réponses
        if ($PSCmdlet.ShouldProcess("Hygen", "Générer un script d'intégration")) {
            $process = Start-Process -FilePath "npx" -ArgumentList "hygen n8n-integration new" -NoNewWindow -PassThru -RedirectStandardInput
            
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
                Write-Success "Script d'intégration généré avec succès"
                
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
                Write-Error "Erreur lors de la génération du script d'intégration (code: $($process.ExitCode))"
                
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
        Write-Error "Erreur lors de la génération du script d'intégration: $_"
        
        # Revenir au répertoire d'origine
        Set-Location -Path $currentLocation
        
        return $null
    }
}

# Fonction pour vérifier le contenu du script généré
function Test-IntegrationScriptContent {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [string]$System,
        
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
    
    # Vérifier la présence du système
    if ($content -match [regex]::Escape($System)) {
        Write-Success "Le script contient le système: $System"
    } else {
        Write-Error "Le script ne contient pas le système: $System"
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
    
    # Vérifier la présence des fonctions d'intégration spécifiques
    $integrationFunctions = @(
        "Connect-$System",
        "Get-$System",
        "Set-$System",
        "Sync-"
    )
    
    foreach ($function in $integrationFunctions) {
        if ($content -match $function) {
            Write-Success "Le script contient la fonction d'intégration: $function"
        } else {
            Write-Error "Le script ne contient pas la fonction d'intégration: $function"
            $success = $false
        }
    }
    
    return $success
}

# Fonction pour tester l'exécution du script généré
function Test-IntegrationScriptExecution {
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

# Fonction pour vérifier l'intégration avec MCP
function Test-McpIntegration {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory=$true)]
        [string]$System
    )
    
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Error "Le script n'existe pas: $ScriptPath"
        return $false
    }
    
    if ($System -ne "mcp") {
        Write-Warning "Le système n'est pas MCP, l'intégration avec MCP ne sera pas testée"
        return $true
    }
    
    $content = Get-Content -Path $ScriptPath -Raw
    $success = $true
    
    # Vérifier la présence des fonctions d'intégration MCP spécifiques
    $mcpFunctions = @(
        "Connect-Mcp",
        "Get-McpData",
        "Set-McpData",
        "Sync-McpWorkflows"
    )
    
    foreach ($function in $mcpFunctions) {
        if ($content -match $function) {
            Write-Success "Le script contient la fonction d'intégration MCP: $function"
        } else {
            Write-Error "Le script ne contient pas la fonction d'intégration MCP: $function"
            $success = $false
        }
    }
    
    return $success
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
    Write-Info "Test du template Hygen pour les intégrations..."
    
    # Générer un script d'intégration
    $scriptPath = New-IntegrationScript -Name $IntegrationName -System $System -Description $Description -OutputFolder $OutputFolder
    
    if (-not $scriptPath) {
        Write-Error "Impossible de générer le script d'intégration"
        return $false
    }
    
    # Vérifier le contenu du script
    $contentValid = Test-IntegrationScriptContent -ScriptPath $scriptPath -Name $IntegrationName -System $System -Description $Description
    
    # Tester l'exécution du script
    $executionValid = Test-IntegrationScriptExecution -ScriptPath $scriptPath
    
    # Vérifier l'intégration avec MCP
    $mcpIntegrationValid = Test-McpIntegration -ScriptPath $scriptPath -System $System
    
    # Nettoyer les fichiers générés
    if (-not $KeepGeneratedFiles) {
        Remove-GeneratedFiles -ScriptPath $scriptPath
    } else {
        Write-Info "Les fichiers générés sont conservés: $scriptPath"
    }
    
    # Afficher le résultat global
    Write-Host "`nRésultat du test:" -ForegroundColor $infoColor
    if ($contentValid -and $executionValid -and $mcpIntegrationValid) {
        Write-Success "Le template pour les intégrations est valide"
        return $true
    } else {
        Write-Error "Le template pour les intégrations est invalide"
        return $false
    }
}

# Exécuter le test
Start-TemplateTest
