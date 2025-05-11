# SimpleHtmlFormatTest.ps1
# Script de test simple pour la fonction Format-PreviewsAsHtml
# Version: 1.0
# Date: 2025-05-15

# Creer des previsualisations de test
$previews = @(
    [PSCustomObject]@{
        id = "doc1"
        title = "Rapport annuel 2024"
        snippet = "Ce rapport presente les resultats financiers de l'annee 2024."
        type = "document"
    },
    [PSCustomObject]@{
        id = "doc2"
        title = "Logo de l'entreprise"
        snippet = "Logo officiel de l'entreprise en haute resolution."
        type = "image"
    }
)

# Formater les previsualisations en HTML
$html = "<div class='search-results'>`n"

foreach ($preview in $previews) {
    $html += "  <div class='result-item'>`n"
    $html += "    <h3 class='result-title'>$($preview.title)</h3>`n"
    $html += "    <div class='result-type'>$($preview.type)</div>`n"
    $html += "    <div class='result-snippet'>$($preview.snippet)</div>`n"
    $html += "  </div>`n"
}

$html += "</div>"

# Afficher la sortie
Write-Output "Sortie HTML:"
Write-Output $html

# Ecrire le HTML dans un fichier pour pouvoir le visualiser
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$htmlPath = Join-Path -Path $scriptPath -ChildPath "preview_output.html"
$html | Out-File -FilePath $htmlPath -Encoding utf8
Write-Output "`nHTML ecrit dans le fichier: $htmlPath"
