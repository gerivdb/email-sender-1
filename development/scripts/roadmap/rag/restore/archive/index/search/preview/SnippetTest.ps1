# SnippetTest.ps1
# Script de test pour la fonction Get-TextSnippet
# Version: 1.0
# Date: 2025-05-15

# Fonction pour generer un extrait de texte autour des termes de recherche
function Get-TextSnippet {
    param (
        [string]$Text,
        [string]$SearchTerm,
        [int]$ContextLength = 50
    )
    
    # Si le texte est vide, retourner une chaine vide
    if ([string]::IsNullOrEmpty($Text)) {
        return ""
    }
    
    # Preparer les valeurs pour la recherche
    $compareText = $Text.ToLower()
    $compareTerm = $SearchTerm.ToLower()
    
    # Trouver la position du terme de recherche
    $position = $compareText.IndexOf($compareTerm)
    
    # Si le terme n'est pas trouve, retourner une chaine vide
    if ($position -eq -1) {
        return ""
    }
    
    # Calculer les positions de debut et de fin de l'extrait
    $startPos = [Math]::Max(0, $position - $ContextLength)
    $endPos = [Math]::Min($Text.Length, $position + $SearchTerm.Length + $ContextLength)
    
    # Extraire l'extrait
    $length = $endPos - $startPos
    $snippet = $Text.Substring($startPos, $length)
    
    # Ajouter des points de suspension si necessaire
    if ($startPos -gt 0) {
        $snippet = "..." + $snippet
    }
    
    if ($endPos -lt $Text.Length) {
        $snippet = $snippet + "..."
    }
    
    # Mettre en evidence le terme de recherche
    $originalTerm = $Text.Substring($position, $SearchTerm.Length)
    $snippet = $snippet.Replace($originalTerm, "[$originalTerm]")
    
    return $snippet
}

# Tester la fonction Get-TextSnippet
$text = "Ce rapport presente les resultats financiers de l'annee 2024. Les revenus ont augmente de 15% par rapport a l'annee precedente."
$searchTerm = "resultats"
$snippet = Get-TextSnippet -Text $text -SearchTerm $searchTerm -ContextLength 20
Write-Output "Texte original: $text"
Write-Output "Terme de recherche: $searchTerm"
Write-Output "Extrait: $snippet"

# Tester avec un terme qui n'existe pas
$searchTerm = "inexistant"
$snippet = Get-TextSnippet -Text $text -SearchTerm $searchTerm -ContextLength 20
Write-Output "`nTerme de recherche: $searchTerm"
Write-Output "Extrait: $snippet"

# Tester avec un texte vide
$text = ""
$searchTerm = "resultats"
$snippet = Get-TextSnippet -Text $text -SearchTerm $searchTerm -ContextLength 20
Write-Output "`nTexte vide"
Write-Output "Terme de recherche: $searchTerm"
Write-Output "Extrait: $snippet"

# Tester avec un terme au debut du texte
$text = "Resultats financiers de l'annee 2024. Les revenus ont augmente de 15% par rapport a l'annee precedente."
$searchTerm = "Resultats"
$snippet = Get-TextSnippet -Text $text -SearchTerm $searchTerm -ContextLength 20
Write-Output "`nTerme au debut du texte"
Write-Output "Texte: $text"
Write-Output "Terme de recherche: $searchTerm"
Write-Output "Extrait: $snippet"

# Tester avec un terme a la fin du texte
$text = "Ce rapport presente les resultats financiers de l'annee 2024. Les revenus ont augmente de 15% par rapport a l'annee precedente. Conclusion."
$searchTerm = "Conclusion"
$snippet = Get-TextSnippet -Text $text -SearchTerm $searchTerm -ContextLength 20
Write-Output "`nTerme a la fin du texte"
Write-Output "Texte: $text"
Write-Output "Terme de recherche: $searchTerm"
Write-Output "Extrait: $snippet"
