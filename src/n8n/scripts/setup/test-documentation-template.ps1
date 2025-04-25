<#
.SYNOPSIS
    Script de test du template Hygen pour la documentation.

.DESCRIPTION
    Ce script teste le template Hygen pour la documentation en générant un document de test
    et en vérifiant que le document généré est valide et conforme aux attentes.

.PARAMETER OutputFolder
    Dossier de sortie pour le document généré. Par défaut, le document sera généré dans le dossier standard.

.PARAMETER DocumentName
    Nom du document à générer. Par défaut, "test-documentation".

.PARAMETER Category
    Catégorie du document à générer. Par défaut, "guides".

.PARAMETER Description
    Description du document à générer. Par défaut, "Document de test pour valider le template Hygen".

.PARAMETER KeepGeneratedFiles
    Si spécifié, les fichiers générés ne seront pas supprimés après le test.

.EXAMPLE
    .\test-documentation-template.ps1
    Teste le template Hygen pour la documentation avec les valeurs par défaut.

.EXAMPLE
    .\test-documentation-template.ps1 -DocumentName "my-test-doc" -Category "architecture" -Description "Ma documentation de test"
    Teste le template Hygen pour la documentation avec des valeurs personnalisées.

.NOTES
    Auteur: Équipe n8n
    Date de création: 2023-05-09
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$false)]
    [string]$OutputFolder = "",
    
    [Parameter(Mandatory=$false)]
    [string]$DocumentName = "test-documentation",
    
    [Parameter(Mandatory=$false)]
    [string]$Category = "guides",
    
    [Parameter(Mandatory=$false)]
    [string]$Description = "Document de test pour valider le template Hygen",
    
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

# Fonction pour générer un document avec Hygen
function New-Documentation {
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
        $outputFolder = Join-Path -Path $projectRoot -ChildPath "n8n\docs\$Category"
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
    
    # Générer le document
    Write-Info "Génération du document avec Hygen..."
    
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
        if ($PSCmdlet.ShouldProcess("Hygen", "Générer un document")) {
            $process = Start-Process -FilePath "npx" -ArgumentList "hygen n8n-doc new" -NoNewWindow -PassThru -RedirectStandardInput
            
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
                Write-Success "Document généré avec succès"
                
                # Déterminer le chemin du document généré
                $documentPath = Join-Path -Path $outputFolder -ChildPath "$Name.md"
                
                # Vérifier si le document a été généré
                if (Test-Path -Path $documentPath) {
                    Write-Success "Document généré: $documentPath"
                    
                    # Revenir au répertoire d'origine
                    Set-Location -Path $currentLocation
                    
                    return $documentPath
                } else {
                    Write-Error "Le document n'a pas été généré à l'emplacement attendu: $documentPath"
                    
                    # Revenir au répertoire d'origine
                    Set-Location -Path $currentLocation
                    
                    return $null
                }
            } else {
                Write-Error "Erreur lors de la génération du document (code: $($process.ExitCode))"
                
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
        Write-Error "Erreur lors de la génération du document: $_"
        
        # Revenir au répertoire d'origine
        Set-Location -Path $currentLocation
        
        return $null
    }
}

# Fonction pour vérifier le contenu du document généré
function Test-DocumentContent {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DocumentPath,
        
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [string]$Description
    )
    
    if (-not (Test-Path -Path $DocumentPath)) {
        Write-Error "Le document n'existe pas: $DocumentPath"
        return $false
    }
    
    $content = Get-Content -Path $DocumentPath -Raw
    $success = $true
    
    # Vérifier la présence du titre
    $titlePattern = "^# .*$Name"
    if ($content -match $titlePattern) {
        Write-Success "Le document contient le titre avec le nom: $Name"
    } else {
        Write-Error "Le document ne contient pas le titre avec le nom: $Name"
        $success = $false
    }
    
    # Vérifier la présence de la description
    if ($content -match [regex]::Escape($Description)) {
        Write-Success "Le document contient la description: $Description"
    } else {
        Write-Error "Le document ne contient pas la description: $Description"
        $success = $false
    }
    
    # Vérifier la présence des sections standard
    $sections = @(
        "## Description",
        "## Installation",
        "## Utilisation",
        "## Configuration",
        "## Exemples",
        "## Dépannage",
        "## Références"
    )
    
    foreach ($section in $sections) {
        if ($content -match [regex]::Escape($section)) {
            Write-Success "Le document contient la section: $section"
        } else {
            Write-Error "Le document ne contient pas la section: $section"
            $success = $false
        }
    }
    
    return $success
}

# Fonction pour vérifier la validité du Markdown
function Test-MarkdownValidity {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DocumentPath
    )
    
    if (-not (Test-Path -Path $DocumentPath)) {
        Write-Error "Le document n'existe pas: $DocumentPath"
        return $false
    }
    
    try {
        $content = Get-Content -Path $DocumentPath -Raw
        
        # Vérifier les titres
        $titlePattern = "^#+\s+.*$"
        $titles = [regex]::Matches($content, $titlePattern, "Multiline")
        
        if ($titles.Count -gt 0) {
            Write-Success "Le document contient des titres valides"
        } else {
            Write-Error "Le document ne contient pas de titres valides"
            return $false
        }
        
        # Vérifier les listes
        $listPattern = "^\s*[-*+]\s+.*$"
        $lists = [regex]::Matches($content, $listPattern, "Multiline")
        
        if ($lists.Count -gt 0) {
            Write-Success "Le document contient des listes valides"
        } else {
            Write-Warning "Le document ne contient pas de listes"
        }
        
        # Vérifier les liens
        $linkPattern = "\[.*\]\(.*\)"
        $links = [regex]::Matches($content, $linkPattern)
        
        if ($links.Count -gt 0) {
            Write-Success "Le document contient des liens valides"
        } else {
            Write-Warning "Le document ne contient pas de liens"
        }
        
        # Vérifier les blocs de code
        $codeBlockPattern = "```.*```"
        $codeBlocks = [regex]::Matches($content, $codeBlockPattern, "Singleline")
        
        if ($codeBlocks.Count -gt 0) {
            Write-Success "Le document contient des blocs de code valides"
        } else {
            Write-Warning "Le document ne contient pas de blocs de code"
        }
        
        return $true
    }
    catch {
        Write-Error "Erreur lors de la vérification de la validité du Markdown: $_"
        return $false
    }
}

# Fonction pour nettoyer les fichiers générés
function Remove-GeneratedFiles {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DocumentPath
    )
    
    if (-not (Test-Path -Path $DocumentPath)) {
        Write-Warning "Le document n'existe pas: $DocumentPath"
        return
    }
    
    if ($PSCmdlet.ShouldProcess($DocumentPath, "Supprimer")) {
        Remove-Item -Path $DocumentPath -Force
        Write-Success "Document supprimé: $DocumentPath"
    }
}

# Fonction principale
function Start-TemplateTest {
    Write-Info "Test du template Hygen pour la documentation..."
    
    # Générer un document
    $documentPath = New-Documentation -Name $DocumentName -Category $Category -Description $Description -OutputFolder $OutputFolder
    
    if (-not $documentPath) {
        Write-Error "Impossible de générer le document"
        return $false
    }
    
    # Vérifier le contenu du document
    $contentValid = Test-DocumentContent -DocumentPath $documentPath -Name $DocumentName -Description $Description
    
    # Vérifier la validité du Markdown
    $markdownValid = Test-MarkdownValidity -DocumentPath $documentPath
    
    # Nettoyer les fichiers générés
    if (-not $KeepGeneratedFiles) {
        Remove-GeneratedFiles -DocumentPath $documentPath
    } else {
        Write-Info "Les fichiers générés sont conservés: $documentPath"
    }
    
    # Afficher le résultat global
    Write-Host "`nRésultat du test:" -ForegroundColor $infoColor
    if ($contentValid -and $markdownValid) {
        Write-Success "Le template pour la documentation est valide"
        return $true
    } else {
        Write-Error "Le template pour la documentation est invalide"
        return $false
    }
}

# Exécuter le test
Start-TemplateTest
