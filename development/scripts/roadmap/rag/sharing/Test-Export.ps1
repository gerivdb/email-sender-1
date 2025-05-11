<#
.SYNOPSIS
    Test des fonctionnalités d'export pour le partage des vues.

.DESCRIPTION
    Ce script teste les fonctionnalités d'export pour le partage des vues,
    y compris l'export en JSON, URL paramétré et fichier autonome.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer les modules requis
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$exportManagerPath = Join-Path -Path $scriptDir -ChildPath "ExportManager.ps1"

if (Test-Path -Path $exportManagerPath) {
    . $exportManagerPath
    Write-Host "Module ExportManager.ps1 chargé avec succès depuis: $exportManagerPath"
} else {
    throw "Le module ExportManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $exportManagerPath"
}

# Vérifier que les fonctions sont disponibles
if (-not (Get-Command -Name Export-ViewToJSON -ErrorAction SilentlyContinue)) {
    Write-Host "La fonction Export-ViewToJSON n'est pas disponible. Chargement explicite des fonctions..."

    # Charger explicitement les fonctions
    function Export-ViewToJSON {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [PSObject]$ViewData,

            [Parameter(Mandatory = $false)]
            [switch]$Compact,

            [Parameter(Mandatory = $false)]
            [string]$ExportStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\ExportStore"),

            [Parameter(Mandatory = $false)]
            [switch]$EnableDebug
        )

        $exportManager = New-ExportManager -ExportStorePath $ExportStorePath -EnableDebug:$EnableDebug
        return $exportManager.ExportToJSON($ViewData, $Compact)
    }

    function Export-ViewToURL {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [PSObject]$ViewData,

            [Parameter(Mandatory = $true)]
            [string]$BaseURL,

            [Parameter(Mandatory = $false)]
            [string]$ExportStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\ExportStore"),

            [Parameter(Mandatory = $false)]
            [switch]$EnableDebug
        )

        $exportManager = New-ExportManager -ExportStorePath $ExportStorePath -EnableDebug:$EnableDebug
        return $exportManager.ExportToURL($ViewData, $BaseURL)
    }

    function Export-ViewToStandalone {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [PSObject]$ViewData,

            [Parameter(Mandatory = $true)]
            [string]$TemplatePath,

            [Parameter(Mandatory = $false)]
            [string]$ExportStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\ExportStore"),

            [Parameter(Mandatory = $false)]
            [switch]$EnableDebug
        )

        $exportManager = New-ExportManager -ExportStorePath $ExportStorePath -EnableDebug:$EnableDebug
        return $exportManager.ExportToStandalone($ViewData, $TemplatePath)
    }

    function Export-ViewEncrypted {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [PSObject]$ViewData,

            [Parameter(Mandatory = $true)]
            [ValidateSet("JSON", "JSON_COMPACT")]
            [string]$Format,

            [Parameter(Mandatory = $true)]
            [System.Security.SecureString]$Password,

            [Parameter(Mandatory = $false)]
            [string]$ExportStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\ExportStore"),

            [Parameter(Mandatory = $false)]
            [switch]$EnableDebug
        )

        $exportManager = New-ExportManager -ExportStorePath $ExportStorePath -EnableDebug:$EnableDebug
        return $exportManager.ExportEncrypted($ViewData, $Format, $Password)
    }

    Write-Host "Fonctions chargées explicitement"
}

# Fonction pour afficher un message formaté
function Write-TestMessage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Level = "Info"
    )

    $colors = @{
        Info    = "White"
        Success = "Green"
        Warning = "Yellow"
        Error   = "Red"
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colors[$Level]
}

# Fonction pour créer un répertoire de test temporaire
function New-TestDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$BasePath = $env:TEMP,

        [Parameter(Mandatory = $false)]
        [string]$DirectoryName = "ExportTest_$(Get-Date -Format 'yyyyMMddHHmmss')"
    )

    $testDir = Join-Path -Path $BasePath -ChildPath $DirectoryName

    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
    }

    New-Item -Path $testDir -ItemType Directory -Force | Out-Null

    return $testDir
}

# Fonction pour créer des données de vue de test
function New-TestViewData {
    [CmdletBinding()]
    param()

    $viewId = [guid]::NewGuid().ToString()
    $now = Get-Date

    $viewData = [PSCustomObject]@{
        Id       = $viewId
        Title    = "Vue de test pour l'export"
        Type     = "RAG_SEARCH_RESULTS"
        Metadata = [PSCustomObject]@{
            Creator     = "Utilisateur de test"
            CreatedAt   = $now.ToString('o')
            Description = "Cette vue a été créée pour tester les fonctionnalités d'export"
            Tags        = @("test", "export", "rag")
            Query       = "requête de test"
        }
        Items    = @(
            [PSCustomObject]@{
                Id       = [guid]::NewGuid().ToString()
                Title    = "Premier résultat"
                Content  = "Ceci est le contenu du premier résultat de recherche."
                Source   = "Source 1"
                Tags     = @("important", "prioritaire")
                Score    = 0.95
                Metadata = [PSCustomObject]@{
                    Type      = "document"
                    CreatedAt = $now.AddDays(-5).ToString('o')
                }
            },
            [PSCustomObject]@{
                Id       = [guid]::NewGuid().ToString()
                Title    = "Deuxième résultat"
                Content  = "Ceci est le contenu du deuxième résultat de recherche."
                Source   = "Source 2"
                Tags     = @("secondaire")
                Score    = 0.85
                Metadata = [PSCustomObject]@{
                    Type      = "document"
                    CreatedAt = $now.AddDays(-3).ToString('o')
                }
            },
            [PSCustomObject]@{
                Id       = [guid]::NewGuid().ToString()
                Title    = "Troisième résultat"
                Content  = "Ceci est le contenu du troisième résultat de recherche."
                Source   = "Source 3"
                Tags     = @("tertiaire", "optionnel")
                Score    = 0.75
                Metadata = [PSCustomObject]@{
                    Type      = "document"
                    CreatedAt = $now.AddDays(-1).ToString('o')
                }
            }
        )
    }

    return $viewData
}

# Fonction pour tester l'export en JSON
function Test-JSONExport {
    [CmdletBinding()]
    param()

    Write-TestMessage "Démarrage du test d'export en JSON" -Level "Info"

    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"

    # Créer un chemin de stockage des exports pour les tests
    $exportStorePath = Join-Path -Path $testDir -ChildPath "ExportStore"

    # Créer des données de vue de test
    $viewData = New-TestViewData
    Write-TestMessage "Données de vue de test créées avec l'ID: $($viewData.Id)" -Level "Info"

    # Test 1: Exporter en JSON standard
    Write-TestMessage "Test 1: Export en JSON standard" -Level "Info"

    $jsonPath = Export-ViewToJSON -ViewData $viewData -ExportStorePath $exportStorePath -EnableDebug

    if (Test-Path -Path $jsonPath) {
        Write-TestMessage "Vue exportée avec succès en JSON standard: $jsonPath" -Level "Success"

        # Vérifier le contenu du fichier
        $jsonContent = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json

        if ($jsonContent.Id -eq $viewData.Id) {
            Write-TestMessage "Le contenu du fichier JSON est valide" -Level "Success"
        } else {
            Write-TestMessage "Le contenu du fichier JSON n'est pas valide" -Level "Error"
            return
        }
    } else {
        Write-TestMessage "Échec de l'export en JSON standard" -Level "Error"
        return
    }

    # Test 2: Exporter en JSON compact
    Write-TestMessage "Test 2: Export en JSON compact" -Level "Info"

    $jsonCompactPath = Export-ViewToJSON -ViewData $viewData -Compact -ExportStorePath $exportStorePath -EnableDebug

    if (Test-Path -Path $jsonCompactPath) {
        Write-TestMessage "Vue exportée avec succès en JSON compact: $jsonCompactPath" -Level "Success"

        # Vérifier le contenu du fichier
        $jsonCompactContent = Get-Content -Path $jsonCompactPath -Raw | ConvertFrom-Json

        if ($jsonCompactContent.Id -eq $viewData.Id) {
            Write-TestMessage "Le contenu du fichier JSON compact est valide" -Level "Success"
        } else {
            Write-TestMessage "Le contenu du fichier JSON compact n'est pas valide" -Level "Error"
            return
        }
    } else {
        Write-TestMessage "Échec de l'export en JSON compact" -Level "Error"
        return
    }

    # Test 3: Exporter en JSON chiffré
    Write-TestMessage "Test 3: Export en JSON chiffré" -Level "Info"

    $passwordSecure = ConvertTo-SecureString "MotDePasse123!" -AsPlainText -Force
    $jsonEncryptedPath = Export-ViewEncrypted -ViewData $viewData -Format "JSON" -Password $passwordSecure -ExportStorePath $exportStorePath -EnableDebug

    if (Test-Path -Path $jsonEncryptedPath) {
        Write-TestMessage "Vue exportée avec succès en JSON chiffré: $jsonEncryptedPath" -Level "Success"
    } else {
        Write-TestMessage "Échec de l'export en JSON chiffré" -Level "Error"
        return
    }

    Write-TestMessage "Tests d'export en JSON terminés avec succès" -Level "Success"

    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Fonction pour tester l'export en URL paramétré
function Test-URLExport {
    [CmdletBinding()]
    param()

    Write-TestMessage "Démarrage du test d'export en URL paramétré" -Level "Info"

    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"

    # Créer un chemin de stockage des exports pour les tests
    $exportStorePath = Join-Path -Path $testDir -ChildPath "ExportStore"

    # Créer des données de vue de test
    $viewData = New-TestViewData
    Write-TestMessage "Données de vue de test créées avec l'ID: $($viewData.Id)" -Level "Info"

    # Test 1: Exporter en URL paramétré
    Write-TestMessage "Test 1: Export en URL paramétré" -Level "Info"

    $baseURL = "https://example.com/view"
    $urlPath = Export-ViewToURL -ViewData $viewData -BaseURL $baseURL -ExportStorePath $exportStorePath -EnableDebug

    if (Test-Path -Path $urlPath) {
        Write-TestMessage "Vue exportée avec succès en URL paramétré: $urlPath" -Level "Success"

        # Vérifier le contenu du fichier
        $urlContent = Get-Content -Path $urlPath -Raw

        if ($urlContent.StartsWith($baseURL)) {
            Write-TestMessage "Le contenu du fichier URL est valide" -Level "Success"
        } else {
            Write-TestMessage "Le contenu du fichier URL n'est pas valide" -Level "Error"
            return
        }
    } else {
        Write-TestMessage "Échec de l'export en URL paramétré" -Level "Error"
        return
    }

    Write-TestMessage "Tests d'export en URL paramétré terminés avec succès" -Level "Success"

    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Fonction pour tester l'export en fichier autonome
function Test-StandaloneExport {
    [CmdletBinding()]
    param()

    Write-TestMessage "Démarrage du test d'export en fichier autonome" -Level "Info"

    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"

    # Créer un chemin de stockage des exports pour les tests
    $exportStorePath = Join-Path -Path $testDir -ChildPath "ExportStore"

    # Créer des données de vue de test
    $viewData = New-TestViewData
    Write-TestMessage "Données de vue de test créées avec l'ID: $($viewData.Id)" -Level "Info"

    # Test 1: Exporter en fichier autonome
    Write-TestMessage "Test 1: Export en fichier autonome" -Level "Info"

    $templatePath = Join-Path -Path $scriptDir -ChildPath "templates\standalone-template.html"

    if (-not (Test-Path -Path $templatePath)) {
        Write-TestMessage "Le template pour le fichier autonome n'existe pas: $templatePath" -Level "Error"
        return
    }

    $standalonePath = Export-ViewToStandalone -ViewData $viewData -TemplatePath $templatePath -ExportStorePath $exportStorePath -EnableDebug

    if (Test-Path -Path $standalonePath) {
        Write-TestMessage "Vue exportée avec succès en fichier autonome: $standalonePath" -Level "Success"

        # Vérifier le contenu du fichier
        $standaloneContent = Get-Content -Path $standalonePath -Raw

        if ($standaloneContent.Contains($viewData.Id)) {
            Write-TestMessage "Le contenu du fichier autonome est valide" -Level "Success"
        } else {
            Write-TestMessage "Le contenu du fichier autonome n'est pas valide" -Level "Error"
            return
        }
    } else {
        Write-TestMessage "Échec de l'export en fichier autonome" -Level "Error"
        return
    }

    Write-TestMessage "Tests d'export en fichier autonome terminés avec succès" -Level "Success"

    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Exécuter tous les tests
Write-TestMessage "Démarrage des tests d'export pour le partage des vues" -Level "Info"
Test-JSONExport
Test-URLExport
Test-StandaloneExport
Write-TestMessage "Tous les tests d'export pour le partage des vues sont terminés" -Level "Info"
