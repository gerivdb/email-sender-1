# Common-Functions.ps1
# Fonctions communes pour les scripts de métadonnées
# Version: 1.0
# Date: 2025-05-15

# Fonction pour écrire des messages de log
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Success", "Debug")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "Info" { 
            Write-Host $logMessage -ForegroundColor Gray 
        }
        "Warning" { 
            Write-Host $logMessage -ForegroundColor Yellow 
        }
        "Error" { 
            Write-Host $logMessage -ForegroundColor Red 
        }
        "Success" { 
            Write-Host $logMessage -ForegroundColor Green 
        }
        "Debug" { 
            if ($VerbosePreference -eq "Continue") {
                Write-Host $logMessage -ForegroundColor Cyan 
            }
        }
    }
}

# Fonction pour normaliser les unités de temps
function Get-NormalizedTimeUnit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Unit
    )
    
    $normalizedUnit = switch -Regex ($Unit.ToLower()) {
        "min(ute)?s?" { "Minutes" }
        "h(our)?s?" { "Hours" }
        "d(ay)?s?" { "Days" }
        "w(eek)?s?" { "Weeks" }
        "m(onth)?s?" { "Months" }
        "j(our)?s?" { "Days" } # Français
        "s(emaine)?s?" { "Weeks" } # Français
        "mois" { "Months" } # Français
        "heure?s?" { "Hours" } # Français
        default { "Hours" }
    }
    
    return $normalizedUnit
}

# Fonction pour convertir une valeur d'une unité à une autre
function Convert-TimeUnit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double]$Value,
        
        [Parameter(Mandatory = $true)]
        [string]$FromUnit,
        
        [Parameter(Mandatory = $true)]
        [string]$ToUnit
    )
    
    # Normaliser les unités
    $sourceUnit = Get-NormalizedTimeUnit -Unit $FromUnit
    $targetUnit = Get-NormalizedTimeUnit -Unit $ToUnit
    
    # Facteurs de conversion vers des heures
    $conversionFactors = @{
        "Minutes" = 1/60
        "Hours" = 1
        "Days" = 8       # 1 jour = 8 heures
        "Weeks" = 40     # 1 semaine = 40 heures (5 jours * 8 heures)
        "Months" = 160   # 1 mois = 160 heures (4 semaines * 40 heures)
    }
    
    # Convertir en heures d'abord
    $valueInHours = $Value * $conversionFactors[$sourceUnit]
    
    # Puis convertir de heures vers l'unité cible
    $convertedValue = $valueInHours / $conversionFactors[$targetUnit]
    
    # Arrondir à 2 décimales
    $convertedValue = [Math]::Round($convertedValue, 2)
    
    return $convertedValue
}

# Fonction pour extraire les tâches d'un contenu Markdown
function Get-TasksFromContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    $tasks = @()
    $lines = $Content -split "`n"
    
    foreach ($line in $lines) {
        if ($line -match '^\s*-\s*\[([ xX])\]\s*(.+)$') {
            $status = if ($matches[1] -match '[xX]') { "Completed" } else { "Pending" }
            $text = $matches[2]
            
            # Extraire l'ID de la tâche s'il est présent (format **ID**)
            $id = ""
            if ($text -match '\*\*([^\*]+)\*\*') {
                $id = $matches[1]
                $text = $text -replace '\*\*[^\*]+\*\*\s*', ''
            }
            
            $task = @{
                Id = $id
                Text = $text
                Status = $status
                Line = $line
            }
            
            $tasks += $task
        }
    }
    
    return $tasks
}

# Fonction pour extraire les tags d'une tâche
function Get-TagsFromTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Task,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath
    )
    
    $tags = @()
    $text = $Task.Text
    
    # Extraire les tags de type #tag
    $hashtagPattern = '#([a-zA-Z0-9_-]+)(?::([^#\s]+))?'
    $hashtagMatches = [regex]::Matches($text, $hashtagPattern)
    
    foreach ($match in $hashtagMatches) {
        $tagName = $match.Groups[1].Value
        $tagValue = if ($match.Groups.Count -gt 2) { $match.Groups[2].Value } else { "" }
        
        $tag = @{
            Type = "Hashtag"
            Name = $tagName
            Value = $tagValue
            FullMatch = $match.Value
        }
        
        $tags += $tag
    }
    
    # Si un fichier de configuration est fourni, extraire les tags personnalisés
    if ($ConfigPath -and (Test-Path -Path $ConfigPath)) {
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        
        foreach ($tagType in $config.tag_formats.PSObject.Properties.Name) {
            $tagTypeConfig = $config.tag_formats.$tagType
            
            foreach ($format in $tagTypeConfig.formats) {
                $pattern = $format.pattern
                $tagMatches = [regex]::Matches($text, $pattern)
                
                foreach ($match in $tagMatches) {
                    $value = $null
                    
                    if ($format.value_group -gt 0 -and $match.Groups.Count -gt $format.value_group) {
                        $value = $match.Groups[$format.value_group].Value
                    }
                    
                    $tag = @{
                        Type = $tagType
                        Name = $format.name
                        Value = $value
                        Unit = $format.unit
                        FullMatch = $match.Value
                    }
                    
                    $tags += $tag
                }
            }
        }
    }
    
    return $tags
}

# Fonction pour formater les résultats
function Format-Results {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Results,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "JSON", "CSV", "Table")]
        [string]$Format = "Text"
    )
    
    switch ($Format) {
        "JSON" {
            return $Results | ConvertTo-Json -Depth 10
        }
        "CSV" {
            return $Results | ConvertTo-Csv -NoTypeInformation
        }
        "Table" {
            return $Results | Format-Table -AutoSize | Out-String
        }
        default {
            $output = ""
            foreach ($result in $Results) {
                $output += "- $($result | Out-String)`n"
            }
            return $output
        }
    }
}
