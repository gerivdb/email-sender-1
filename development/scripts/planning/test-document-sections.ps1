# Script de test pour identifier les sections principales du document d'expertise

# Paramètres
$FilePath = ".\development\data\planning\expertise-levels.md"

# Lire le contenu du fichier
$content = Get-Content -Path $FilePath -Raw

# Extraire les sections principales
$sections = @()
$lines = $content -split "`r?`n"
$sectionPattern = '^(#{1,3})\s+(.+)$'

foreach ($line in $lines) {
    if ($line -match $sectionPattern) {
        $level = $matches[1].Length
        $title = $matches[2]
        
        $sections += [PSCustomObject]@{
            Level = $level
            Title = $title
        }
    }
}

# Afficher les sections principales
Write-Host "Sections principales du document d'expertise :"
Write-Host "=============================================="
Write-Host ""

$sections | ForEach-Object {
    $indent = "  " * ($_.Level - 1)
    Write-Host "$indent- $($_.Title) (Niveau $($_.Level))"
}

# Identifier les sections importantes pour l'évaluation
Write-Host ""
Write-Host "Sections importantes pour l'évaluation :"
Write-Host "======================================="
Write-Host ""

$evaluationSections = $sections | Where-Object { 
    $_.Title -match "Critères|Évaluation|Matrice|Niveaux d'Expertise|Expertise" 
}

$evaluationSections | ForEach-Object {
    $indent = "  " * ($_.Level - 1)
    Write-Host "$indent- $($_.Title) (Niveau $($_.Level))"
}

# Résumé
Write-Host ""
Write-Host "Résumé :"
Write-Host "========"
Write-Host ""
Write-Host "Nombre total de sections : $($sections.Count)"
Write-Host "Nombre de sections de niveau 1 : $(($sections | Where-Object { $_.Level -eq 1 }).Count)"
Write-Host "Nombre de sections de niveau 2 : $(($sections | Where-Object { $_.Level -eq 2 }).Count)"
Write-Host "Nombre de sections de niveau 3 : $(($sections | Where-Object { $_.Level -eq 3 }).Count)"
Write-Host "Nombre de sections importantes pour l'évaluation : $($evaluationSections.Count)"
