# DÃ©veloppement de plugins d'analyse personnalisÃ©s

Ce document explique comment dÃ©velopper des plugins personnalisÃ©s pour le systÃ¨me d'intÃ©gration avec des outils d'analyse tiers.

## Table des matiÃ¨res

1. [Introduction](#introduction)
2. [Architecture du systÃ¨me de plugins](#architecture-du-systÃ¨me-de-plugins)
3. [Structure d'un plugin](#structure-dun-plugin)
4. [CrÃ©ation d'un plugin simple](#crÃ©ation-dun-plugin-simple)
5. [Fonctions avancÃ©es](#fonctions-avancÃ©es)
   - [Conversion des rÃ©sultats](#conversion-des-rÃ©sultats)
   - [Configuration du plugin](#configuration-du-plugin)
   - [Gestion des dÃ©pendances](#gestion-des-dÃ©pendances)
6. [Bonnes pratiques](#bonnes-pratiques)
7. [DÃ©bogage des plugins](#dÃ©bogage-des-plugins)
8. [Exemples](#exemples)

## Introduction

Le systÃ¨me de plugins permet d'Ã©tendre les fonctionnalitÃ©s d'analyse avec des plugins personnalisÃ©s. Un plugin est un script PowerShell qui enregistre une fonction d'analyse avec le systÃ¨me de plugins. Cette fonction est appelÃ©e lorsque le plugin est utilisÃ© pour analyser un fichier ou un rÃ©pertoire.

## Architecture du systÃ¨me de plugins

Le systÃ¨me de plugins est composÃ© des Ã©lÃ©ments suivants :

- **AnalysisPluginManager.psm1** : Module de gestion des plugins
- **UnifiedResultsFormat.psm1** : Module dÃ©finissant le format unifiÃ© des rÃ©sultats
- **Register-AnalysisPlugin.ps1** : Script pour enregistrer des plugins
- **Plugins** : Scripts PowerShell qui enregistrent des fonctions d'analyse

Le flux de travail typique est le suivant :

1. Un plugin est enregistrÃ© avec `Register-AnalysisPlugin`
2. Le plugin est appelÃ© pour analyser un fichier ou un rÃ©pertoire
3. Le plugin exÃ©cute sa fonction d'analyse et retourne des rÃ©sultats au format unifiÃ©
4. Les rÃ©sultats sont traitÃ©s par le systÃ¨me (affichage, fusion, etc.)

## Structure d'un plugin

Un plugin est un script PowerShell qui contient au minimum :

- Une fonction d'analyse qui prend un chemin de fichier en paramÃ¨tre et retourne des rÃ©sultats au format unifiÃ©
- Un appel Ã  `Register-AnalysisPlugin` pour enregistrer la fonction d'analyse

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
    
    # Analyser le fichier et retourner des rÃ©sultats au format unifiÃ©
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

## CrÃ©ation d'un plugin simple

Voici un exemple de plugin simple qui vÃ©rifie la longueur des lignes dans un fichier texte :

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
    
    # VÃ©rifier si le fichier existe
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
        
        # VÃ©rifier la longueur de la ligne
        if ($line.Length -gt $MaxLineLength) {
            $result = New-UnifiedAnalysisResult -ToolName "LineLengthAnalyzer" `
                                               -FilePath $FilePath `
                                               -Line $lineNumber `
                                               -Column 1 `
                                               -RuleId "LineLength" `
                                               -Severity "Warning" `
                                               -Message "La ligne dÃ©passe la longueur maximale de $MaxLineLength caractÃ¨res (longueur actuelle: $($line.Length))" `
                                               -Category "Style" `
                                               -Suggestion "RÃ©duisez la longueur de la ligne Ã  $MaxLineLength caractÃ¨res ou moins."
            
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
.\development\scripts\analysis\Register-AnalysisPlugin.ps1 -Path ".\development\scripts\analysis\plugins\LineLengthAnalyzer.ps1"

# Utiliser le plugin via le systÃ¨me de plugins
$plugin = Get-AnalysisPlugin -Name "LineLengthAnalyzer"
$results = Invoke-AnalysisPlugin -Name "LineLengthAnalyzer" -FilePath "chemin\vers\fichier.txt" -AdditionalParameters @{ MaxLineLength = 100 }
```

## Fonctions avancÃ©es

### Conversion des rÃ©sultats

Si votre plugin utilise un outil externe qui produit des rÃ©sultats dans un format spÃ©cifique, vous pouvez dÃ©finir une fonction de conversion pour transformer ces rÃ©sultats en format unifiÃ© :

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

Vous pouvez dÃ©finir une configuration par dÃ©faut pour votre plugin :

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

La configuration est accessible dans la fonction d'analyse via les paramÃ¨tres :

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

### Gestion des dÃ©pendances

Vous pouvez spÃ©cifier les dÃ©pendances de votre plugin :

```powershell
# Enregistrer le plugin avec des dÃ©pendances
Register-AnalysisPlugin -Name "MonPlugin" `
                       -Description "Description de mon plugin" `
                       -Version "1.0" `
                       -Author "Votre nom" `
                       -Language "Generic" `
                       -AnalyzeFunction $analyzeFunction `
                       -Dependencies @("PSScriptAnalyzer", "ESLint") `
                       -Force
```

Le systÃ¨me vÃ©rifiera que ces dÃ©pendances sont disponibles avant d'exÃ©cuter le plugin.

## Bonnes pratiques

### Performance

- Utilisez des techniques efficaces pour analyser les fichiers (lecture en bloc, traitement parallÃ¨le, etc.)
- Ã‰vitez de charger des fichiers volumineux en mÃ©moire si possible
- Utilisez des caches pour Ã©viter de rÃ©analyser des fichiers inchangÃ©s

### Robustesse

- GÃ©rez correctement les erreurs et les exceptions
- VÃ©rifiez que les fichiers existent avant de les analyser
- Validez les paramÃ¨tres d'entrÃ©e

### CompatibilitÃ©

- Assurez-vous que votre plugin fonctionne avec PowerShell 5.1 et supÃ©rieur
- Ã‰vitez d'utiliser des fonctionnalitÃ©s spÃ©cifiques Ã  une version de PowerShell
- Testez votre plugin sur diffÃ©rentes plateformes (Windows, Linux, macOS)

### Documentation

- Documentez clairement le but et le fonctionnement de votre plugin
- Expliquez les paramÃ¨tres de configuration disponibles
- Fournissez des exemples d'utilisation

## DÃ©bogage des plugins

Pour dÃ©boguer un plugin :

1. Utilisez le paramÃ¨tre `-Verbose` pour obtenir des informations dÃ©taillÃ©es :

```powershell
Invoke-AnalysisPlugin -Name "MonPlugin" -FilePath "chemin\vers\fichier.txt" -Verbose
```

2. Utilisez `Write-Verbose` dans votre fonction d'analyse pour afficher des informations de dÃ©bogage :

```powershell
$analyzeFunction = {
    param (
        [string]$FilePath
    )
    
    Write-Verbose "Analyse du fichier: $FilePath"
    
    # ...
}
```

3. Utilisez `Get-AnalysisPluginStatistics` pour obtenir des statistiques sur l'exÃ©cution de votre plugin :

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
    
    # VÃ©rifier si le fichier existe
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
        
        # VÃ©rifier si la ligne contient un commentaire TODO
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
                                                   -Suggestion "RÃ©solvez ce $todoKeyword ou convertissez-le en tÃ¢che dans le systÃ¨me de suivi des problÃ¨mes."
                
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
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "Le fichier '$FilePath' n'existe pas."
        return $null
    }
    
    # VÃ©rifier si le fichier est un fichier JSON
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
    
    # VÃ©rifier les propriÃ©tÃ©s requises
    foreach ($property in $RequiredProperties) {
        if (-not (Get-Member -InputObject $json -Name $property -MemberType Properties)) {
            $result = New-UnifiedAnalysisResult -ToolName "JsonConfigAnalyzer" `
                                               -FilePath $FilePath `
                                               -Line 1 `
                                               -Column 1 `
                                               -RuleId "Json.MissingProperty" `
                                               -Severity "Error" `
                                               -Message "PropriÃ©tÃ© requise manquante: $property" `
                                               -Category "Configuration" `
                                               -Suggestion "Ajoutez la propriÃ©tÃ© '$property' au fichier de configuration."
            
            $results += $result
        }
    }
    
    # Valider les propriÃ©tÃ©s avec des validateurs personnalisÃ©s
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
                                                   -Message "PropriÃ©tÃ© invalide: $property - $validationResult" `
                                                   -Category "Configuration" `
                                                   -Suggestion "Corrigez la valeur de la propriÃ©tÃ© '$property'."
                
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

Ces exemples montrent comment crÃ©er des plugins personnalisÃ©s pour des cas d'utilisation spÃ©cifiques. Vous pouvez les adapter Ã  vos besoins ou crÃ©er vos propres plugins pour intÃ©grer d'autres outils d'analyse.
