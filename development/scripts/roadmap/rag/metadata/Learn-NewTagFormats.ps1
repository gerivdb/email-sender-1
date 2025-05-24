# Learn-NewTagFormats.ps1
# Script pour apprendre et ajouter automatiquement de nouveaux formats de tags
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath,
    
    [Parameter(Mandatory = $false)]
    [string]$Content,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "development\scripts\roadmap\rag\config\tag-formats\TagFormats.config.json",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Auto", "Interactive", "Silent")]
    [string]$Mode = "Interactive",
    
    [Parameter(Mandatory = $false)]
    [double]$ConfidenceThreshold = 0.7,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction pour charger la configuration des formats de tags
function Get-TagFormatsConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )
    
    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $ConfigPath)) {
            Write-Error "Le fichier de configuration n'existe pas: $ConfigPath"
            return $null
        }
        
        # Charger le fichier de configuration
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        
        return $config
    }
    catch {
        Write-Error "Erreur lors du chargement de la configuration: $_"
        return $null
    }
}

# Fonction pour sauvegarder la configuration des formats de tags
function Save-TagFormatsConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Config,
        
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )
    
    try {
        # Mettre à jour la date de modification
        $Config.updated_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        
        # Convertir la configuration en JSON et l'enregistrer
        $Config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8
        
        Write-Host "Configuration enregistrée avec succès dans $ConfigPath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'enregistrement de la configuration: $_"
        return $false
    }
}

# Fonction pour détecter les tâches dans le contenu
function Get-TasksFromContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    try {
        # Diviser le contenu en lignes
        $lines = $Content -split "`r?`n"
        
        # Pattern pour détecter les tâches
        $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
        
        $tasks = @{}
        $lineNumber = 0
        
        foreach ($line in $lines) {
            $lineNumber++
            
            if ($line -match $taskPattern) {
                $status = $matches[1] -ne ' '
                $taskId = $matches[2]
                $taskTitle = $matches[3]
                
                if (-not $tasks.ContainsKey($taskId)) {
                    $tasks[$taskId] = @{
                        Id = $taskId
                        Title = $taskTitle
                        Status = $status
                        LineNumber = $lineNumber
                        Line = $line
                    }
                }
            }
        }
        
        return $tasks
    }
    catch {
        Write-Error "Erreur lors de la détection des tâches: $_"
        return @{}
    }
}

# Fonction pour détecter les potentiels nouveaux formats de tags
function Find-PotentialTagFormats {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Tasks,
        
        [Parameter(Mandatory = $true)]
        [PSObject]$TagFormats
    )
    
    try {
        # Patterns pour détecter les potentiels nouveaux formats de tags
        $potentialPatterns = @(
            # Format général des tags: #tag:value ou #tag(value)
            @{
                Pattern = '#([a-zA-Z0-9_-]+):([a-zA-Z0-9_.-]+)'
                Description = "Format #tag:value"
                Example = "#tag:value"
                Type = "General"
            },
            @{
                Pattern = '#([a-zA-Z0-9_-]+)\(([a-zA-Z0-9_.-]+)\)'
                Description = "Format #tag(value)"
                Example = "#tag(value)"
                Type = "General"
            },
            # Formats spécifiques pour les durées
            @{
                Pattern = '#([a-zA-Z0-9_-]+):(\d+(?:\.\d+)?)([a-zA-Z]+)'
                Description = "Format #tag:Xunit (durée avec unité)"
                Example = "#tag:5d"
                Type = "Duration"
            },
            @{
                Pattern = '#([a-zA-Z0-9_-]+)\((\d+(?:\.\d+)?)([a-zA-Z]+)\)'
                Description = "Format #tag(Xunit) (durée avec unité)"
                Example = "#tag(5d)"
                Type = "Duration"
            },
            # Formats composites
            @{
                Pattern = '#([a-zA-Z0-9_-]+):(\d+(?:\.\d+)?)([a-zA-Z]+)[-_]?(\d+(?:\.\d+)?)([a-zA-Z]+)'
                Description = "Format #tag:Xunit1Yunit2 (durée composite)"
                Example = "#tag:5d3h"
                Type = "CompositeDuration"
            }
        )
        
        # Créer un dictionnaire pour stocker les formats détectés
        $detectedFormats = @{}
        
        # Pour chaque tâche
        foreach ($taskId in $Tasks.Keys) {
            $taskLine = $Tasks[$taskId].Line
            
            # Pour chaque pattern potentiel
            foreach ($potentialPattern in $potentialPatterns) {
                $pattern = $potentialPattern.Pattern
                
                # Rechercher toutes les occurrences du pattern
                $matches = [regex]::Matches($taskLine, $pattern)
                
                foreach ($match in $matches) {
                    $fullMatch = $match.Value
                    
                    # Vérifier si ce format est déjà connu
                    $isKnown = $false
                    
                    foreach ($tagType in $TagFormats.tag_formats.PSObject.Properties.Name) {
                        foreach ($format in $TagFormats.tag_formats.$tagType.formats) {
                            if ($fullMatch -match $format.pattern) {
                                $isKnown = $true
                                break
                            }
                        }
                        
                        if ($isKnown) {
                            break
                        }
                    }
                    
                    # Si le format n'est pas connu, l'ajouter aux formats détectés
                    if (-not $isKnown) {
                        $tagName = $match.Groups[1].Value.ToLower()
                        
                        if (-not $detectedFormats.ContainsKey($tagName)) {
                            $detectedFormats[$tagName] = @{
                                Name = $tagName
                                Formats = @{}
                                Count = 0
                            }
                        }
                        
                        if (-not $detectedFormats[$tagName].Formats.ContainsKey($fullMatch)) {
                            $detectedFormats[$tagName].Formats[$fullMatch] = @{
                                Original = $fullMatch
                                Pattern = $pattern
                                Type = $potentialPattern.Type
                                Count = 0
                                Tasks = @()
                            }
                        }
                        
                        $detectedFormats[$tagName].Formats[$fullMatch].Count++
                        $detectedFormats[$tagName].Count++
                        
                        if (-not $detectedFormats[$tagName].Formats[$fullMatch].Tasks.Contains($taskId)) {
                            $detectedFormats[$tagName].Formats[$fullMatch].Tasks += $taskId
                        }
                    }
                }
            }
        }
        
        return $detectedFormats
    }
    catch {
        Write-Error "Erreur lors de la détection des potentiels nouveaux formats de tags: $_"
        return @{}
    }
}

# Fonction pour analyser et créer des patterns regex pour les nouveaux formats
function New-RegexPatterns {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$DetectedFormats
    )
    
    try {
        $newPatterns = @{}
        
        foreach ($tagName in $DetectedFormats.Keys) {
            $newPatterns[$tagName] = @{
                Name = $tagName
                Patterns = @()
            }
            
            foreach ($formatKey in $DetectedFormats[$tagName].Formats.Keys) {
                $format = $DetectedFormats[$tagName].Formats[$formatKey]
                
                # Créer un pattern regex en fonction du type
                $regexPattern = ""
                $description = ""
                $example = $format.Original
                $valueGroup = 0
                $unit = ""
                $isComposite = $false
                $valueGroups = @()
                $units = @()
                
                switch ($format.Type) {
                    "General" {
                        if ($format.Original -match '#([a-zA-Z0-9_-]+):([a-zA-Z0-9_.-]+)') {
                            $regexPattern = "#$tagName:([a-zA-Z0-9_.-]+)"
                            $description = "Format #$tagName:value"
                            $valueGroup = 1
                        }
                        elseif ($format.Original -match '#([a-zA-Z0-9_-]+)\(([a-zA-Z0-9_.-]+)\)') {
                            $regexPattern = "#$tagName\(([a-zA-Z0-9_.-]+)\)"
                            $description = "Format #$tagName(value)"
                            $valueGroup = 1
                        }
                    }
                    "Duration" {
                        if ($format.Original -match '#([a-zA-Z0-9_-]+):(\d+(?:\.\d+)?)([a-zA-Z]+)') {
                            $value = $matches[2]
                            $unitStr = $matches[3]
                            
                            $regexPattern = "#$tagName:(\d+(?:\.\d+)?)$unitStr\b"
                            $description = "Format #$tagName:X$unitStr"
                            $valueGroup = 1
                            
                            # Déterminer l'unité
                            switch ($unitStr) {
                                "d" { $unit = "days" }
                                "j" { $unit = "days" }
                                "w" { $unit = "weeks" }
                                "s" { $unit = "weeks" }
                                "m" { $unit = "months" }
                                "h" { $unit = "hours" }
                                "min" { $unit = "minutes" }
                                default { $unit = $unitStr }
                            }
                        }
                        elseif ($format.Original -match '#([a-zA-Z0-9_-]+)\((\d+(?:\.\d+)?)([a-zA-Z]+)\)') {
                            $value = $matches[2]
                            $unitStr = $matches[3]
                            
                            $regexPattern = "#$tagName\((\d+(?:\.\d+)?)$unitStr\)"
                            $description = "Format #$tagName(X$unitStr)"
                            $valueGroup = 1
                            
                            # Déterminer l'unité
                            switch ($unitStr) {
                                "d" { $unit = "days" }
                                "j" { $unit = "days" }
                                "w" { $unit = "weeks" }
                                "s" { $unit = "weeks" }
                                "m" { $unit = "months" }
                                "h" { $unit = "hours" }
                                "min" { $unit = "minutes" }
                                default { $unit = $unitStr }
                            }
                        }
                    }
                    "CompositeDuration" {
                        if ($format.Original -match '#([a-zA-Z0-9_-]+):(\d+(?:\.\d+)?)([a-zA-Z]+)[-_]?(\d+(?:\.\d+)?)([a-zA-Z]+)') {
                            $value1 = $matches[2]
                            $unit1Str = $matches[3]
                            $value2 = $matches[4]
                            $unit2Str = $matches[5]
                            
                            $regexPattern = "#$tagName:(\d+(?:\.\d+)?)$unit1Str[-_]?(\d+(?:\.\d+)?)$unit2Str\b"
                            $description = "Format #$tagName:X$unit1StrY$unit2Str"
                            $isComposite = $true
                            $valueGroups = @(1, 2)
                            
                            # Déterminer les unités
                            $unit1 = ""
                            $unit2 = ""
                            
                            switch ($unit1Str) {
                                "d" { $unit1 = "days" }
                                "j" { $unit1 = "days" }
                                "w" { $unit1 = "weeks" }
                                "s" { $unit1 = "weeks" }
                                "m" { $unit1 = "months" }
                                "h" { $unit1 = "hours" }
                                "min" { $unit1 = "minutes" }
                                default { $unit1 = $unit1Str }
                            }
                            
                            switch ($unit2Str) {
                                "d" { $unit2 = "days" }
                                "j" { $unit2 = "days" }
                                "w" { $unit2 = "weeks" }
                                "s" { $unit2 = "weeks" }
                                "m" { $unit2 = "months" }
                                "h" { $unit2 = "hours" }
                                "min" { $unit2 = "minutes" }
                                default { $unit2 = $unit2Str }
                            }
                            
                            $units = @($unit1, $unit2)
                        }
                    }
                }
                
                # Ajouter le pattern s'il a été créé
                if ($regexPattern) {
                    $newPattern = @{
                        Original = $format.Original
                        Pattern = $regexPattern
                        Description = $description
                        Example = $example
                        Count = $format.Count
                        Tasks = $format.Tasks
                    }
                    
                    if ($isComposite) {
                        $newPattern.IsComposite = $true
                        $newPattern.ValueGroups = $valueGroups
                        $newPattern.Units = $units
                    }
                    else {
                        $newPattern.ValueGroup = $valueGroup
                        $newPattern.Unit = $unit
                    }
                    
                    $newPatterns[$tagName].Patterns += $newPattern
                }
            }
        }
        
        return $newPatterns
    }
    catch {
        Write-Error "Erreur lors de la création des patterns regex: $_"
        return @{}
    }
}

# Fonction pour ajouter les nouveaux formats à la configuration
function Add-NewFormatsToConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Config,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$NewPatterns,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Auto", "Interactive", "Silent")]
        [string]$Mode = "Interactive",
        
        [Parameter(Mandatory = $false)]
        [double]$ConfidenceThreshold = 0.7
    )
    
    try {
        $addedFormats = @()
        
        foreach ($tagName in $NewPatterns.Keys) {
            # Vérifier si le type de tag existe déjà
            $tagTypeExists = $Config.tag_formats.PSObject.Properties.Name -contains $tagName
            
            # Si le type n'existe pas, le créer
            if (-not $tagTypeExists) {
                $Config.tag_formats | Add-Member -MemberType NoteProperty -Name $tagName -Value @{
                    name = $tagName
                    description = "Tags pour $tagName"
                    formats = @()
                }
                
                Write-Host "Nouveau type de tag créé: $tagName" -ForegroundColor Green
            }
            
            # Pour chaque pattern détecté
            foreach ($pattern in $NewPatterns[$tagName].Patterns) {
                # Vérifier si le format existe déjà
                $formatExists = $false
                
                foreach ($existingFormat in $Config.tag_formats.$tagName.formats) {
                    if ($existingFormat.pattern -eq $pattern.Pattern) {
                        $formatExists = $true
                        break
                    }
                }
                
                if ($formatExists) {
                    Write-Host "Le format '$($pattern.Description)' existe déjà pour le type de tag '$tagName'." -ForegroundColor Yellow
                    continue
                }
                
                # Déterminer si le format doit être ajouté
                $addFormat = $false
                
                switch ($Mode) {
                    "Auto" {
                        # Ajouter automatiquement si le nombre d'occurrences est suffisant
                        if ($pattern.Count -ge 3) {
                            $addFormat = $true
                        }
                    }
                    "Interactive" {
                        # Demander à l'utilisateur
                        Write-Host "`nNouveau format de tag détecté:" -ForegroundColor Cyan
                        Write-Host "  Type: $tagName" -ForegroundColor Cyan
                        Write-Host "  Description: $($pattern.Description)" -ForegroundColor Cyan
                        Write-Host "  Exemple: $($pattern.Example)" -ForegroundColor Cyan
                        Write-Host "  Nombre d'occurrences: $($pattern.Count)" -ForegroundColor Cyan
                        Write-Host "  Tâches: $($pattern.Tasks -join ', ')" -ForegroundColor Cyan
                        
                        $response = Read-Host "Voulez-vous ajouter ce format à la configuration? (O/N)"
                        
                        if ($response -eq "O" -or $response -eq "o") {
                            $addFormat = $true
                        }
                    }
                    "Silent" {
                        # Ajouter tous les formats
                        $addFormat = $true
                    }
                }
                
                if ($addFormat) {
                    # Créer le nouveau format
                    $formatName = "$($tagName)_$($Config.tag_formats.$tagName.formats.Count + 1)"
                    
                    $newFormat = @{
                        name = $formatName
                        pattern = $pattern.Pattern
                        description = $pattern.Description
                        example = $pattern.Example
                    }
                    
                    if ($pattern.IsComposite) {
                        $newFormat.composite = $true
                        $newFormat.value_groups = $pattern.ValueGroups
                        $newFormat.units = $pattern.Units
                    }
                    else {
                        $newFormat.value_group = $pattern.ValueGroup
                        $newFormat.unit = $pattern.Unit
                    }
                    
                    # Ajouter le format à la configuration
                    $Config.tag_formats.$tagName.formats += $newFormat
                    
                    Write-Host "Format '$formatName' ajouté avec succès pour le type de tag '$tagName'." -ForegroundColor Green
                    
                    $addedFormats += @{
                        TagType = $tagName
                        FormatName = $formatName
                        Description = $pattern.Description
                        Example = $pattern.Example
                    }
                }
            }
        }
        
        return $addedFormats
    }
    catch {
        Write-Error "Erreur lors de l'ajout des nouveaux formats à la configuration: $_"
        return @()
    }
}

# Fonction principale
function Invoke-TagFormatLearning {
    [CmdletBinding()]
    param (
        [string]$FilePath,
        [string]$Content,
        [string]$ConfigPath,
        [string]$OutputPath,
        [string]$Mode,
        [double]$ConfidenceThreshold,
        [switch]$Force
    )
    
    try {
        # Charger la configuration des formats de tags
        $tagFormats = Get-TagFormatsConfig -ConfigPath $ConfigPath
        
        if (-not $tagFormats) {
            return
        }
        
        # Charger le contenu si un chemin de fichier est spécifié
        if (-not [string]::IsNullOrEmpty($FilePath)) {
            if (-not (Test-Path -Path $FilePath)) {
                Write-Error "Le fichier spécifié n'existe pas: $FilePath"
                return
            }
            
            $Content = Get-Content -Path $FilePath -Raw
        }
        
        if ([string]::IsNullOrEmpty($Content)) {
            Write-Error "Aucun contenu à analyser. Spécifiez un fichier ou fournissez du contenu."
            return
        }
        
        # Détecter les tâches dans le contenu
        $tasks = Get-TasksFromContent -Content $Content
        
        if ($tasks.Count -eq 0) {
            Write-Warning "Aucune tâche détectée dans le contenu."
            return
        }
        
        # Détecter les potentiels nouveaux formats de tags
        $detectedFormats = Find-PotentialTagFormats -Tasks $tasks -TagFormats $tagFormats
        
        if ($detectedFormats.Count -eq 0) {
            Write-Host "Aucun nouveau format de tag détecté." -ForegroundColor Green
            return
        }
        
        # Créer des patterns regex pour les nouveaux formats
        $newPatterns = New-RegexPatterns -DetectedFormats $detectedFormats
        
        if ($newPatterns.Count -eq 0) {
            Write-Host "Aucun nouveau pattern regex créé." -ForegroundColor Green
            return
        }
        
        # Ajouter les nouveaux formats à la configuration
        $addedFormats = Add-NewFormatsToConfig -Config $tagFormats -NewPatterns $newPatterns -Mode $Mode -ConfidenceThreshold $ConfidenceThreshold
        
        if ($addedFormats.Count -eq 0) {
            Write-Host "Aucun nouveau format ajouté à la configuration." -ForegroundColor Yellow
            return
        }
        
        # Sauvegarder la configuration mise à jour
        $result = Save-TagFormatsConfig -Config $tagFormats -ConfigPath $ConfigPath
        
        if ($result) {
            Write-Host "`nRésumé des formats ajoutés:" -ForegroundColor Cyan
            
            foreach ($format in $addedFormats) {
                Write-Host "  - Type: $($format.TagType), Format: $($format.FormatName)" -ForegroundColor Green
                Write-Host "    Description: $($format.Description)" -ForegroundColor Gray
                Write-Host "    Exemple: $($format.Example)" -ForegroundColor Gray
                Write-Host ""
            }
            
            # Enregistrer le rapport si un chemin de sortie est spécifié
            if (-not [string]::IsNullOrEmpty($OutputPath)) {
                $report = "# Rapport d'apprentissage des formats de tags`n`n"
                $report += "## Résumé`n`n"
                $report += "- Nombre de tâches analysées: $($tasks.Count)`n"
                $report += "- Nombre de nouveaux formats détectés: $($detectedFormats.Count)`n"
                $report += "- Nombre de formats ajoutés: $($addedFormats.Count)`n`n"
                
                $report += "## Formats ajoutés`n`n"
                
                foreach ($format in $addedFormats) {
                    $report += "### Type: $($format.TagType), Format: $($format.FormatName)`n`n"
                    $report += "- Description: $($format.Description)`n"
                    $report += "- Exemple: $($format.Example)`n`n"
                }
                
                $report | Set-Content -Path $OutputPath -Encoding UTF8
                Write-Host "Rapport enregistré dans $OutputPath" -ForegroundColor Green
            }
        }
        
        return $addedFormats
    }
    catch {
        Write-Error "Erreur lors de l'apprentissage des formats de tags: $_"
        return $null
    }
}

# Exécuter la fonction principale
Invoke-TagFormatLearning -FilePath $FilePath -Content $Content -ConfigPath $ConfigPath -OutputPath $OutputPath -Mode $Mode -ConfidenceThreshold $ConfidenceThreshold -Force:$Force

