# CompareViewer.ps1
# Module d'affichage de comparaison entre points de restauration
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$comparePath = Join-Path -Path $scriptPath -ChildPath "CompareManager.ps1"

if (Test-Path -Path $comparePath) {
    . $comparePath
} else {
    Write-Error "Le fichier CompareManager.ps1 est introuvable."
    exit 1
}

# Fonction pour afficher la comparaison côte à côte
function Show-SideBySideComparison {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Comparison,
        
        [Parameter(Mandatory = $false)]
        [int]$ConsoleWidth = 120,
        
        [Parameter(Mandatory = $false)]
        [switch]$HighlightDifferences,
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowOnlyDifferences
    )
    
    # Vérifier si la comparaison est valide
    if ($null -eq $Comparison -or $null -eq $Comparison.Point1 -or $null -eq $Comparison.Point2) {
        Write-Error "La comparaison est invalide."
        return
    }
    
    # Récupérer les points de restauration
    $point1 = $Comparison.Point1
    $point2 = $Comparison.Point2
    
    # Calculer la largeur de chaque colonne
    $columnWidth = [Math]::Floor(($ConsoleWidth - 3) / 2) # 3 caractères pour la séparation
    
    # Fonction pour formater une valeur
    function Format-Value {
        param (
            [Parameter(Mandatory = $false)]
            $Value,
            
            [Parameter(Mandatory = $false)]
            [int]$Width = $columnWidth
        )
        
        if ($null -eq $Value) {
            return "null"
        } elseif ($Value -is [System.Array]) {
            return "[$($Value -join ", ")]"
        } elseif ($Value -is [System.Collections.IDictionary]) {
            $result = "{"
            foreach ($key in $Value.Keys) {
                $result += "$key=$($Value[$key]), "
            }
            if ($result.Length -gt 1) {
                $result = $result.Substring(0, $result.Length - 2)
            }
            $result += "}"
            return $result
        } else {
            return $Value.ToString()
        }
    }
    
    # Fonction pour tronquer une chaîne à une largeur donnée
    function Limit-String {
        param (
            [Parameter(Mandatory = $true)]
            [string]$String,
            
            [Parameter(Mandatory = $false)]
            [int]$Width = $columnWidth
        )
        
        if ($String.Length -le $Width) {
            return $String.PadRight($Width)
        } else {
            return $String.Substring(0, $Width - 3) + "..."
        }
    }
    
    # Afficher l'en-tête
    Clear-Host
    Write-Host "=== COMPARAISON DE POINTS DE RESTAURATION ===" -ForegroundColor Cyan
    
    # Afficher les noms des points
    $name1 = if ($point1.PSObject.Properties.Match("Name").Count) { $point1.Name } else { "Point 1" }
    $name2 = if ($point2.PSObject.Properties.Match("Name").Count) { $point2.Name } else { "Point 2" }
    
    Write-Host (Limit-String -String $name1) -NoNewline -ForegroundColor Yellow
    Write-Host " | " -NoNewline -ForegroundColor DarkGray
    Write-Host (Limit-String -String $name2) -ForegroundColor Yellow
    
    # Afficher une ligne de séparation
    Write-Host ("-" * $columnWidth) -NoNewline -ForegroundColor DarkGray
    Write-Host "-+-" -NoNewline -ForegroundColor DarkGray
    Write-Host ("-" * $columnWidth) -ForegroundColor DarkGray
    
    # Afficher les propriétés communes
    if (-not $ShowOnlyDifferences) {
        Write-Host "`nPropriétés communes:" -ForegroundColor Green
        
        foreach ($property in $Comparison.CommonProperties | Sort-Object) {
            $value = Format-Value -Value $point1.$property
            
            Write-Host "$property: " -NoNewline -ForegroundColor White
            Write-Host $value -ForegroundColor DarkGray
        }
    }
    
    # Afficher les propriétés différentes
    Write-Host "`nPropriétés différentes:" -ForegroundColor Magenta
    
    foreach ($diff in $Comparison.DifferentProperties | Sort-Object -Property Property) {
        $property = $diff.Property
        $value1 = Format-Value -Value $diff.Value1
        $value2 = Format-Value -Value $diff.Value2
        
        Write-Host "$property:" -ForegroundColor White
        
        if ($HighlightDifferences) {
            # Mettre en évidence les différences
            Write-Host "  " -NoNewline
            Write-Host (Limit-String -String $value1) -NoNewline -ForegroundColor Red
            Write-Host " | " -NoNewline -ForegroundColor DarkGray
            Write-Host (Limit-String -String $value2) -ForegroundColor Red
        } else {
            # Affichage normal
            Write-Host "  " -NoNewline
            Write-Host (Limit-String -String $value1) -NoNewline -ForegroundColor DarkGray
            Write-Host " | " -NoNewline -ForegroundColor DarkGray
            Write-Host (Limit-String -String $value2) -ForegroundColor DarkGray
        }
    }
    
    # Afficher les propriétés uniques à chaque point
    Write-Host "`nPropriétés uniques au point 1:" -ForegroundColor Cyan
    
    foreach ($property in $Comparison.UniqueToPoint1 | Sort-Object) {
        $value = Format-Value -Value $point1.$property
        
        Write-Host "$property: " -NoNewline -ForegroundColor White
        Write-Host $value -ForegroundColor DarkGray
    }
    
    Write-Host "`nPropriétés uniques au point 2:" -ForegroundColor Cyan
    
    foreach ($property in $Comparison.UniqueToPoint2 | Sort-Object) {
        $value = Format-Value -Value $point2.$property
        
        Write-Host "$property: " -NoNewline -ForegroundColor White
        Write-Host $value -ForegroundColor DarkGray
    }
    
    # Afficher les différences de contenu si disponibles
    if ($null -ne $Comparison.ContentDifference) {
        Write-Host "`nDifférences de contenu:" -ForegroundColor Yellow
        Write-Host $Comparison.ContentDifference -ForegroundColor DarkGray
    }
    
    # Afficher les différences structurelles si disponibles
    if ($null -ne $Comparison.StructuralDifference) {
        Write-Host "`nDifférences structurelles:" -ForegroundColor Yellow
        Write-Host $Comparison.StructuralDifference -ForegroundColor DarkGray
    }
    
    # Afficher les statistiques de comparaison
    Write-Host "`nStatistiques de comparaison:" -ForegroundColor Cyan
    Write-Host "  Propriétés communes: $($Comparison.CommonProperties.Count)" -ForegroundColor White
    Write-Host "  Propriétés différentes: $($Comparison.DifferentProperties.Count)" -ForegroundColor White
    Write-Host "  Propriétés uniques au point 1: $($Comparison.UniqueToPoint1.Count)" -ForegroundColor White
    Write-Host "  Propriétés uniques au point 2: $($Comparison.UniqueToPoint2.Count)" -ForegroundColor White
    
    # Calculer le pourcentage de similitude
    $totalProperties = $Comparison.CommonProperties.Count + $Comparison.DifferentProperties.Count + 
                       $Comparison.UniqueToPoint1.Count + $Comparison.UniqueToPoint2.Count
    
    if ($totalProperties -gt 0) {
        $similarityPercentage = [Math]::Round(($Comparison.CommonProperties.Count / $totalProperties) * 100, 2)
        Write-Host "  Pourcentage de similitude: $similarityPercentage%" -ForegroundColor White
    }
}

# Fonction pour afficher la comparaison avec mise en évidence des différences
function Show-DifferenceHighlighting {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Comparison,
        
        [Parameter(Mandatory = $false)]
        [int]$ConsoleWidth = 120,
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowOnlyDifferences
    )
    
    # Appeler la fonction d'affichage côte à côte avec mise en évidence des différences
    Show-SideBySideComparison -Comparison $Comparison -ConsoleWidth $ConsoleWidth -HighlightDifferences -ShowOnlyDifferences:$ShowOnlyDifferences
}

# Fonction pour afficher les statistiques de changement
function Show-ChangeStatistics {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Comparison,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeChart
    )
    
    # Vérifier si la comparaison est valide
    if ($null -eq $Comparison -or $null -eq $Comparison.Point1 -or $null -eq $Comparison.Point2) {
        Write-Error "La comparaison est invalide."
        return
    }
    
    # Récupérer les points de restauration
    $point1 = $Comparison.Point1
    $point2 = $Comparison.Point2
    
    # Afficher l'en-tête
    Clear-Host
    Write-Host "=== STATISTIQUES DE CHANGEMENT ===" -ForegroundColor Cyan
    
    # Afficher les noms des points
    $name1 = if ($point1.PSObject.Properties.Match("Name").Count) { $point1.Name } else { "Point 1" }
    $name2 = if ($point2.PSObject.Properties.Match("Name").Count) { $point2.Name } else { "Point 2" }
    
    Write-Host "Comparaison entre:" -ForegroundColor White
    Write-Host "  $name1" -ForegroundColor Yellow
    Write-Host "  $name2" -ForegroundColor Yellow
    
    # Calculer les statistiques
    $commonCount = $Comparison.CommonProperties.Count
    $differentCount = $Comparison.DifferentProperties.Count
    $uniqueToPoint1Count = $Comparison.UniqueToPoint1.Count
    $uniqueToPoint2Count = $Comparison.UniqueToPoint2.Count
    $totalCount = $commonCount + $differentCount + $uniqueToPoint1Count + $uniqueToPoint2Count
    
    # Calculer les pourcentages
    $commonPercentage = if ($totalCount -gt 0) { [Math]::Round(($commonCount / $totalCount) * 100, 2) } else { 0 }
    $differentPercentage = if ($totalCount -gt 0) { [Math]::Round(($differentCount / $totalCount) * 100, 2) } else { 0 }
    $uniqueToPoint1Percentage = if ($totalCount -gt 0) { [Math]::Round(($uniqueToPoint1Count / $totalCount) * 100, 2) } else { 0 }
    $uniqueToPoint2Percentage = if ($totalCount -gt 0) { [Math]::Round(($uniqueToPoint2Count / $totalCount) * 100, 2) } else { 0 }
    
    # Afficher les statistiques
    Write-Host "`nStatistiques:" -ForegroundColor Cyan
    Write-Host "  Propriétés communes: $commonCount ($commonPercentage%)" -ForegroundColor Green
    Write-Host "  Propriétés différentes: $differentCount ($differentPercentage%)" -ForegroundColor Magenta
    Write-Host "  Propriétés uniques au point 1: $uniqueToPoint1Count ($uniqueToPoint1Percentage%)" -ForegroundColor Yellow
    Write-Host "  Propriétés uniques au point 2: $uniqueToPoint2Count ($uniqueToPoint2Percentage%)" -ForegroundColor Yellow
    Write-Host "  Total des propriétés: $totalCount" -ForegroundColor White
    
    # Afficher un graphique si demandé
    if ($IncludeChart) {
        Write-Host "`nGraphique de répartition:" -ForegroundColor Cyan
        
        # Déterminer la largeur du graphique
        $chartWidth = 50
        
        # Calculer les largeurs des barres
        $commonWidth = [Math]::Round(($commonCount / $totalCount) * $chartWidth)
        $differentWidth = [Math]::Round(($differentCount / $totalCount) * $chartWidth)
        $uniqueToPoint1Width = [Math]::Round(($uniqueToPoint1Count / $totalCount) * $chartWidth)
        $uniqueToPoint2Width = [Math]::Round(($uniqueToPoint2Count / $totalCount) * $chartWidth)
        
        # Ajuster les largeurs pour qu'elles totalisent exactement la largeur du graphique
        $totalWidth = $commonWidth + $differentWidth + $uniqueToPoint1Width + $uniqueToPoint2Width
        if ($totalWidth -lt $chartWidth) {
            $commonWidth += ($chartWidth - $totalWidth)
        } elseif ($totalWidth -gt $chartWidth) {
            $commonWidth -= ($totalWidth - $chartWidth)
        }
        
        # Afficher le graphique
        Write-Host "  " -NoNewline
        Write-Host ("█" * $commonWidth) -NoNewline -ForegroundColor Green
        Write-Host ("█" * $differentWidth) -NoNewline -ForegroundColor Magenta
        Write-Host ("█" * $uniqueToPoint1Width) -NoNewline -ForegroundColor Yellow
        Write-Host ("█" * $uniqueToPoint2Width) -ForegroundColor Cyan
        
        # Afficher la légende
        Write-Host "  " -NoNewline
        Write-Host "█ " -NoNewline -ForegroundColor Green
        Write-Host "Communes " -NoNewline -ForegroundColor White
        Write-Host "█ " -NoNewline -ForegroundColor Magenta
        Write-Host "Différentes " -NoNewline -ForegroundColor White
        Write-Host "█ " -NoNewline -ForegroundColor Yellow
        Write-Host "Uniques (1) " -NoNewline -ForegroundColor White
        Write-Host "█ " -NoNewline -ForegroundColor Cyan
        Write-Host "Uniques (2)" -ForegroundColor White
    }
    
    # Afficher les propriétés les plus modifiées
    if ($Comparison.DifferentProperties.Count -gt 0) {
        Write-Host "`nPropriétés modifiées:" -ForegroundColor Cyan
        
        foreach ($diff in $Comparison.DifferentProperties | Sort-Object -Property Property) {
            $property = $diff.Property
            $value1 = if ($null -eq $diff.Value1) { "null" } else { $diff.Value1.ToString() }
            $value2 = if ($null -eq $diff.Value2) { "null" } else { $diff.Value2.ToString() }
            
            Write-Host "  $property:" -ForegroundColor White
            Write-Host "    $name1: " -NoNewline -ForegroundColor Yellow
            Write-Host $value1 -ForegroundColor DarkGray
            Write-Host "    $name2: " -NoNewline -ForegroundColor Yellow
            Write-Host $value2 -ForegroundColor DarkGray
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Show-SideBySideComparison, Show-DifferenceHighlighting, Show-ChangeStatistics

