# TextNormalizationRules.ps1
# Script définissant les règles de normalisation textuelle pour les tâches de roadmap
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Définit les règles de normalisation textuelle pour les tâches de roadmap.

.DESCRIPTION
    Ce script définit les règles de normalisation textuelle pour les tâches de roadmap,
    notamment la standardisation de la casse, la normalisation des espaces et caractères spéciaux,
    et la gestion des encodages.

.NOTES
    Auteur: Équipe DevOps
    Date: 2025-05-15
    Version: 1.0
#>

# Structure définissant les règles de normalisation textuelle
$script:TextNormalizationRules = @{
    # Règles de standardisation de la casse
    Case = @{
        # Standardisation de la casse pour les titres (première lettre en majuscule)
        Title = {
            param($text)
            if ([string]::IsNullOrWhiteSpace($text)) { return $text }
            
            # Première lettre en majuscule, reste en minuscule
            return (Get-Culture).TextInfo.ToTitleCase($text.ToLower())
        }
        
        # Standardisation de la casse pour les identifiants (conserver tels quels)
        Id = {
            param($text)
            return $text
        }
        
        # Standardisation de la casse pour les statuts (PascalCase)
        Status = {
            param($text)
            if ([string]::IsNullOrWhiteSpace($text)) { return $text }
            
            # Convertir en PascalCase
            $words = $text -split '[\s_-]+'
            $pascalCase = ($words | ForEach-Object { (Get-Culture).TextInfo.ToTitleCase($_.ToLower()) }) -join ''
            return $pascalCase
        }
        
        # Standardisation de la casse pour les tags (minuscules)
        Tag = {
            param($text)
            if ([string]::IsNullOrWhiteSpace($text)) { return $text }
            
            # Convertir en minuscules
            return $text.ToLower()
        }
        
        # Standardisation de la casse pour les catégories (PascalCase)
        Category = {
            param($text)
            if ([string]::IsNullOrWhiteSpace($text)) { return $text }
            
            # Convertir en PascalCase
            $words = $text -split '[\s_-]+'
            $pascalCase = ($words | ForEach-Object { (Get-Culture).TextInfo.ToTitleCase($_.ToLower()) }) -join ''
            return $pascalCase
        }
    }
    
    # Règles de normalisation des espaces et caractères spéciaux
    Spaces = @{
        # Normalisation des espaces pour les titres (supprimer les espaces multiples)
        Title = {
            param($text)
            if ([string]::IsNullOrWhiteSpace($text)) { return $text }
            
            # Supprimer les espaces multiples et les espaces en début/fin
            return ($text -replace '\s+', ' ').Trim()
        }
        
        # Normalisation des espaces pour les descriptions (préserver les sauts de ligne)
        Description = {
            param($text)
            if ([string]::IsNullOrWhiteSpace($text)) { return $text }
            
            # Supprimer les espaces multiples mais préserver les sauts de ligne
            $lines = $text -split '\r?\n'
            $normalizedLines = $lines | ForEach-Object { ($_ -replace '\s+', ' ').Trim() }
            return $normalizedLines -join "`n"
        }
        
        # Normalisation des espaces pour les tags (supprimer tous les espaces)
        Tag = {
            param($text)
            if ([string]::IsNullOrWhiteSpace($text)) { return $text }
            
            # Supprimer tous les espaces
            return $text -replace '\s+', ''
        }
    }
    
    # Règles de normalisation des caractères spéciaux
    SpecialChars = @{
        # Normalisation des caractères spéciaux pour les identifiants (conserver uniquement les chiffres et points)
        Id = {
            param($text)
            if ([string]::IsNullOrWhiteSpace($text)) { return $text }
            
            # Conserver uniquement les chiffres et points
            return $text -replace '[^0-9\.]', ''
        }
        
        # Normalisation des caractères spéciaux pour les titres (remplacer les caractères non imprimables)
        Title = {
            param($text)
            if ([string]::IsNullOrWhiteSpace($text)) { return $text }
            
            # Remplacer les caractères non imprimables par des espaces
            $normalizedText = $text
            $normalizedText = $normalizedText -replace '[\x00-\x1F\x7F]', ' '
            
            # Normaliser les guillemets
            $normalizedText = $normalizedText -replace '[\u201C\u201D\u201E\u201F\u2033\u2036]', '"'
            $normalizedText = $normalizedText -replace '[\u2018\u2019\u201A\u201B\u2032\u2035]', "'"
            
            # Normaliser les tirets
            $normalizedText = $normalizedText -replace '[\u2013\u2014\u2015]', '-'
            
            # Normaliser les points de suspension
            $normalizedText = $normalizedText -replace '\u2026', '...'
            
            return $normalizedText
        }
        
        # Normalisation des caractères spéciaux pour les descriptions (préserver la plupart des caractères)
        Description = {
            param($text)
            if ([string]::IsNullOrWhiteSpace($text)) { return $text }
            
            # Remplacer uniquement les caractères non imprimables
            $normalizedText = $text
            $normalizedText = $normalizedText -replace '[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]', ' '
            
            return $normalizedText
        }
        
        # Normalisation des caractères spéciaux pour les tags (conserver uniquement les caractères alphanumériques et tirets)
        Tag = {
            param($text)
            if ([string]::IsNullOrWhiteSpace($text)) { return $text }
            
            # Conserver uniquement les caractères alphanumériques et tirets
            return $text -replace '[^a-zA-Z0-9\-_]', ''
        }
    }
    
    # Règles de gestion des encodages
    Encoding = @{
        # Normalisation des encodages pour tous les champs textuels
        Text = {
            param($text)
            if ([string]::IsNullOrWhiteSpace($text)) { return $text }
            
            # Convertir en UTF-8
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
            return [System.Text.Encoding]::UTF8.GetString($bytes)
        }
    }
}

# Fonction pour normaliser un texte selon les règles spécifiées
function ConvertTo-Text {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Title", "Description", "Id", "Status", "Tag", "Category")]
        [string]$FieldType,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Case", "Spaces", "SpecialChars", "Encoding", "All")]
        [string[]]$Rules = @("All")
    )
    
    $normalizedText = $Text
    
    # Appliquer les règles spécifiées
    if ($Rules -contains "All" -or $Rules -contains "Encoding") {
        $normalizedText = & $script:TextNormalizationRules.Encoding.Text $normalizedText
    }
    
    if ($Rules -contains "All" -or $Rules -contains "Spaces") {
        if ($script:TextNormalizationRules.Spaces.ContainsKey($FieldType)) {
            $normalizedText = & $script:TextNormalizationRules.Spaces[$FieldType] $normalizedText
        }
        else {
            $normalizedText = & $script:TextNormalizationRules.Spaces.Title $normalizedText
        }
    }
    
    if ($Rules -contains "All" -or $Rules -contains "SpecialChars") {
        if ($script:TextNormalizationRules.SpecialChars.ContainsKey($FieldType)) {
            $normalizedText = & $script:TextNormalizationRules.SpecialChars[$FieldType] $normalizedText
        }
        else {
            $normalizedText = & $script:TextNormalizationRules.SpecialChars.Title $normalizedText
        }
    }
    
    if ($Rules -contains "All" -or $Rules -contains "Case") {
        if ($script:TextNormalizationRules.Case.ContainsKey($FieldType)) {
            $normalizedText = & $script:TextNormalizationRules.Case[$FieldType] $normalizedText
        }
        else {
            $normalizedText = & $script:TextNormalizationRules.Case.Title $normalizedText
        }
    }
    
    return $normalizedText
}

# Fonction pour normaliser un tableau de textes
function ConvertTo-TextArray {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$TextArray,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Tag", "Category")]
        [string]$FieldType,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Case", "Spaces", "SpecialChars", "Encoding", "All")]
        [string[]]$Rules = @("All")
    )
    
    $normalizedArray = @()
    
    foreach ($text in $TextArray) {
        $normalizedText = ConvertTo-Text -Text $text -FieldType $FieldType -Rules $Rules
        $normalizedArray += $normalizedText
    }
    
    # Supprimer les doublons
    $normalizedArray = $normalizedArray | Select-Object -Unique
    
    # Supprimer les valeurs vides
    $normalizedArray = $normalizedArray | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    
    return $normalizedArray
}

# Fonction pour normaliser une tâche complète
function ConvertTo-TaskText {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$Task
    )
    
    process {
        # Normaliser les champs textuels de la tâche
        if ($Task.PSObject.Properties.Name.Contains("title")) {
            $Task.title = ConvertTo-Text -Text $Task.title -FieldType "Title"
        }
        
        if ($Task.PSObject.Properties.Name.Contains("description")) {
            $Task.description = ConvertTo-Text -Text $Task.description -FieldType "Description"
        }
        
        if ($Task.PSObject.Properties.Name.Contains("id")) {
            $Task.id = ConvertTo-Text -Text $Task.id -FieldType "Id"
        }
        
        if ($Task.PSObject.Properties.Name.Contains("status")) {
            $Task.status = ConvertTo-Text -Text $Task.status -FieldType "Status"
        }
        
        if ($Task.PSObject.Properties.Name.Contains("category")) {
            $Task.category = ConvertTo-Text -Text $Task.category -FieldType "Category"
        }
        
        if ($Task.PSObject.Properties.Name.Contains("tags") -and $Task.tags -is [array]) {
            $Task.tags = ConvertTo-TextArray -TextArray $Task.tags -FieldType "Tag"
        }
        
        return $Task
    }
}

# Exporter les fonctions
Export-ModuleMember -function ConvertTo-Text, ConvertTo-TextArray, ConvertTo-TaskText

