<#
.SYNOPSIS
    Test des fonctionnalités d'import pour le partage des vues.

.DESCRIPTION
    Ce script teste les fonctionnalités d'import pour le partage des vues,
    y compris l'import depuis un fichier JSON, URL paramétré et fichier autonome.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer les modules requis
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$importManagerPath = Join-Path -Path $scriptDir -ChildPath "ImportManager.ps1"
$exportManagerPath = Join-Path -Path $scriptDir -ChildPath "ExportManager.ps1"

Write-Host "Chargement du module ImportManager depuis: $importManagerPath"
. $importManagerPath

Write-Host "Chargement du module ExportManager depuis: $exportManagerPath"
. $exportManagerPath

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
        Info = "White"
        Success = "Green"
        Warning = "Yellow"
        Error = "Red"
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
        [string]$DirectoryName = "ImportTest_$(Get-Date -Format 'yyyyMMddHHmmss')"
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
        Id = $viewId
        Title = "Vue de test pour l'import"
        Type = "RAG_SEARCH_RESULTS"
        Metadata = [PSCustomObject]@{
            Creator = "Utilisateur de test"
            CreatedAt = $now.ToString('o')
            Description = "Cette vue a été créée pour tester les fonctionnalités d'import"
            Tags = @("test", "import", "rag")
            Query = "requête de test"
        }
        Items = @(
            [PSCustomObject]@{
                Id = [guid]::NewGuid().ToString()
                Title = "Premier résultat"
                Content = "Ceci est le contenu du premier résultat de recherche."
                Source = "Source 1"
                Tags = @("important", "prioritaire")
                Score = 0.95
                Metadata = [PSCustomObject]@{
                    Type = "document"
                    CreatedAt = $now.AddDays(-5).ToString('o')
                }
            },
            [PSCustomObject]@{
                Id = [guid]::NewGuid().ToString()
                Title = "Deuxième résultat"
                Content = "Ceci est le contenu du deuxième résultat de recherche."
                Source = "Source 2"
                Tags = @("secondaire")
                Score = 0.85
                Metadata = [PSCustomObject]@{
                    Type = "document"
                    CreatedAt = $now.AddDays(-3).ToString('o')
                }
            }
        )
    }
    
    return $viewData
}

# Fonction pour tester l'import depuis un fichier JSON
function Test-JSONImport {
    [CmdletBinding()]
    param()
    
    Write-TestMessage "Démarrage du test d'import depuis un fichier JSON" -Level "Info"
    
    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"
    
    # Créer des données de vue de test
    $viewData = New-TestViewData
    Write-TestMessage "Données de vue de test créées avec l'ID: $($viewData.Id)" -Level "Info"
    
    # Exporter la vue en JSON pour le test
    $exportManager = New-ExportManager -ExportStorePath $testDir -EnableDebug
    $jsonPath = $exportManager.ExportToJSON($viewData, $false)
    
    if (-not (Test-Path -Path $jsonPath)) {
        Write-TestMessage "Échec de l'export en JSON pour le test" -Level "Error"
        return
    }
    
    Write-TestMessage "Vue exportée en JSON pour le test: $jsonPath" -Level "Info"
    
    # Importer la vue depuis le fichier JSON
    $importManager = New-ImportManager -ImportStorePath $testDir -EnableDebug
    
    try {
        $importedViewData = $importManager.ImportFromJSON($jsonPath)
        
        if ($null -ne $importedViewData -and $importedViewData.Id -eq $viewData.Id) {
            Write-TestMessage "Vue importée avec succès depuis le fichier JSON" -Level "Success"
        }
        else {
            Write-TestMessage "Échec de l'import depuis le fichier JSON" -Level "Error"
            return
        }
    }
    catch {
        Write-TestMessage "Erreur lors de l'import depuis le fichier JSON: $($_.Exception.Message)" -Level "Error"
        return
    }
    
    # Tester la fonction Import-ViewFromFile
    try {
        $importedViewData2 = Import-ViewFromFile -FilePath $jsonPath -ImportStorePath $testDir -EnableDebug
        
        if ($null -ne $importedViewData2 -and $importedViewData2.Id -eq $viewData.Id) {
            Write-TestMessage "Vue importée avec succès via Import-ViewFromFile" -Level "Success"
        }
        else {
            Write-TestMessage "Échec de l'import via Import-ViewFromFile" -Level "Error"
            return
        }
    }
    catch {
        Write-TestMessage "Erreur lors de l'import via Import-ViewFromFile: $($_.Exception.Message)" -Level "Error"
        return
    }
    
    Write-TestMessage "Tests d'import depuis un fichier JSON terminés avec succès" -Level "Success"
    
    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Fonction pour tester l'import depuis une URL paramétrée
function Test-URLImport {
    [CmdletBinding()]
    param()
    
    Write-TestMessage "Démarrage du test d'import depuis une URL paramétrée" -Level "Info"
    
    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"
    
    # Créer des données de vue de test
    $viewData = New-TestViewData
    Write-TestMessage "Données de vue de test créées avec l'ID: $($viewData.Id)" -Level "Info"
    
    # Exporter la vue en URL pour le test
    $exportManager = New-ExportManager -ExportStorePath $testDir -EnableDebug
    $baseURL = "https://example.com/view"
    $urlPath = $exportManager.ExportToURL($viewData, $baseURL)
    
    if (-not (Test-Path -Path $urlPath)) {
        Write-TestMessage "Échec de l'export en URL pour le test" -Level "Error"
        return
    }
    
    Write-TestMessage "Vue exportée en URL pour le test: $urlPath" -Level "Info"
    
    # Lire l'URL depuis le fichier
    $url = Get-Content -Path $urlPath -Raw
    
    # Importer la vue depuis l'URL
    $importManager = New-ImportManager -ImportStorePath $testDir -EnableDebug
    
    try {
        $importedViewData = $importManager.ImportFromURL($url)
        
        if ($null -ne $importedViewData -and $importedViewData.Id -eq $viewData.Id) {
            Write-TestMessage "Vue importée avec succès depuis l'URL" -Level "Success"
        }
        else {
            Write-TestMessage "Échec de l'import depuis l'URL" -Level "Error"
            return
        }
    }
    catch {
        Write-TestMessage "Erreur lors de l'import depuis l'URL: $($_.Exception.Message)" -Level "Error"
        return
    }
    
    # Tester la fonction Import-ViewFromURL
    try {
        $importedViewData2 = Import-ViewFromURL -URL $url -ImportStorePath $testDir -EnableDebug
        
        if ($null -ne $importedViewData2 -and $importedViewData2.Id -eq $viewData.Id) {
            Write-TestMessage "Vue importée avec succès via Import-ViewFromURL" -Level "Success"
        }
        else {
            Write-TestMessage "Échec de l'import via Import-ViewFromURL" -Level "Error"
            return
        }
    }
    catch {
        Write-TestMessage "Erreur lors de l'import via Import-ViewFromURL: $($_.Exception.Message)" -Level "Error"
        return
    }
    
    Write-TestMessage "Tests d'import depuis une URL paramétrée terminés avec succès" -Level "Success"
    
    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Fonction pour tester l'import depuis un fichier autonome
function Test-StandaloneImport {
    [CmdletBinding()]
    param()
    
    Write-TestMessage "Démarrage du test d'import depuis un fichier autonome" -Level "Info"
    
    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"
    
    # Créer des données de vue de test
    $viewData = New-TestViewData
    Write-TestMessage "Données de vue de test créées avec l'ID: $($viewData.Id)" -Level "Info"
    
    # Exporter la vue en fichier autonome pour le test
    $exportManager = New-ExportManager -ExportStorePath $testDir -EnableDebug
    $templatePath = Join-Path -Path $scriptDir -ChildPath "templates\standalone-template.html"
    
    if (-not (Test-Path -Path $templatePath)) {
        Write-TestMessage "Le template pour le fichier autonome n'existe pas: $templatePath" -Level "Error"
        return
    }
    
    $standalonePath = $exportManager.ExportToStandalone($viewData, $templatePath)
    
    if (-not (Test-Path -Path $standalonePath)) {
        Write-TestMessage "Échec de l'export en fichier autonome pour le test" -Level "Error"
        return
    }
    
    Write-TestMessage "Vue exportée en fichier autonome pour le test: $standalonePath" -Level "Info"
    
    # Importer la vue depuis le fichier autonome
    $importManager = New-ImportManager -ImportStorePath $testDir -EnableDebug
    
    try {
        $importedViewData = $importManager.ImportFromStandalone($standalonePath)
        
        if ($null -ne $importedViewData -and $importedViewData.Id -eq $viewData.Id) {
            Write-TestMessage "Vue importée avec succès depuis le fichier autonome" -Level "Success"
        }
        else {
            Write-TestMessage "Échec de l'import depuis le fichier autonome" -Level "Error"
            return
        }
    }
    catch {
        Write-TestMessage "Erreur lors de l'import depuis le fichier autonome: $($_.Exception.Message)" -Level "Error"
        return
    }
    
    # Tester la fonction Import-ViewFromFile
    try {
        $importedViewData2 = Import-ViewFromFile -FilePath $standalonePath -ImportStorePath $testDir -EnableDebug
        
        if ($null -ne $importedViewData2 -and $importedViewData2.Id -eq $viewData.Id) {
            Write-TestMessage "Vue importée avec succès via Import-ViewFromFile" -Level "Success"
        }
        else {
            Write-TestMessage "Échec de l'import via Import-ViewFromFile" -Level "Error"
            return
        }
    }
    catch {
        Write-TestMessage "Erreur lors de l'import via Import-ViewFromFile: $($_.Exception.Message)" -Level "Error"
        return
    }
    
    Write-TestMessage "Tests d'import depuis un fichier autonome terminés avec succès" -Level "Success"
    
    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Exécuter tous les tests
Write-TestMessage "Démarrage des tests d'import pour le partage des vues" -Level "Info"
Test-JSONImport
Test-URLImport
Test-StandaloneImport
Write-TestMessage "Tous les tests d'import pour le partage des vues sont terminés" -Level "Info"
