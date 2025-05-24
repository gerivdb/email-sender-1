# Measure-CriticalFunctionPerformance.ps1
# Script pour mesurer les performances des fonctions critiques du module ExtractedInfoModuleV2

# Définir les couleurs pour les messages
$infoColor = "Cyan"
$successColor = "Green"
$warningColor = "Yellow"
$errorColor = "Red"

# Définir le chemin du répertoire des résultats
$resultsDir = Join-Path -Path $PSScriptRoot -ChildPath "Results"
$performanceDir = Join-Path -Path $resultsDir -ChildPath "Performance"

# Créer le répertoire des résultats de performance s'il n'existe pas
if (-not (Test-Path -Path $performanceDir)) {
    New-Item -Path $performanceDir -ItemType Directory -Force | Out-Null
}

# Définir le fichier de résultats de performance
$performanceFile = Join-Path -Path $performanceDir -ChildPath "CriticalFunctions_Performance.md"

# Initialiser le fichier de résultats de performance
Set-Content -Path $performanceFile -Value "# Mesure des performances des fonctions critiques du module ExtractedInfoModuleV2`r`n"
Add-Content -Path $performanceFile -Value "Date de mesure : $(Get-Date)`r`n"
Add-Content -Path $performanceFile -Value "Ce document présente les résultats des mesures de performance des fonctions critiques du module ExtractedInfoModuleV2.`r`n"

# Fonction pour mesurer les performances d'une fonction
function Measure-FunctionPerformance {
    param (
        [string]$FunctionName,
        [scriptblock]$TestScript,
        [int]$Iterations = 100,
        [string]$Description = "",
        [hashtable]$Parameters = @{}
    )
    
    Write-Host "Mesure des performances de la fonction : $FunctionName" -ForegroundColor $infoColor
    
    # Préparer les résultats
    $results = @{
        FunctionName = $FunctionName
        Description = $Description
        Iterations = $Iterations
        Parameters = $Parameters
        TotalMilliseconds = 0
        AverageMilliseconds = 0
        MinMilliseconds = [double]::MaxValue
        MaxMilliseconds = 0
        MemoryUsageBefore = 0
        MemoryUsageAfter = 0
        MemoryDifference = 0
        Success = $true
        Error = $null
    }
    
    try {
        # Mesurer l'utilisation de la mémoire avant
        [System.GC]::Collect()
        Start-Sleep -Milliseconds 500
        $memoryBefore = [System.GC]::GetTotalMemory($true)
        $results.MemoryUsageBefore = $memoryBefore
        
        # Mesurer le temps d'exécution
        $measurements = @()
        
        for ($i = 1; $i -le $Iterations; $i++) {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            try {
                # Exécuter le script de test
                $null = & $TestScript
                
                # Arrêter le chronomètre
                $stopwatch.Stop()
                $milliseconds = $stopwatch.Elapsed.TotalMilliseconds
                $measurements += $milliseconds
                
                # Mettre à jour les statistiques
                $results.TotalMilliseconds += $milliseconds
                
                if ($milliseconds -lt $results.MinMilliseconds) {
                    $results.MinMilliseconds = $milliseconds
                }
                
                if ($milliseconds -gt $results.MaxMilliseconds) {
                    $results.MaxMilliseconds = $milliseconds
                }
                
                # Afficher la progression
                if ($i % 10 -eq 0 -or $i -eq $Iterations) {
                    Write-Progress -Activity "Mesure des performances de $FunctionName" -Status "Itération $i/$Iterations" -PercentComplete (($i / $Iterations) * 100)
                }
            }
            catch {
                Write-Host "  [ERREUR] Itération $i : $_" -ForegroundColor $errorColor
                $results.Success = $false
                $results.Error = $_
                break
            }
        }
        
        # Mesurer l'utilisation de la mémoire après
        [System.GC]::Collect()
        Start-Sleep -Milliseconds 500
        $memoryAfter = [System.GC]::GetTotalMemory($true)
        $results.MemoryUsageAfter = $memoryAfter
        $results.MemoryDifference = $memoryAfter - $memoryBefore
        
        # Calculer la moyenne
        if ($measurements.Count -gt 0) {
            $results.AverageMilliseconds = $results.TotalMilliseconds / $measurements.Count
        }
        
        # Afficher les résultats
        Write-Host "  Temps total : $($results.TotalMilliseconds) ms" -ForegroundColor $infoColor
        Write-Host "  Temps moyen : $($results.AverageMilliseconds) ms" -ForegroundColor $infoColor
        Write-Host "  Temps min : $($results.MinMilliseconds) ms" -ForegroundColor $infoColor
        Write-Host "  Temps max : $($results.MaxMilliseconds) ms" -ForegroundColor $infoColor
        Write-Host "  Différence de mémoire : $($results.MemoryDifference) octets" -ForegroundColor $infoColor
        
        if ($results.Success) {
            Write-Host "  [SUCCÈS] Mesure des performances terminée" -ForegroundColor $successColor
        }
        else {
            Write-Host "  [ÉCHEC] Mesure des performances échouée : $($results.Error)" -ForegroundColor $errorColor
        }
    }
    catch {
        Write-Host "  [ERREUR] Mesure des performances échouée : $_" -ForegroundColor $errorColor
        $results.Success = $false
        $results.Error = $_
    }
    
    return $results
}

# Fonction pour documenter les résultats de performance
function Write-PerformanceResults {
    param (
        [hashtable]$Results,
        [string]$PerformanceFile
    )
    
    Add-Content -Path $PerformanceFile -Value "## $($Results.FunctionName)`r`n"
    
    if (-not [string]::IsNullOrEmpty($Results.Description)) {
        Add-Content -Path $PerformanceFile -Value "$($Results.Description)`r`n"
    }
    
    Add-Content -Path $PerformanceFile -Value "### Paramètres de test`r`n"
    Add-Content -Path $PerformanceFile -Value "- Nombre d'itérations : $($Results.Iterations)"
    
    if ($Results.Parameters.Count -gt 0) {
        Add-Content -Path $PerformanceFile -Value "- Paramètres :"
        foreach ($param in $Results.Parameters.GetEnumerator()) {
            Add-Content -Path $PerformanceFile -Value "  - $($param.Key) : $($param.Value)"
        }
    }
    
    Add-Content -Path $PerformanceFile -Value "`r`n### Résultats`r`n"
    Add-Content -Path $PerformanceFile -Value "| Métrique | Valeur |"
    Add-Content -Path $PerformanceFile -Value "|---------|--------|"
    Add-Content -Path $PerformanceFile -Value "| Temps total | $($Results.TotalMilliseconds) ms |"
    Add-Content -Path $PerformanceFile -Value "| Temps moyen | $($Results.AverageMilliseconds) ms |"
    Add-Content -Path $PerformanceFile -Value "| Temps minimum | $($Results.MinMilliseconds) ms |"
    Add-Content -Path $PerformanceFile -Value "| Temps maximum | $($Results.MaxMilliseconds) ms |"
    Add-Content -Path $PerformanceFile -Value "| Utilisation mémoire avant | $($Results.MemoryUsageBefore) octets |"
    Add-Content -Path $PerformanceFile -Value "| Utilisation mémoire après | $($Results.MemoryUsageAfter) octets |"
    Add-Content -Path $PerformanceFile -Value "| Différence mémoire | $($Results.MemoryDifference) octets |"
    Add-Content -Path $PerformanceFile -Value "| Statut | $($Results.Success ? 'SUCCÈS' : 'ÉCHEC') |"
    
    if (-not $Results.Success) {
        Add-Content -Path $PerformanceFile -Value "`r`n### Erreur`r`n"
        Add-Content -Path $PerformanceFile -Value "```"
        Add-Content -Path $PerformanceFile -Value $Results.Error
        Add-Content -Path $PerformanceFile -Value "```"
    }
    
    Add-Content -Path $PerformanceFile -Value "`r`n---`r`n"
}

# Importer le module ExtractedInfoModuleV2
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ExtractedInfoModuleV2.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module -Name $modulePath -Force
    Write-Host "Module ExtractedInfoModuleV2 importé avec succès" -ForegroundColor $successColor
}
else {
    Write-Host "Impossible de trouver le module ExtractedInfoModuleV2 : $modulePath" -ForegroundColor $errorColor
    exit 1
}

# Définir les fonctions critiques à mesurer
$criticalFunctions = @(
    @{
        Name = "New-ExtractedInfo"
        Description = "Création d'une nouvelle information extraite de base"
        Script = {
            $info = New-ExtractedInfo -Source "Test" -ExtractorName "PerformanceTest"
        }
        Iterations = 1000
        Parameters = @{
            Source = "Test"
            ExtractorName = "PerformanceTest"
        }
    },
    @{
        Name = "New-TextExtractedInfo"
        Description = "Création d'une nouvelle information extraite de type texte"
        Script = {
            $info = New-TextExtractedInfo -Source "Test" -ExtractorName "PerformanceTest" -Text "Ceci est un texte de test pour la mesure des performances" -Language "fr"
        }
        Iterations = 1000
        Parameters = @{
            Source = "Test"
            ExtractorName = "PerformanceTest"
            TextLength = 58
            Language = "fr"
        }
    },
    @{
        Name = "Add-ExtractedInfoMetadata"
        Description = "Ajout de métadonnées à une information extraite"
        Script = {
            $info = New-ExtractedInfo -Source "Test" -ExtractorName "PerformanceTest"
            $info = Add-ExtractedInfoMetadata -Info $info -Key "TestKey" -Value "TestValue"
        }
        Iterations = 1000
        Parameters = @{
            MetadataCount = 1
        }
    },
    @{
        Name = "New-ExtractedInfoCollection"
        Description = "Création d'une nouvelle collection d'informations extraites"
        Script = {
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
        }
        Iterations = 1000
        Parameters = @{
            Name = "TestCollection"
        }
    },
    @{
        Name = "Add-ExtractedInfoToCollection (petit)"
        Description = "Ajout d'une information extraite à une petite collection (10 éléments)"
        Script = {
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            for ($i = 0; $i -lt 10; $i++) {
                $info = New-ExtractedInfo -Source "Test$i" -ExtractorName "PerformanceTest"
                $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info
            }
        }
        Iterations = 100
        Parameters = @{
            CollectionSize = 10
        }
    },
    @{
        Name = "Add-ExtractedInfoToCollection (moyen)"
        Description = "Ajout d'une information extraite à une collection moyenne (100 éléments)"
        Script = {
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            for ($i = 0; $i -lt 100; $i++) {
                $info = New-ExtractedInfo -Source "Test$i" -ExtractorName "PerformanceTest"
                $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info
            }
        }
        Iterations = 10
        Parameters = @{
            CollectionSize = 100
        }
    },
    @{
        Name = "Get-ExtractedInfoFromCollection (petit)"
        Description = "Récupération d'informations extraites d'une petite collection (10 éléments)"
        Script = {
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            for ($i = 0; $i -lt 10; $i++) {
                $info = New-ExtractedInfo -Source "Test$i" -ExtractorName "PerformanceTest"
                $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info
            }
            $items = Get-ExtractedInfoFromCollection -Collection $collection
        }
        Iterations = 100
        Parameters = @{
            CollectionSize = 10
        }
    },
    @{
        Name = "Get-ExtractedInfoFromCollection (moyen)"
        Description = "Récupération d'informations extraites d'une collection moyenne (100 éléments)"
        Script = {
            $collection = New-ExtractedInfoCollection -Name "TestCollection"
            for ($i = 0; $i -lt 100; $i++) {
                $info = New-ExtractedInfo -Source "Test$i" -ExtractorName "PerformanceTest"
                $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info
            }
            $items = Get-ExtractedInfoFromCollection -Collection $collection
        }
        Iterations = 10
        Parameters = @{
            CollectionSize = 100
        }
    },
    @{
        Name = "Test-ExtractedInfo"
        Description = "Validation d'une information extraite"
        Script = {
            $info = New-ExtractedInfo -Source "Test" -ExtractorName "PerformanceTest"
            $valid = Test-ExtractedInfo -Info $info
        }
        Iterations = 1000
        Parameters = @{
            ValidInfo = $true
        }
    },
    @{
        Name = "ConvertTo-ExtractedInfoJson (simple)"
        Description = "Conversion d'une information extraite simple en JSON"
        Script = {
            $info = New-ExtractedInfo -Source "Test" -ExtractorName "PerformanceTest"
            $json = ConvertTo-ExtractedInfoJson -InputObject $info
        }
        Iterations = 1000
        Parameters = @{
            ObjectType = "Simple"
            Depth = 5
        }
    },
    @{
        Name = "ConvertTo-ExtractedInfoJson (complexe)"
        Description = "Conversion d'une information extraite complexe en JSON"
        Script = {
            $info = New-TextExtractedInfo -Source "Test" -ExtractorName "PerformanceTest" -Text "Ceci est un texte de test pour la mesure des performances" -Language "fr"
            $info = Add-ExtractedInfoMetadata -Info $info -Key "TestKey1" -Value "TestValue1"
            $info = Add-ExtractedInfoMetadata -Info $info -Key "TestKey2" -Value "TestValue2"
            $info = Add-ExtractedInfoMetadata -Info $info -Key "TestKey3" -Value @{ SubKey1 = "SubValue1"; SubKey2 = "SubValue2" }
            $json = ConvertTo-ExtractedInfoJson -InputObject $info
        }
        Iterations = 1000
        Parameters = @{
            ObjectType = "Complexe"
            Depth = 5
            MetadataCount = 3
        }
    },
    @{
        Name = "ConvertFrom-ExtractedInfoJson (simple)"
        Description = "Conversion d'un JSON en information extraite simple"
        Script = {
            $info = New-ExtractedInfo -Source "Test" -ExtractorName "PerformanceTest"
            $json = ConvertTo-ExtractedInfoJson -InputObject $info
            $infoFromJson = ConvertFrom-ExtractedInfoJson -Json $json
        }
        Iterations = 1000
        Parameters = @{
            ObjectType = "Simple"
        }
    },
    @{
        Name = "ConvertFrom-ExtractedInfoJson (complexe)"
        Description = "Conversion d'un JSON en information extraite complexe"
        Script = {
            $info = New-TextExtractedInfo -Source "Test" -ExtractorName "PerformanceTest" -Text "Ceci est un texte de test pour la mesure des performances" -Language "fr"
            $info = Add-ExtractedInfoMetadata -Info $info -Key "TestKey1" -Value "TestValue1"
            $info = Add-ExtractedInfoMetadata -Info $info -Key "TestKey2" -Value "TestValue2"
            $info = Add-ExtractedInfoMetadata -Info $info -Key "TestKey3" -Value @{ SubKey1 = "SubValue1"; SubKey2 = "SubValue2" }
            $json = ConvertTo-ExtractedInfoJson -InputObject $info
            $infoFromJson = ConvertFrom-ExtractedInfoJson -Json $json
        }
        Iterations = 1000
        Parameters = @{
            ObjectType = "Complexe"
            MetadataCount = 3
        }
    }
)

# Mesurer les performances des fonctions critiques
$allResults = @()

foreach ($function in $criticalFunctions) {
    $results = Measure-FunctionPerformance -FunctionName $function.Name -TestScript $function.Script -Iterations $function.Iterations -Description $function.Description -Parameters $function.Parameters
    $allResults += $results
    Write-PerformanceResults -Results $results -PerformanceFile $performanceFile
}

# Ajouter un résumé des résultats
Add-Content -Path $performanceFile -Value "## Résumé des performances`r`n"
Add-Content -Path $performanceFile -Value "| Fonction | Temps moyen (ms) | Différence mémoire (octets) | Statut |"
Add-Content -Path $performanceFile -Value "|---------|-----------------|---------------------------|--------|"

foreach ($result in $allResults) {
    Add-Content -Path $performanceFile -Value "| $($result.FunctionName) | $($result.AverageMilliseconds) | $($result.MemoryDifference) | $($result.Success ? 'SUCCÈS' : 'ÉCHEC') |"
}

# Ajouter des recommandations
Add-Content -Path $performanceFile -Value "`r`n## Recommandations`r`n"
Add-Content -Path $performanceFile -Value "Sur la base des mesures de performance, voici quelques recommandations pour améliorer les performances du module ExtractedInfoModuleV2 :"

# Identifier les fonctions les plus lentes
$slowestFunctions = $allResults | Sort-Object -Property AverageMilliseconds -Descending | Select-Object -First 3
Add-Content -Path $performanceFile -Value "`r`n### Fonctions les plus lentes`r`n"
foreach ($function in $slowestFunctions) {
    Add-Content -Path $performanceFile -Value "- **$($function.FunctionName)** : $($function.AverageMilliseconds) ms en moyenne"
}
Add-Content -Path $performanceFile -Value "`r`nCes fonctions pourraient bénéficier d'optimisations pour améliorer leurs performances."

# Identifier les fonctions consommant le plus de mémoire
$memoryHungryFunctions = $allResults | Sort-Object -Property MemoryDifference -Descending | Select-Object -First 3
Add-Content -Path $performanceFile -Value "`r`n### Fonctions consommant le plus de mémoire`r`n"
foreach ($function in $memoryHungryFunctions) {
    Add-Content -Path $performanceFile -Value "- **$($function.FunctionName)** : $($function.MemoryDifference) octets"
}
Add-Content -Path $performanceFile -Value "`r`nCes fonctions pourraient bénéficier d'optimisations pour réduire leur consommation de mémoire."

# Ajouter des recommandations générales
Add-Content -Path $performanceFile -Value "`r`n### Recommandations générales`r`n"
Add-Content -Path $performanceFile -Value "1. **Optimiser les collections volumineuses** : Les opérations sur les collections volumineuses sont parmi les plus lentes. Envisager l'utilisation de structures de données plus efficaces ou de techniques de traitement par lots."
Add-Content -Path $performanceFile -Value "2. **Réduire la consommation de mémoire** : Certaines fonctions consomment beaucoup de mémoire. Envisager l'utilisation de techniques de gestion de la mémoire plus efficaces, comme la libération explicite des ressources ou le traitement par flux."
Add-Content -Path $performanceFile -Value "3. **Optimiser la sérialisation** : Les opérations de sérialisation et de désérialisation sont relativement lentes. Envisager l'utilisation de formats de sérialisation plus efficaces ou de techniques de mise en cache."
Add-Content -Path $performanceFile -Value "4. **Paralléliser les opérations** : Certaines opérations pourraient bénéficier de la parallélisation, en particulier pour les collections volumineuses."
Add-Content -Path $performanceFile -Value "5. **Optimiser la validation** : La validation des informations extraites peut être coûteuse. Envisager l'utilisation de techniques de validation plus efficaces ou de mise en cache des résultats de validation."

# Afficher le chemin du fichier de résultats
Write-Host "`nLes résultats des mesures de performance ont été enregistrés dans : $performanceFile" -ForegroundColor $successColor

# Retourner le code de sortie
exit 0

