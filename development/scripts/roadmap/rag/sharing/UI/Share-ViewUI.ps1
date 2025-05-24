<#
.SYNOPSIS
    Interface utilisateur pour le partage des vues RAG.

.DESCRIPTION
    Ce script fournit une interface utilisateur simple pour le partage des vues RAG.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer les modules requis
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$parentDir = Split-Path -Path $scriptDir -Parent
$sharingIntegrationPath = Join-Path -Path $parentDir -ChildPath "SharingIntegration.ps1"

if (Test-Path -Path $sharingIntegrationPath) {
    . $sharingIntegrationPath
}
else {
    throw "Le module SharingIntegration.ps1 est requis mais n'a pas été trouvé à l'emplacement: $sharingIntegrationPath"
}

# Fonction pour afficher un message formaté
function Write-UIMessage {
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
    
    Write-Host $Message -ForegroundColor $colors[$Level]
}

# Fonction pour afficher un menu
function Show-Menu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [string[]]$Options,
        
        [Parameter(Mandatory = $false)]
        [int]$DefaultOption = 0
    )
    
    Clear-Host
    Write-Host "===== $Title =====" -ForegroundColor Cyan
    Write-Host
    
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "[$($i + 1)] $($Options[$i])"
    }
    
    Write-Host
    $selection = Read-Host "Sélectionnez une option (1-$($Options.Count)) [$(($DefaultOption + 1))]"
    
    if ([string]::IsNullOrEmpty($selection)) {
        return $DefaultOption
    }
    
    $selectionInt = 0
    if ([int]::TryParse($selection, [ref]$selectionInt)) {
        if ($selectionInt -ge 1 -and $selectionInt -le $Options.Count) {
            return $selectionInt - 1
        }
    }
    
    return $DefaultOption
}

# Fonction pour créer un exemple de résultat RAG
function New-ExampleRAGResult {
    [CmdletBinding()]
    param()
    
    $now = Get-Date
    
    $ragResult = [PSCustomObject]@{
        Query = "requête d'exemple RAG"
        Timestamp = $now.ToString('o')
        TotalResults = 3
        ProcessingTime = 0.25
        Tags = @("exemple", "rag", "partage")
        Results = @(
            [PSCustomObject]@{
                Title = "Premier résultat d'exemple"
                Content = "Ceci est le contenu du premier résultat d'exemple."
                Source = "Source 1"
                Path = "C:\Data\document1.txt"
                Tags = @("important", "prioritaire")
                Score = 0.95
                Metadata = [PSCustomObject]@{
                    Type = "document"
                    CreatedAt = $now.AddDays(-5).ToString('o')
                }
            },
            [PSCustomObject]@{
                Title = "Deuxième résultat d'exemple"
                Content = "Ceci est le contenu du deuxième résultat d'exemple."
                Source = "Source 2"
                Path = "C:\Data\document2.txt"
                Tags = @("secondaire")
                Score = 0.85
                Metadata = [PSCustomObject]@{
                    Type = "document"
                    CreatedAt = $now.AddDays(-3).ToString('o')
                }
            },
            [PSCustomObject]@{
                Title = "Troisième résultat d'exemple"
                Content = "Ceci est le contenu du troisième résultat d'exemple."
                Source = "Source 3"
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

# Fonction pour afficher les détails d'une vue
function Show-ViewDetails {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$View
    )
    
    Clear-Host
    Write-Host "===== Détails de la vue =====" -ForegroundColor Cyan
    Write-Host
    Write-Host "ID: $($View.Id)" -ForegroundColor Yellow
    Write-Host "Titre: $($View.Title)" -ForegroundColor Yellow
    Write-Host "Type: $($View.Type)" -ForegroundColor Yellow
    Write-Host
    Write-Host "Métadonnées:" -ForegroundColor Cyan
    Write-Host "  Créateur: $($View.Metadata.Creator)"
    Write-Host "  Date de création: $($View.Metadata.CreatedAt)"
    Write-Host "  Description: $($View.Metadata.Description)"
    Write-Host "  Tags: $($View.Metadata.Tags -join ', ')"
    Write-Host "  Requête: $($View.Metadata.Query)"
    Write-Host
    Write-Host "Éléments ($($View.Items.Count)):" -ForegroundColor Cyan
    
    foreach ($item in $View.Items) {
        Write-Host "  - $($item.Title)" -ForegroundColor Green
        Write-Host "    Score: $($item.Score)"
        Write-Host "    Source: $($item.Source)"
        Write-Host "    Tags: $($item.Tags -join ', ')"
        Write-Host "    Contenu: $($item.Content.Substring(0, [Math]::Min(50, $item.Content.Length)))..."
        Write-Host
    }
    
    Write-Host "Appuyez sur une touche pour continuer..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Fonction pour partager une vue
function Publish-ViewUI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$View
    )
    
    Clear-Host
    Write-Host "===== Partager la vue =====" -ForegroundColor Cyan
    Write-Host
    Write-Host "ID: $($View.Id)" -ForegroundColor Yellow
    Write-Host "Titre: $($View.Title)" -ForegroundColor Yellow
    Write-Host
    
    # Sélectionner le format
    $formatOptions = @("JSON", "JSON compact", "URL", "Fichier autonome")
    $formatSelection = Show-Menu -Title "Sélectionnez un format de partage" -Options $formatOptions
    
    $format = switch ($formatSelection) {
        0 { "JSON" }
        1 { "JSON_COMPACT" }
        2 { "URL" }
        3 { "STANDALONE" }
        default { "JSON" }
    }
    
    # Saisir les destinataires
    Clear-Host
    Write-Host "===== Destinataires =====" -ForegroundColor Cyan
    Write-Host
    Write-Host "Entrez les adresses e-mail des destinataires (séparées par des virgules):"
    $recipientsInput = Read-Host
    
    $recipients = $recipientsInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrEmpty($_) }
    
    if ($recipients.Count -eq 0) {
        Write-UIMessage "Aucun destinataire spécifié. Ajout d'un destinataire par défaut." -Level "Warning"
        $recipients = @("user@example.com")
    }
    
    # Sélectionner les permissions
    $permissionOptions = @(
        "Lecture de base (métadonnées uniquement)",
        "Lecture standard (contenu complet)",
        "Lecture étendue (historique et versions)",
        "Écriture de commentaires",
        "Modification du contenu",
        "Modification de la structure",
        "Partage avec d'autres utilisateurs",
        "Gestion des permissions",
        "Transfert de propriété"
    )
    
    $permissionValues = @(
        "READ_BASIC",
        "READ_STANDARD",
        "READ_EXTENDED",
        "WRITE_COMMENT",
        "WRITE_CONTENT",
        "WRITE_STRUCTURE",
        "ADMIN_SHARE",
        "ADMIN_PERMISSIONS",
        "ADMIN_OWNERSHIP"
    )
    
    Clear-Host
    Write-Host "===== Permissions =====" -ForegroundColor Cyan
    Write-Host
    Write-Host "Sélectionnez les permissions à accorder (séparées par des virgules):"
    
    for ($i = 0; $i -lt $permissionOptions.Count; $i++) {
        Write-Host "[$($i + 1)] $($permissionOptions[$i])"
    }
    
    Write-Host
    $permissionsInput = Read-Host "Entrez les numéros des permissions (par défaut: 2)"
    
    $selectedPermissions = @()
    
    if ([string]::IsNullOrEmpty($permissionsInput)) {
        $selectedPermissions = @("READ_STANDARD")
    }
    else {
        $permissionIndices = $permissionsInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrEmpty($_) }
        
        foreach ($index in $permissionIndices) {
            $indexInt = 0
            if ([int]::TryParse($index, [ref]$indexInt)) {
                if ($indexInt -ge 1 -and $indexInt -le $permissionValues.Count) {
                    $selectedPermissions += $permissionValues[$indexInt - 1]
                }
            }
        }
        
        if ($selectedPermissions.Count -eq 0) {
            Write-UIMessage "Aucune permission valide spécifiée. Utilisation de la permission par défaut." -Level "Warning"
            $selectedPermissions = @("READ_STANDARD")
        }
    }
    
    # Partager la vue
    Clear-Host
    Write-Host "===== Partage en cours =====" -ForegroundColor Cyan
    Write-Host
    Write-Host "Format: $format"
    Write-Host "Destinataires: $($recipients -join ', ')"
    Write-Host "Permissions: $($selectedPermissions -join ', ')"
    Write-Host
    
    try {
        $shareResult = Share-RAGView -View $View -Format $format -Recipients $recipients -Permissions $selectedPermissions -EnableDebug
        
        if ($null -ne $shareResult -and $shareResult.ContainsKey("ExportPath")) {
            Write-UIMessage "Vue partagée avec succès!" -Level "Success"
            Write-UIMessage "Fichier d'export: $($shareResult.ExportPath)" -Level "Success"
        }
        else {
            Write-UIMessage "Échec du partage de la vue." -Level "Error"
        }
    }
    catch {
        Write-UIMessage "Erreur lors du partage de la vue: $($_.Exception.Message)" -Level "Error"
    }
    
    Write-Host
    Write-Host "Appuyez sur une touche pour continuer..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Fonction pour importer une vue
function Import-ViewUI {
    [CmdletBinding()]
    param()
    
    Clear-Host
    Write-Host "===== Importer une vue =====" -ForegroundColor Cyan
    Write-Host
    
    # Sélectionner le fichier
    Write-Host "Entrez le chemin du fichier à importer:"
    $filePath = Read-Host
    
    if (-not (Test-Path -Path $filePath)) {
        Write-UIMessage "Le fichier n'existe pas: $filePath" -Level "Error"
        Write-Host "Appuyez sur une touche pour continuer..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return $null
    }
    
    # Demander un mot de passe si nécessaire
    $password = $null
    $fileExtension = [System.IO.Path]::GetExtension($filePath).ToLower()
    
    if ($fileExtension -eq ".enc" -or $fileExtension -eq ".encrypted") {
        Write-Host "Le fichier semble être chiffré. Entrez le mot de passe:"
        $passwordSecure = Read-Host -AsSecureString
        $password = $passwordSecure
    }
    
    # Importer la vue
    Clear-Host
    Write-Host "===== Import en cours =====" -ForegroundColor Cyan
    Write-Host
    
    try {
        $importedView = Import-SharedView -Path $filePath -Password $password -EnableDebug
        
        if ($null -ne $importedView) {
            Write-UIMessage "Vue importée avec succès!" -Level "Success"
            Write-UIMessage "ID: $($importedView.Id)" -Level "Success"
            Write-UIMessage "Titre: $($importedView.Title)" -Level "Success"
            
            # Intégrer la vue
            $integrationOptions = @("Ajouter aux résultats existants", "Remplacer les résultats existants", "Fusionner avec les résultats existants", "Ne pas intégrer")
            $integrationSelection = Show-Menu -Title "Comment souhaitez-vous intégrer cette vue?" -Options $integrationOptions
            
            if ($integrationSelection -lt 3) {
                $integrationMode = switch ($integrationSelection) {
                    0 { "Append" }
                    1 { "Replace" }
                    2 { "Merge" }
                    default { "Append" }
                }
                
                $integrationResult = Integrate-ImportedView -View $importedView -IntegrationMode $integrationMode -EnableDebug
                
                if ($null -ne $integrationResult -and $integrationResult.Status -eq "Success") {
                    Write-UIMessage "Vue intégrée avec succès: $($integrationResult.Message)" -Level "Success"
                }
                else {
                    Write-UIMessage "Échec de l'intégration de la vue." -Level "Error"
                }
            }
            
            return $importedView
        }
        else {
            Write-UIMessage "Échec de l'import de la vue." -Level "Error"
        }
    }
    catch {
        Write-UIMessage "Erreur lors de l'import de la vue: $($_.Exception.Message)" -Level "Error"
    }
    
    Write-Host
    Write-Host "Appuyez sur une touche pour continuer..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    return $null
}

# Fonction principale
function Start-SharingUI {
    [CmdletBinding()]
    param()
    
    $currentView = $null
    
    while ($true) {
        $options = @(
            "Créer une vue d'exemple",
            "Afficher les détails de la vue",
            "Partager la vue",
            "Importer une vue",
            "Quitter"
        )
        
        $selection = Show-Menu -Title "Partage des vues RAG" -Options $options
        
        switch ($selection) {
            0 {
                # Créer une vue d'exemple
                $ragResult = New-ExampleRAGResult
                $currentView = ConvertTo-ShareableView -RAGResult $ragResult -Title "Vue d'exemple" -Description "Vue créée pour tester le partage" -EnableDebug
                Write-UIMessage "Vue d'exemple créée avec l'ID: $($currentView.Id)" -Level "Success"
                Write-Host "Appuyez sur une touche pour continuer..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            1 {
                # Afficher les détails de la vue
                if ($null -eq $currentView) {
                    Write-UIMessage "Aucune vue n'est actuellement chargée. Créez ou importez une vue d'abord." -Level "Warning"
                    Write-Host "Appuyez sur une touche pour continuer..."
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                }
                else {
                    Show-ViewDetails -View $currentView
                }
            }
            2 {
                # Partager la vue
                if ($null -eq $currentView) {
                    Write-UIMessage "Aucune vue n'est actuellement chargée. Créez ou importez une vue d'abord." -Level "Warning"
                    Write-Host "Appuyez sur une touche pour continuer..."
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                }
                else {
                    Publish-ViewUI -View $currentView
                }
            }
            3 {
                # Importer une vue
                $importedView = Import-ViewUI
                if ($null -ne $importedView) {
                    $currentView = $importedView
                }
            }
            4 {
                # Quitter
                return
            }
        }
    }
}

# Exécuter l'interface utilisateur
Start-SharingUI

