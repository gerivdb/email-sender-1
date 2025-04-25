# Module de classification pour le Script Manager
# Ce module classe les scripts selon des règles définies
# Author: Script Manager
# Version: 1.0
# Tags: classification, scripts, organization

function Get-ScriptClassification {
    <#
    .SYNOPSIS
        Classifie un script selon les règles définies
    .DESCRIPTION
        Analyse un script et détermine sa catégorie et sa sous-catégorie selon les règles
    .PARAMETER Script
        Objet script à classifier
    .PARAMETER Rules
        Règles de classification
    .EXAMPLE
        Get-ScriptClassification -Script $script -Rules $rules
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Rules
    )
    
    # Initialiser l'objet de classification
    $Classification = [PSCustomObject]@{
        Category = "Unknown"
        SubCategory = "General"
        Score = 0
        MatchedRules = @()
    }
    
    # Trouver les règles applicables au type de script
    $ApplicableRules = @()
    foreach ($Rule in $Rules.rules) {
        foreach ($Pattern in $Rule.patterns) {
            $IsMatch = $false
            
            if ($Pattern.type -eq "regex") {
                $IsMatch = $Script.Path -match $Pattern.pattern
            } elseif ($Pattern.type -eq "extension") {
                $IsMatch = $Script.Path -like "*$($Pattern.pattern)"
            } elseif ($Pattern.type -eq "scriptType") {
                $IsMatch = $Script.Type -eq $Pattern.pattern
            }
            
            if ($IsMatch) {
                $ApplicableRules += $Rule
                break
            }
        }
    }
    
    # Si aucune règle n'est applicable, retourner la classification par défaut
    if ($ApplicableRules.Count -eq 0) {
        return $Classification
    }
    
    # Lire le contenu du script
    $Content = Get-Content -Path $Script.Path -Raw -ErrorAction SilentlyContinue
    
    # Évaluer chaque règle applicable
    $CategoryScores = @{}
    $SubCategoryScores = @{}
    $MatchedRules = @()
    
    foreach ($Rule in $ApplicableRules) {
        foreach ($Condition in $Rule.conditions) {
            $IsMatch = $false
            $MatchScore = 0
            
            # Évaluer la condition
            if ($Condition.field -eq "content" -and $Content) {
                if ($Condition.type -eq "regex") {
                    $Matches = [regex]::Matches($Content, $Condition.pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                    $MatchScore = $Matches.Count
                    $IsMatch = $MatchScore -gt 0
                } elseif ($Condition.type -eq "contains") {
                    $IsMatch = $Content -like "*$($Condition.pattern)*"
                    $MatchScore = if ($IsMatch) { 1 } else { 0 }
                }
            } elseif ($Condition.field -eq "path") {
                if ($Condition.type -eq "regex") {
                    $IsMatch = $Script.Path -match $Condition.pattern
                    $MatchScore = if ($IsMatch) { 1 } else { 0 }
                } elseif ($Condition.type -eq "contains") {
                    $IsMatch = $Script.Path -like "*$($Condition.pattern)*"
                    $MatchScore = if ($IsMatch) { 1 } else { 0 }
                }
            } elseif ($Condition.field -eq "name") {
                if ($Condition.type -eq "regex") {
                    $IsMatch = $Script.Name -match $Condition.pattern
                    $MatchScore = if ($IsMatch) { 1 } else { 0 }
                } elseif ($Condition.type -eq "contains") {
                    $IsMatch = $Script.Name -like "*$($Condition.pattern)*"
                    $MatchScore = if ($IsMatch) { 1 } else { 0 }
                }
            }
            
            # Si la condition est remplie, ajouter le score à la catégorie correspondante
            if ($IsMatch) {
                # Extraire la catégorie et la sous-catégorie de la destination
                $DestinationParts = $Condition.destination -split "/"
                $Category = $DestinationParts[1]  # scripts/category/subcategory
                $SubCategory = if ($DestinationParts.Count -gt 2) { $DestinationParts[2] } else { "General" }
                
                # Incrémenter le score de la catégorie
                if (-not $CategoryScores.ContainsKey($Category)) {
                    $CategoryScores[$Category] = 0
                }
                $CategoryScores[$Category] += $MatchScore
                
                # Incrémenter le score de la sous-catégorie
                $SubCategoryKey = "$Category/$SubCategory"
                if (-not $SubCategoryScores.ContainsKey($SubCategoryKey)) {
                    $SubCategoryScores[$SubCategoryKey] = 0
                }
                $SubCategoryScores[$SubCategoryKey] += $MatchScore
                
                # Ajouter la règle aux règles correspondantes
                $MatchedRules += [PSCustomObject]@{
                    RuleName = $Rule.name
                    Condition = $Condition.field
                    Pattern = $Condition.pattern
                    Score = $MatchScore
                    Destination = $Condition.destination
                }
            }
        }
    }
    
    # Déterminer la catégorie avec le score le plus élevé
    $BestCategory = $CategoryScores.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1
    
    if ($BestCategory) {
        $Classification.Category = $BestCategory.Name
        $Classification.Score = $BestCategory.Value
        
        # Déterminer la sous-catégorie avec le score le plus élevé pour cette catégorie
        $BestSubCategory = $SubCategoryScores.GetEnumerator() | 
            Where-Object { $_.Name -like "$($BestCategory.Name)/*" } | 
            Sort-Object -Property Value -Descending | 
            Select-Object -First 1
        
        if ($BestSubCategory) {
            $Classification.SubCategory = $BestSubCategory.Name -replace "$($BestCategory.Name)/", ""
        }
    }
    
    $Classification.MatchedRules = $MatchedRules
    
    return $Classification
}

function Get-TargetPath {
    <#
    .SYNOPSIS
        Détermine le chemin cible pour un script
    .DESCRIPTION
        Calcule le chemin cible pour un script en fonction de sa classification
    .PARAMETER Script
        Objet script à déplacer
    .PARAMETER Classification
        Classification du script
    .EXAMPLE
        Get-TargetPath -Script $script -Classification $classification
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Classification
    )
    
    # Déterminer le dossier cible en fonction de la classification
    $Category = $Classification.Category
    $SubCategory = $Classification.SubCategory
    
    # Construire le chemin cible
    $TargetFolder = "scripts"
    
    # Ajouter le dossier spécifique au type de script si nécessaire
    $TypeFolder = switch ($Script.Type) {
        "PowerShell" { "" }
        "Python" { "python/" }
        "Batch" { "batch/" }
        "Shell" { "shell/" }
        default { "" }
    }
    
    # Construire le chemin complet
    if ($Category -ne "Unknown") {
        $TargetFolder = "scripts/$TypeFolder$($Category.ToLower())"
        
        if ($SubCategory -ne "General") {
            $TargetFolder = "$TargetFolder/$($SubCategory.ToLower())"
        }
    }
    
    # Construire le chemin complet du fichier
    $TargetPath = Join-Path -Path $TargetFolder -ChildPath $Script.Name
    
    return $TargetPath
}

# Exporter les fonctions
Export-ModuleMember -Function Get-ScriptClassification, Get-TargetPath
