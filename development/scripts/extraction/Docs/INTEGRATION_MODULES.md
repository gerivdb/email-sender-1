# Intégration du module ExtractedInfoModuleV2 avec d'autres modules

Ce document explique comment intégrer le module ExtractedInfoModuleV2 avec d'autres modules PowerShell pour créer des solutions complètes d'extraction et de traitement d'informations.

## Scénarios d'intégration courants

### 1. Extraction et traitement de données

Le module ExtractedInfoModuleV2 peut être utilisé en conjonction avec des modules d'extraction de données pour créer un pipeline complet de traitement :

```powershell
# Importer les modules

Import-Module WebScrapingModule
Import-Module ExtractedInfoModuleV2
Import-Module DataProcessingModule

# Extraire des données du web

$webData = Get-WebContent -Url "https://example.com/data"

# Convertir en objets d'information extraite

$extractedInfo = New-TextExtractedInfo -Source "https://example.com/data" -Text $webData -Language "fr"

# Enrichir l'information extraite

$extractedInfo = Add-ExtractedInfoMetadata -Info $extractedInfo -Metadata @{
    Timestamp = Get-Date
    Category = "Web"
}

# Traiter les données

$processedData = Convert-ExtractedInfoToProcessedData -Info $extractedInfo
```plaintext
### 2. Stockage et récupération d'informations

Le module peut être intégré avec des systèmes de stockage pour persister les informations extraites :

```powershell
# Importer les modules

Import-Module ExtractedInfoModuleV2
Import-Module DatabaseModule

# Créer une connexion à la base de données

$connection = New-DatabaseConnection -Server "localhost" -Database "ExtractedInfo"

# Stocker l'information extraite

$info = New-TextExtractedInfo -Source "document.txt" -Text "Contenu du document" -Language "fr"
Save-ExtractedInfoToDatabase -Info $info -Connection $connection -Table "TextInfo"

# Récupérer l'information extraite

$retrievedInfo = Get-ExtractedInfoFromDatabase -Connection $connection -Table "TextInfo" -Id $info.Id
```plaintext
### 3. Analyse et reporting

Le module peut être utilisé avec des outils d'analyse et de reporting :

```powershell
# Importer les modules

Import-Module ExtractedInfoModuleV2
Import-Module ReportingModule

# Créer une collection d'informations extraites

$collection = New-ExtractedInfoCollection -Name "Données à analyser"

# Ajouter des informations à la collection

1..10 | ForEach-Object {
    $info = New-TextExtractedInfo -Source "document$_.txt" -Text "Contenu $_ du document" -Language "fr"
    $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info
}

# Analyser les informations

$statistics = Get-ExtractedInfoStatistics -Collection $collection

# Générer un rapport

$report = New-StatisticsReport -Statistics $statistics -Format "HTML"
```plaintext
### 4. Traitement par lots

Le module peut être intégré dans des workflows de traitement par lots :

```powershell
# Importer les modules

Import-Module ExtractedInfoModuleV2
Import-Module BatchProcessingModule

# Définir une fonction de traitement

function Process-File {
    param($FilePath)
    
    $content = Get-Content -Path $FilePath -Raw
    $info = New-TextExtractedInfo -Source $FilePath -Text $content -Language "fr"
    return $info
}

# Traiter un lot de fichiers

$batchResult = Invoke-BatchProcessing -InputFolder "C:\Data\Input" -ProcessFunction ${function:Process-File} -MaxParallelism 4

# Exporter les résultats

$batchResult | ForEach-Object {
    Export-ExtractedInfo -Info $_ -Format "Json" -OutputPath "C:\Data\Output\$($_.Id).json"
}
```plaintext
## Importation et exportation de données

### Importation de données externes

Le module ExtractedInfoModuleV2 fournit plusieurs méthodes pour importer des données externes et les convertir en objets d'information extraite :

```powershell
# Importer depuis un fichier texte

$textContent = Get-Content -Path "document.txt" -Raw
$textInfo = New-TextExtractedInfo -Source "document.txt" -Text $textContent -Language "fr"

# Importer depuis un fichier JSON

$jsonContent = Get-Content -Path "data.json" -Raw | ConvertFrom-Json
$structuredInfo = New-StructuredDataExtractedInfo -Source "data.json" -Data $jsonContent -DataFormat "Json"

# Importer depuis un fichier CSV

$csvData = Import-Csv -Path "data.csv"
$structuredInfo = New-StructuredDataExtractedInfo -Source "data.csv" -Data $csvData -DataFormat "Csv"

# Importer depuis une base de données

$queryResult = Invoke-SqlQuery -Query "SELECT * FROM Products" -Connection $dbConnection
$structuredInfo = New-StructuredDataExtractedInfo -Source "database:Products" -Data $queryResult -DataFormat "DataTable"
```plaintext
### Exportation de données

Le module permet d'exporter les objets d'information extraite dans différents formats :

```powershell
# Exporter en JSON

$jsonOutput = Export-ExtractedInfo -Info $extractedInfo -Format "Json"
$jsonOutput | Out-File -FilePath "output.json"

# Exporter en XML

$xmlOutput = Export-ExtractedInfo -Info $extractedInfo -Format "Xml"
$xmlOutput | Out-File -FilePath "output.xml"

# Exporter en CSV (pour les données structurées)

if ($extractedInfo._Type -eq "StructuredDataExtractedInfo" -and $extractedInfo.DataFormat -eq "Hashtable") {
    $extractedInfo.Data | Export-Csv -Path "output.csv" -NoTypeInformation
}

# Exporter vers une base de données

$properties = @{
    Id = $extractedInfo.Id
    Type = $extractedInfo._Type
    Source = $extractedInfo.Source
    Content = ($extractedInfo | ConvertTo-Json -Depth 10)
    CreatedAt = Get-Date
}
Add-SqlTableRow -Table "ExtractedInfo" -Properties $properties -Connection $dbConnection
```plaintext
## Gestion des dépendances

### Dépendances du module

Le module ExtractedInfoModuleV2 a été conçu pour minimiser les dépendances externes. Cependant, certaines fonctionnalités peuvent nécessiter des modules supplémentaires :

- **Aucune dépendance obligatoire** : Le module fonctionne de manière autonome pour les fonctionnalités de base.
- **Dépendances optionnelles** :
  - `PSFramework` : Pour la journalisation avancée et la gestion de la configuration
  - `ImportExcel` : Pour l'exportation vers Excel
  - `SqlServer` : Pour l'intégration avec SQL Server

### Vérification des dépendances

Vous pouvez vérifier et installer les dépendances nécessaires avec le code suivant :

```powershell
function Test-ModuleDependency {
    param(
        [string]$ModuleName,
        [switch]$Install
    )
    
    $moduleInstalled = Get-Module -Name $ModuleName -ListAvailable
    
    if (-not $moduleInstalled) {
        Write-Warning "Le module $ModuleName n'est pas installé."
        if ($Install) {
            Write-Host "Installation du module $ModuleName..."
            Install-Module -Name $ModuleName -Scope CurrentUser -Force
            return $true
        }
        return $false
    }
    
    return $true
}

# Vérifier les dépendances optionnelles

$dependencies = @("PSFramework", "ImportExcel", "SqlServer")
foreach ($dependency in $dependencies) {
    Test-ModuleDependency -ModuleName $dependency -Install
}
```plaintext
### Gestion des versions

Le module ExtractedInfoModuleV2 utilise le versionnement sémantique (SemVer) pour gérer les versions. Assurez-vous d'utiliser une version compatible lors de l'intégration :

```powershell
function Test-ModuleVersion {
    param(
        [string]$ModuleName,
        [string]$MinimumVersion
    )
    
    $module = Get-Module -Name $ModuleName -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
    
    if (-not $module) {
        Write-Warning "Le module $ModuleName n'est pas installé."
        return $false
    }
    
    if ($module.Version -lt [version]$MinimumVersion) {
        Write-Warning "Le module $ModuleName version $($module.Version) est installé, mais la version minimum requise est $MinimumVersion."
        return $false
    }
    
    Write-Host "Le module $ModuleName version $($module.Version) est compatible."
    return $true
}

# Vérifier la version du module

Test-ModuleVersion -ModuleName "ExtractedInfoModuleV2" -MinimumVersion "2.0.0"
```plaintext
## Bonnes pratiques d'intégration

### 1. Utiliser des pipelines PowerShell

Tirez parti des pipelines PowerShell pour créer des flux de traitement efficaces :

```powershell
# Exemple de pipeline de traitement

Get-ChildItem -Path "C:\Data\Input" -Filter "*.txt" |
    ForEach-Object {
        $content = Get-Content -Path $_.FullName -Raw
        New-TextExtractedInfo -Source $_.Name -Text $content -Language "fr"
    } |
    Where-Object { $_.Text.Length -gt 100 } |
    ForEach-Object {
        $_ = Add-ExtractedInfoMetadata -Info $_ -Metadata @{
            ProcessedAt = Get-Date
            FileSize = (Get-Item -Path "C:\Data\Input\$($_.Source)").Length
        }
        $_
    } |
    Export-ExtractedInfo -Format "Json" |
    Out-File -FilePath "C:\Data\Output\combined_result.json"
```plaintext
### 2. Utiliser des collections pour les opérations groupées

Les collections d'informations extraites permettent de gérer efficacement de grands ensembles de données :

```powershell
# Créer une collection

$collection = New-ExtractedInfoCollection -Name "Documents traités"

# Ajouter des informations à la collection

Get-ChildItem -Path "C:\Data\Input" -Filter "*.txt" | ForEach-Object {
    $content = Get-Content -Path $_.FullName -Raw
    $info = New-TextExtractedInfo -Source $_.Name -Text $content -Language "fr"
    $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info
}

# Traiter la collection en une seule opération

$processedCollection = Process-ExtractedInfoCollection -Collection $collection -ProcessFunction {
    param($Info)
    # Traitement personnalisé

    return $Info
}

# Exporter la collection

$processedCollection | Export-ExtractedInfoCollection -OutputPath "C:\Data\Output\collection.json"
```plaintext
### 3. Gérer les erreurs de manière appropriée

Implémentez une gestion robuste des erreurs lors de l'intégration du module :

```powershell
function Process-FileWithErrorHandling {
    param(
        [string]$FilePath
    )
    
    try {
        $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        $info = New-TextExtractedInfo -Source $FilePath -Text $content -Language "fr"
        return @{
            Success = $true
            Result = $info
            Error = $null
        }
    }
    catch {
        Write-Warning "Erreur lors du traitement du fichier $FilePath : $_"
        return @{
            Success = $false
            Result = $null
            Error = $_
        }
    }
}

# Traiter les fichiers avec gestion des erreurs

$results = Get-ChildItem -Path "C:\Data\Input" -Filter "*.txt" | ForEach-Object {
    Process-FileWithErrorHandling -FilePath $_.FullName
}

# Séparer les succès et les échecs

$successes = $results | Where-Object { $_.Success }
$failures = $results | Where-Object { -not $_.Success }

# Journaliser les échecs

$failures | ForEach-Object {
    Write-Log -Message "Échec du traitement : $($_.Error.Message)" -Level Error -File "C:\Logs\processing.log"
}
```plaintext
### 4. Optimiser les performances

Utilisez les fonctionnalités de parallélisation pour améliorer les performances :

```powershell
# Traitement parallèle avec ForEach-Object -Parallel (PowerShell 7+)

$results = Get-ChildItem -Path "C:\Data\Input" -Filter "*.txt" | ForEach-Object -Parallel {
    # Importer le module dans chaque thread

    Import-Module ExtractedInfoModuleV2
    
    $content = Get-Content -Path $_.FullName -Raw
    $info = New-TextExtractedInfo -Source $_.Name -Text $content -Language "fr"
    
    # Retourner le résultat

    $info
} -ThrottleLimit 8

# Utiliser des runspaces pour PowerShell 5.1

$runspacePool = [runspacefactory]::CreateRunspacePool(1, 8)
$runspacePool.Open()

$runspaces = @()
Get-ChildItem -Path "C:\Data\Input" -Filter "*.txt" | ForEach-Object {
    $powershell = [powershell]::Create()
    $powershell.RunspacePool = $runspacePool
    
    # Ajouter le script à exécuter

    [void]$powershell.AddScript({
        param($FilePath, $ModulePath)
        
        # Importer le module

        Import-Module $ModulePath
        
        # Traiter le fichier

        $content = Get-Content -Path $FilePath -Raw
        $info = New-TextExtractedInfo -Source (Split-Path -Leaf $FilePath) -Text $content -Language "fr"
        
        # Retourner le résultat

        $info
    })
    
    # Ajouter les paramètres

    [void]$powershell.AddArgument($_.FullName)
    [void]$powershell.AddArgument((Get-Module ExtractedInfoModuleV2).Path)
    
    # Démarrer l'exécution asynchrone

    $runspaces += @{
        PowerShell = $powershell
        Handle = $powershell.BeginInvoke()
        File = $_.FullName
    }
}

# Récupérer les résultats

$results = @()
foreach ($runspace in $runspaces) {
    $results += $runspace.PowerShell.EndInvoke($runspace.Handle)
    $runspace.PowerShell.Dispose()
}

# Fermer le pool de runspaces

$runspacePool.Close()
$runspacePool.Dispose()
```plaintext
Ces bonnes pratiques vous aideront à intégrer efficacement le module ExtractedInfoModuleV2 dans vos solutions PowerShell.
