# Développement de plugins d'analyse personnalisés

Ce document explique comment développer des plugins personnalisés pour le système d'intégration avec des outils d'analyse tiers.

## Table des matières

1. [Introduction](#introduction)
2. [Architecture du système de plugins](#architecture-du-système-de-plugins)
3. [Structure d'un plugin](#structure-dun-plugin)
4. [Création d'un plugin simple](#création-dun-plugin-simple)
5. [Fonctions avancées](#fonctions-avancées)
   - [Conversion des résultats](#conversion-des-résultats)
   - [Configuration du plugin](#configuration-du-plugin)
   - [Gestion des dépendances](#gestion-des-dépendances)
6. [Bonnes pratiques](#bonnes-pratiques)
7. [Débogage des plugins](#débogage-des-plugins)
8. [Exemples](#exemples)

## Introduction

Le système de plugins permet d'étendre les fonctionnalités d'analyse avec des plugins personnalisés. Un plugin est un script PowerShell qui enregistre une fonction d'analyse avec le système de plugins. Cette fonction est appelée lorsque le plugin est utilisé pour analyser un fichier ou un répertoire.

## Architecture du système de plugins

Le système de plugins est composé des éléments suivants :

- **AnalysisPluginManager.psm1** : Module de gestion des plugins
- **UnifiedResultsFormat.psm1** : Module définissant le format unifié des résultats
- **Register-AnalysisPlugin.ps1** : Script pour enregistrer des plugins
- **Plugins** : Scripts PowerShell qui enregistrent des fonctions d'analyse

Le flux de travail typique est le suivant :

1. Un plugin est enregistré avec `Register-AnalysisPlugin`
2. Le plugin est appelé pour analyser un fichier ou un répertoire
3. Le plugin exécute sa fonction d'analyse et retourne des résultats au format unifié
4. Les résultats sont traités par le système (affichage, fusion, etc.)

## Structure d'un plugin

Un plugin est un script PowerShell qui contient au minimum :

- Une fonction d'analyse qui prend un chemin de fichier en paramètre et retourne des résultats au format unifié
- Un appel à `Register-AnalysisPlugin` pour enregistrer la fonction d'analyse

Voici la structure minimale d'un plugin :

```powershell
# Importer le module de gestion des plugins
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
$pluginManagerPath = Join-Path -Path $modulesPath -ChildPath "AnalysisPluginManager.psm1"
Import-Module -Name $pluginManagerPath -Force

# Fonction d'analyse
$analyzeFunction = {
    param (
        [string]$FilePath
    )
    
    # Analyser le fichier et retourner des résultats au format unifié
    $results = @()
    
    # ...
    
    return $results
}

# Enregistrer le plugin
Register-AnalysisPlugin -Name "MonPlugin" `
                       -Description "Description de mon plugin" `
                       -Version "1.0" `
                       -Author "Votre nom" `
                       -Language "Generic" `
                       -AnalyzeFunction $analyzeFunction `
                       -Force
```

## Création d'un plugin simple

Voici un exemple de plugin simple qui vérifie la longueur des lignes dans un fichier texte :

```powershell
# LineLengthAnalyzer.ps1
#Requires -Version 5.1

# Importer les modules requis
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
$pluginManagerPath = Join-Path -Path $modulesPath -ChildPath "AnalysisPluginManager.psm1"
$unifiedResultsFormatPath = Join-Path -Path $modulesPath -ChildPath "UnifiedResultsFormat.psm1"

Import-Module -Name $pluginManagerPath -Force
Import-Module -Name $unifiedResultsFormatPath -Force

# Fonction d'analyse
$analyzeFunction = {
    param (
        [string]$FilePath,
        [int]$MaxLineLength = 80
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "Le fichier '$FilePath' n'existe pas."
        return $null
    }
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath
    $results = @()
    
    # Analyser chaque ligne
    for ($i = 0; $i -lt $content.Count; $i++) {
        $line = $content[$i]
        $lineNumber = $i + 1
        
        # Vérifier la longueur de la ligne
        if ($line.Length -gt $MaxLineLength) {
            $result = New-UnifiedAnalysisResult -ToolName "LineLengthAnalyzer" `
                                               -FilePath $FilePath `
                                               -Line $lineNumber `
                                               -Column 1 `
                                               -RuleId "LineLength" `
                                               -Severity "Warning" `
                                               -Message "La ligne dépasse la longueur maximale de $MaxLineLength caractères (longueur actuelle: $($line.Length))" `
                                               -Category "Style" `
                                               -Suggestion "Réduisez la longueur de la ligne à $MaxLineLength caractères ou moins."
            
            $results += $result
        }
    }
    
    return $results
}

# Enregistrer le plugin
Register-AnalysisPlugin -Name "LineLengthAnalyzer" `
                       -Description "Analyse la longueur des lignes dans un fichier texte" `
                       -Version "1.0" `
                       -Author "EMAIL_SENDER_1" `
                       -Language "Generic" `
                       -AnalyzeFunction $analyzeFunction `
                       -Configuration @{
                           MaxLineLength = 80
                       } `
                       -Force
```

Pour utiliser ce plugin :

```powershell
# Enregistrer le plugin
.\scripts\analysis\Register-AnalysisPlugin.ps1 -Path ".\scripts\analysis\plugins\LineLengthAnalyzer.ps1"

# Utiliser le plugin via le système de plugins
$plugin = Get-AnalysisPlugin -Name "LineLengthAnalyzer"
$results = Invoke-AnalysisPlugin -Name "LineLengthAnalyzer" -FilePath "chemin\vers\fichier.txt" -AdditionalParameters @{ MaxLineLength = 100 }
```

## Fonctions avancées

### Conversion des résultats

Si votre plugin utilise un outil externe qui produit des résultats dans un format spécifique, vous pouvez définir une fonction de conversion pour transformer ces résultats en format unifié :

```powershell
# Fonction de conversion
$convertFunction = {
    param (
        [object]$Results
    )
    
    $unifiedResults = @()
    
    foreach ($result in $Results) {
        $unifiedResult = New-UnifiedAnalysisResult -ToolName "MonOutil" `
                                                  -FilePath $result.file `
                                                  -Line $result.line `
                                                  -Column $result.column `
                                                  -RuleId $result.rule `
                                                  -Severity "Warning" `
                                                  -Message $result.message `
                                                  -Category "Style" `
                                                  -OriginalObject $result
        
        $unifiedResults += $unifiedResult
    }
    
    return $unifiedResults
}

# Enregistrer le plugin avec la fonction de conversion
Register-AnalysisPlugin -Name "MonPlugin" `
                       -Description "Description de mon plugin" `
                       -Version "1.0" `
                       -Author "Votre nom" `
                       -Language "Generic" `
                       -AnalyzeFunction $analyzeFunction `
                       -ConvertFunction $convertFunction `
                       -Force
```

### Configuration du plugin

Vous pouvez définir une configuration par défaut pour votre plugin :

```powershell
# Enregistrer le plugin avec une configuration
Register-AnalysisPlugin -Name "MonPlugin" `
                       -Description "Description de mon plugin" `
                       -Version "1.0" `
                       -Author "Votre nom" `
                       -Language "Generic" `
                       -AnalyzeFunction $analyzeFunction `
                       -Configuration @{
                           MaxLineLength = 80
                           IgnoreComments = $true
                           IgnoreEmptyLines = $true
                       } `
                       -Force
```

La configuration est accessible dans la fonction d'analyse via les paramètres :

```powershell
$analyzeFunction = {
    param (
        [string]$FilePath,
        [int]$MaxLineLength = 80,
        [bool]$IgnoreComments = $true,
        [bool]$IgnoreEmptyLines = $true
    )
    
    # ...
}
```

### Gestion des dépendances

Vous pouvez spécifier les dépendances de votre plugin :

```powershell
# Enregistrer le plugin avec des dépendances
Register-AnalysisPlugin -Name "MonPlugin" `
                       -Description "Description de mon plugin" `
                       -Version "1.0" `
                       -Author "Votre nom" `
                       -Language "Generic" `
                       -AnalyzeFunction $analyzeFunction `
                       -Dependencies @("PSScriptAnalyzer", "ESLint") `
                       -Force
```

Le système vérifiera que ces dépendances sont disponibles avant d'exécuter le plugin.

## Bonnes pratiques

### Performance

- Utilisez des techniques efficaces pour analyser les fichiers (lecture en bloc, traitement parallèle, etc.)
- Évitez de charger des fichiers volumineux en mémoire si possible
- Utilisez des caches pour éviter de réanalyser des fichiers inchangés

### Robustesse

- Gérez correctement les erreurs et les exceptions
- Vérifiez que les fichiers existent avant de les analyser
- Validez les paramètres d'entrée

### Compatibilité

- Assurez-vous que votre plugin fonctionne avec PowerShell 5.1 et supérieur
- Évitez d'utiliser des fonctionnalités spécifiques à une version de PowerShell
- Testez votre plugin sur différentes plateformes (Windows, Linux, macOS)

### Documentation

- Documentez clairement le but et le fonctionnement de votre plugin
- Expliquez les paramètres de configuration disponibles
- Fournissez des exemples d'utilisation

## Débogage des plugins

Pour déboguer un plugin :

1. Utilisez le paramètre `-Verbose` pour obtenir des informations détaillées :

```powershell
Invoke-AnalysisPlugin -Name "MonPlugin" -FilePath "chemin\vers\fichier.txt" -Verbose
```

2. Utilisez `Write-Verbose` dans votre fonction d'analyse pour afficher des informations de débogage :

```powershell
$analyzeFunction = {
    param (
        [string]$FilePath
    )
    
    Write-Verbose "Analyse du fichier: $FilePath"
    
    # ...
}
```

3. Utilisez `Get-AnalysisPluginStatistics` pour obtenir des statistiques sur l'exécution de votre plugin :

```powershell
Get-AnalysisPluginStatistics -Name "MonPlugin"
```

## Exemples

### Plugin pour analyser les commentaires TODO

```powershell
# TodoAnalyzer.ps1
#Requires -Version 5.1

# Importer les modules requis
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
$pluginManagerPath = Join-Path -Path $modulesPath -ChildPath "AnalysisPluginManager.psm1"
$unifiedResultsFormatPath = Join-Path -Path $modulesPath -ChildPath "UnifiedResultsFormat.psm1"

Import-Module -Name $pluginManagerPath -Force
Import-Module -Name $unifiedResultsFormatPath -Force

# Fonction d'analyse
$analyzeFunction = {
    param (
        [string]$FilePath,
        [string[]]$Keywords = @("TODO", "FIXME", "HACK", "NOTE", "BUG"),
        [ValidateSet("Error", "Warning", "Information")]
        [string]$Severity = "Information"
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "Le fichier '$FilePath' n'existe pas."
        return $null
    }
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath
    $results = @()
    
    # Analyser chaque ligne
    for ($i = 0; $i -lt $content.Count; $i++) {
        $line = $content[$i]
        $lineNumber = $i + 1
        
        # Vérifier si la ligne contient un commentaire TODO
        foreach ($keyword in $Keywords) {
            if ($line -match "(?i)(?:#|\/\/|\/\*|\*|--|<!--)\s*($keyword)(?:\s*:)?\s*(.*)") {
                $todoKeyword = $matches[1]
                $todoComment = $matches[2]
                
                $result = New-UnifiedAnalysisResult -ToolName "TodoAnalyzer" `
                                                   -FilePath $FilePath `
                                                   -Line $lineNumber `
                                                   -Column $line.IndexOf($todoKeyword) + 1 `
                                                   -RuleId "Todo.$todoKeyword" `
                                                   -Severity $Severity `
                                                   -Message "$todoKeyword: $todoComment" `
                                                   -Category "Documentation" `
                                                   -Suggestion "Résolvez ce $todoKeyword ou convertissez-le en tâche dans le système de suivi des problèmes."
                
                $results += $result
            }
        }
    }
    
    return $results
}

# Enregistrer le plugin
Register-AnalysisPlugin -Name "TodoAnalyzer" `
                       -Description "Analyse les commentaires TODO, FIXME, etc. dans le code" `
                       -Version "1.0" `
                       -Author "EMAIL_SENDER_1" `
                       -Language "Generic" `
                       -AnalyzeFunction $analyzeFunction `
                       -Configuration @{
                           Keywords = @("TODO", "FIXME", "HACK", "NOTE", "BUG")
                           Severity = "Information"
                       } `
                       -Force
```

### Plugin pour analyser les fichiers de configuration JSON

```powershell
# JsonConfigAnalyzer.ps1
#Requires -Version 5.1

# Importer les modules requis
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
$pluginManagerPath = Join-Path -Path $modulesPath -ChildPath "AnalysisPluginManager.psm1"
$unifiedResultsFormatPath = Join-Path -Path $modulesPath -ChildPath "UnifiedResultsFormat.psm1"

Import-Module -Name $pluginManagerPath -Force
Import-Module -Name $unifiedResultsFormatPath -Force

# Fonction d'analyse
$analyzeFunction = {
    param (
        [string]$FilePath,
        [string[]]$RequiredProperties = @(),
        [hashtable]$PropertyValidators = @{}
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "Le fichier '$FilePath' n'existe pas."
        return $null
    }
    
    # Vérifier si le fichier est un fichier JSON
    if (-not ($FilePath -match '\.json$')) {
        Write-Warning "Le fichier '$FilePath' n'est pas un fichier JSON."
        return @()
    }
    
    # Lire le contenu du fichier
    try {
        $content = Get-Content -Path $FilePath -Raw
        $json = $content | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        $result = New-UnifiedAnalysisResult -ToolName "JsonConfigAnalyzer" `
                                           -FilePath $FilePath `
                                           -Line 1 `
                                           -Column 1 `
                                           -RuleId "Json.InvalidFormat" `
                                           -Severity "Error" `
                                           -Message "Le fichier JSON n'est pas valide: $_" `
                                           -Category "Syntax"
        
        return @($result)
    }
    
    $results = @()
    
    # Vérifier les propriétés requises
    foreach ($property in $RequiredProperties) {
        if (-not (Get-Member -InputObject $json -Name $property -MemberType Properties)) {
            $result = New-UnifiedAnalysisResult -ToolName "JsonConfigAnalyzer" `
                                               -FilePath $FilePath `
                                               -Line 1 `
                                               -Column 1 `
                                               -RuleId "Json.MissingProperty" `
                                               -Severity "Error" `
                                               -Message "Propriété requise manquante: $property" `
                                               -Category "Configuration" `
                                               -Suggestion "Ajoutez la propriété '$property' au fichier de configuration."
            
            $results += $result
        }
    }
    
    # Valider les propriétés avec des validateurs personnalisés
    foreach ($property in $PropertyValidators.Keys) {
        if (Get-Member -InputObject $json -Name $property -MemberType Properties) {
            $validator = $PropertyValidators[$property]
            $value = $json.$property
            
            $validationResult = & $validator $value
            
            if ($validationResult -ne $true) {
                $result = New-UnifiedAnalysisResult -ToolName "JsonConfigAnalyzer" `
                                                   -FilePath $FilePath `
                                                   -Line 1 `
                                                   -Column 1 `
                                                   -RuleId "Json.InvalidProperty" `
                                                   -Severity "Error" `
                                                   -Message "Propriété invalide: $property - $validationResult" `
                                                   -Category "Configuration" `
                                                   -Suggestion "Corrigez la valeur de la propriété '$property'."
                
                $results += $result
            }
        }
    }
    
    return $results
}

# Enregistrer le plugin
Register-AnalysisPlugin -Name "JsonConfigAnalyzer" `
                       -Description "Analyse les fichiers de configuration JSON" `
                       -Version "1.0" `
                       -Author "EMAIL_SENDER_1" `
                       -Language "Generic" `
                       -AnalyzeFunction $analyzeFunction `
                       -Configuration @{
                           RequiredProperties = @()
                           PropertyValidators = @{}
                       } `
                       -Force
```

Ces exemples montrent comment créer des plugins personnalisés pour des cas d'utilisation spécifiques. Vous pouvez les adapter à vos besoins ou créer vos propres plugins pour intégrer d'autres outils d'analyse.
