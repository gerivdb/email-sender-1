<#
.SYNOPSIS
    Test de l'intégration du partage des vues RAG.

.DESCRIPTION
    Ce script teste l'intégration entre le système de partage des vues
    et les autres composants du système RAG.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer les modules requis
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$sharingIntegrationPath = Join-Path -Path $scriptDir -ChildPath "SharingIntegration.ps1"

Write-Host "Chargement du module SharingIntegration depuis: $sharingIntegrationPath"
. $sharingIntegrationPath

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
        [string]$DirectoryName = "IntegrationTest_$(Get-Date -Format 'yyyyMMddHHmmss')"
    )
    
    $testDir = Join-Path -Path $BasePath -ChildPath $DirectoryName
    
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
    }
    
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
    
    return $testDir
}

# Fonction pour créer un résultat RAG de test
function New-TestRAGResult {
    [CmdletBinding()]
    param()
    
    $now = Get-Date
    
    $ragResult = [PSCustomObject]@{
        Query = "requête de test RAG"
        Timestamp = $now.ToString('o')
        TotalResults = 3
        ProcessingTime = 0.25
        Tags = @("test", "rag", "integration")
        Results = @(
            [PSCustomObject]@{
                Title = "Premier résultat RAG"
                Content = "Ceci est le contenu du premier résultat de recherche RAG."
                Source = "Source RAG 1"
                Path = "C:\Data\document1.txt"
                Tags = @("important", "prioritaire")
                Score = 0.95
                Metadata = [PSCustomObject]@{
                    Type = "document"
                    CreatedAt = $now.AddDays(-5).ToString('o')
                }
            },
            [PSCustomObject]@{
                Title = "Deuxième résultat RAG"
                Content = "Ceci est le contenu du deuxième résultat de recherche RAG."
                Source = "Source RAG 2"
                Path = "C:\Data\document2.txt"
                Tags = @("secondaire")
                Score = 0.85
                Metadata = [PSCustomObject]@{
                    Type = "document"
                    CreatedAt = $now.AddDays(-3).ToString('o')
                }
            },
            [PSCustomObject]@{
                Title = "Troisième résultat RAG"
                Content = "Ceci est le contenu du troisième résultat de recherche RAG."
                Source = "Source RAG 3"
                Path = "C:\Data\document3.txt"
                Tags = @("tertiaire", "optionnel")
                Score = 0.75
                Metadata = [PSCustomObject]@{
                    Type = "document"
                    CreatedAt = $now.AddDays(-1).ToString('o')
                }
            }
        )
    }
    
    return $ragResult
}

# Fonction pour tester la conversion d'un résultat RAG en vue partageable
function Test-RAGConversion {
    [CmdletBinding()]
    param()
    
    Write-TestMessage "Démarrage du test de conversion d'un résultat RAG en vue partageable" -Level "Info"
    
    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"
    
    # Créer un résultat RAG de test
    $ragResult = New-TestRAGResult
    Write-TestMessage "Résultat RAG de test créé" -Level "Info"
    
    # Convertir le résultat RAG en vue partageable
    try {
        $view = ConvertTo-ShareableView -RAGResult $ragResult -Title "Vue de test RAG" -Description "Description de la vue de test RAG" -Creator "Utilisateur de test" -StoragePath $testDir -EnableDebug
        
        if ($null -ne $view -and $view.PSObject.Properties.Name.Contains("Id")) {
            Write-TestMessage "Résultat RAG converti avec succès en vue partageable avec l'ID: $($view.Id)" -Level "Success"
        }
        else {
            Write-TestMessage "Échec de la conversion du résultat RAG en vue partageable" -Level "Error"
            return
        }
        
        # Vérifier les propriétés de la vue
        if ($view.Title -eq "Vue de test RAG" -and $view.Type -eq "RAG_SEARCH_RESULTS" -and $view.Items.Count -eq 3) {
            Write-TestMessage "La vue contient les propriétés attendues" -Level "Success"
        }
        else {
            Write-TestMessage "La vue ne contient pas les propriétés attendues" -Level "Error"
            return
        }
    }
    catch {
        Write-TestMessage "Erreur lors de la conversion du résultat RAG en vue partageable: $($_.Exception.Message)" -Level "Error"
        return
    }
    
    Write-TestMessage "Test de conversion d'un résultat RAG en vue partageable terminé avec succès" -Level "Success"
    
    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
    
    return $view
}

# Fonction pour tester le partage d'une vue
function Test-ViewSharing {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$View
    )
    
    Write-TestMessage "Démarrage du test de partage d'une vue" -Level "Info"
    
    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"
    
    # Créer le répertoire des templates
    $templatesDir = Join-Path -Path $testDir -ChildPath "templates"
    New-Item -Path $templatesDir -ItemType Directory -Force | Out-Null
    
    # Copier le template HTML
    $sourceTemplatePath = Join-Path -Path $scriptDir -ChildPath "templates\standalone-template.html"
    $targetTemplatePath = Join-Path -Path $templatesDir -ChildPath "standalone-template.html"
    
    if (Test-Path -Path $sourceTemplatePath) {
        Copy-Item -Path $sourceTemplatePath -Destination $targetTemplatePath -Force
        Write-TestMessage "Template HTML copié: $targetTemplatePath" -Level "Info"
    }
    else {
        Write-TestMessage "Le template HTML n'existe pas: $sourceTemplatePath" -Level "Warning"
    }
    
    # Partager la vue en format JSON
    try {
        $recipients = @("user1@example.com", "user2@example.com")
        $permissions = @("READ_STANDARD", "READ_EXTENDED")
        
        $shareResult = Share-RAGView -View $View -Format "JSON" -Recipients $recipients -Permissions $permissions -StoragePath $testDir -EnableDebug
        
        if ($null -ne $shareResult -and $shareResult.ContainsKey("ViewId")) {
            Write-TestMessage "Vue partagée avec succès en format JSON: $($shareResult.ExportPath)" -Level "Success"
        }
        else {
            Write-TestMessage "Échec du partage de la vue en format JSON" -Level "Error"
            return
        }
        
        # Vérifier le fichier d'export
        if (Test-Path -Path $shareResult.ExportPath) {
            Write-TestMessage "Le fichier d'export existe: $($shareResult.ExportPath)" -Level "Success"
        }
        else {
            Write-TestMessage "Le fichier d'export n'existe pas: $($shareResult.ExportPath)" -Level "Error"
            return
        }
    }
    catch {
        Write-TestMessage "Erreur lors du partage de la vue en format JSON: $($_.Exception.Message)" -Level "Error"
        return
    }
    
    # Partager la vue en format URL
    try {
        $shareResult = Share-RAGView -View $View -Format "URL" -Recipients $recipients -Permissions $permissions -StoragePath $testDir -EnableDebug
        
        if ($null -ne $shareResult -and $shareResult.ContainsKey("ViewId")) {
            Write-TestMessage "Vue partagée avec succès en format URL: $($shareResult.ExportPath)" -Level "Success"
        }
        else {
            Write-TestMessage "Échec du partage de la vue en format URL" -Level "Error"
            return
        }
        
        # Vérifier le fichier d'export
        if (Test-Path -Path $shareResult.ExportPath) {
            Write-TestMessage "Le fichier d'export existe: $($shareResult.ExportPath)" -Level "Success"
        }
        else {
            Write-TestMessage "Le fichier d'export n'existe pas: $($shareResult.ExportPath)" -Level "Error"
            return
        }
    }
    catch {
        Write-TestMessage "Erreur lors du partage de la vue en format URL: $($_.Exception.Message)" -Level "Error"
        return
    }
    
    # Partager la vue en format STANDALONE si le template existe
    if (Test-Path -Path $targetTemplatePath) {
        try {
            $shareResult = Share-RAGView -View $View -Format "STANDALONE" -Recipients $recipients -Permissions $permissions -StoragePath $testDir -EnableDebug
            
            if ($null -ne $shareResult -and $shareResult.ContainsKey("ViewId")) {
                Write-TestMessage "Vue partagée avec succès en format STANDALONE: $($shareResult.ExportPath)" -Level "Success"
            }
            else {
                Write-TestMessage "Échec du partage de la vue en format STANDALONE" -Level "Error"
                return
            }
            
            # Vérifier le fichier d'export
            if (Test-Path -Path $shareResult.ExportPath) {
                Write-TestMessage "Le fichier d'export existe: $($shareResult.ExportPath)" -Level "Success"
            }
            else {
                Write-TestMessage "Le fichier d'export n'existe pas: $($shareResult.ExportPath)" -Level "Error"
                return
            }
        }
        catch {
            Write-TestMessage "Erreur lors du partage de la vue en format STANDALONE: $($_.Exception.Message)" -Level "Error"
            return
        }
    }
    
    Write-TestMessage "Test de partage d'une vue terminé avec succès" -Level "Success"
    
    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
    
    return $shareResult
}

# Fonction pour tester l'import et l'intégration d'une vue
function Test-ViewImportAndIntegration {
    [CmdletBinding()]
    param()
    
    Write-TestMessage "Démarrage du test d'import et d'intégration d'une vue" -Level "Info"
    
    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"
    
    # Créer un résultat RAG de test
    $ragResult = New-TestRAGResult
    Write-TestMessage "Résultat RAG de test créé" -Level "Info"
    
    # Convertir le résultat RAG en vue partageable
    $view = ConvertTo-ShareableView -RAGResult $ragResult -Title "Vue de test pour import" -Description "Description de la vue de test pour import" -Creator "Utilisateur de test" -StoragePath $testDir -EnableDebug
    Write-TestMessage "Résultat RAG converti en vue partageable avec l'ID: $($view.Id)" -Level "Info"
    
    # Exporter la vue en JSON
    $exportManager = New-ExportManager -ExportStorePath $testDir -EnableDebug
    $jsonPath = $exportManager.ExportToJSON($view, $false)
    Write-TestMessage "Vue exportée en JSON: $jsonPath" -Level "Info"
    
    # Importer la vue
    try {
        $importedView = Import-SharedView -Path $jsonPath -StoragePath $testDir -EnableDebug
        
        if ($null -ne $importedView -and $importedView.Id -eq $view.Id) {
            Write-TestMessage "Vue importée avec succès: $($importedView.Id)" -Level "Success"
        }
        else {
            Write-TestMessage "Échec de l'import de la vue" -Level "Error"
            return
        }
    }
    catch {
        Write-TestMessage "Erreur lors de l'import de la vue: $($_.Exception.Message)" -Level "Error"
        return
    }
    
    # Intégrer la vue en mode Append
    try {
        $integrationResult = Integrate-ImportedView -View $importedView -IntegrationMode "Append" -StoragePath $testDir -EnableDebug
        
        if ($null -ne $integrationResult -and $integrationResult.Status -eq "Success") {
            Write-TestMessage "Vue intégrée avec succès en mode Append: $($integrationResult.Message)" -Level "Success"
        }
        else {
            Write-TestMessage "Échec de l'intégration de la vue en mode Append" -Level "Error"
            return
        }
    }
    catch {
        Write-TestMessage "Erreur lors de l'intégration de la vue en mode Append: $($_.Exception.Message)" -Level "Error"
        return
    }
    
    # Intégrer la vue en mode Replace
    try {
        $integrationResult = Integrate-ImportedView -View $importedView -IntegrationMode "Replace" -StoragePath $testDir -EnableDebug
        
        if ($null -ne $integrationResult -and $integrationResult.Status -eq "Success") {
            Write-TestMessage "Vue intégrée avec succès en mode Replace: $($integrationResult.Message)" -Level "Success"
        }
        else {
            Write-TestMessage "Échec de l'intégration de la vue en mode Replace" -Level "Error"
            return
        }
    }
    catch {
        Write-TestMessage "Erreur lors de l'intégration de la vue en mode Replace: $($_.Exception.Message)" -Level "Error"
        return
    }
    
    # Intégrer la vue en mode Merge
    try {
        $integrationResult = Integrate-ImportedView -View $importedView -IntegrationMode "Merge" -StoragePath $testDir -EnableDebug
        
        if ($null -ne $integrationResult -and $integrationResult.Status -eq "Success") {
            Write-TestMessage "Vue intégrée avec succès en mode Merge: $($integrationResult.Message)" -Level "Success"
        }
        else {
            Write-TestMessage "Échec de l'intégration de la vue en mode Merge" -Level "Error"
            return
        }
    }
    catch {
        Write-TestMessage "Erreur lors de l'intégration de la vue en mode Merge: $($_.Exception.Message)" -Level "Error"
        return
    }
    
    Write-TestMessage "Test d'import et d'intégration d'une vue terminé avec succès" -Level "Success"
    
    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Exécuter tous les tests
Write-TestMessage "Démarrage des tests d'intégration du partage des vues RAG" -Level "Info"
$view = Test-RAGConversion
if ($null -ne $view) {
    Test-ViewSharing -View $view
}
Test-ViewImportAndIntegration
Write-TestMessage "Tous les tests d'intégration du partage des vues RAG sont terminés" -Level "Info"
