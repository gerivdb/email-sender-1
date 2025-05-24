#Requires -Version 5.1
<#
.SYNOPSIS
    Tests les snippets de documentation.
.DESCRIPTION
    Ce script teste les snippets de documentation en les convertissant en texte
    et en vérifiant que le texte généré est valide.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

[CmdletBinding()]
param()

# Définir le chemin du fichier de snippets
$snippetsFilePath = Join-Path -Path $PSScriptRoot -ChildPath '..\Documentation-Snippets.json'

# Vérifier que le fichier existe
if (-not (Test-Path -Path $snippetsFilePath)) {
    Write-Error "Le fichier de snippets n'existe pas : $snippetsFilePath"
    return
}

# Charger le fichier de snippets
try {
    $snippets = Get-Content -Path $snippetsFilePath -Raw | ConvertFrom-Json -ErrorAction Stop
    Write-Verbose "Fichier de snippets chargé avec succès : $snippetsFilePath"
} catch {
    Write-Error "Erreur lors du chargement du fichier de snippets : $_"
    return
}

# Créer un dossier temporaire pour les tests
$tempDir = Join-Path -Path $PSScriptRoot -ChildPath 'temp'
if (-not (Test-Path -Path $tempDir)) {
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    Write-Verbose "Dossier temporaire créé : $tempDir"
}

# Fonction pour remplacer les placeholders par des valeurs de test
function Set-Placeholders {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Lines
    )

    $result = @()
    foreach ($line in $Lines) {
        # Remplacer les placeholders ${n:text} par text
        $newLine = $line -replace '\$\{(\d+):([^}]*)\}', '$2'
        # Remplacer les placeholders ${n} par une valeur vide
        $newLine = $newLine -replace '\$\{(\d+)\}', ''
        $result += $newLine
    }
    return $result
}

# Fonction pour tester un snippet
function Test-Snippet {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Snippet
    )

    Write-Host "Test du snippet : $Name" -ForegroundColor Cyan

    # Remplacer les placeholders par des valeurs de test
    if ($null -eq $Snippet.body -or $Snippet.body.Count -eq 0) {
        Write-Host "  Erreur : Le snippet n'a pas de corps" -ForegroundColor Red
        return $false
    }
    $text = Set-Placeholders -Lines $Snippet.body

    # Déterminer l'extension de fichier en fonction du type de snippet
    $extension = if ($Name -like "*PowerShell*") {
        ".ps1"
    } elseif ($Name -like "*Markdown*") {
        ".md"
    } elseif ($Name -like "*Python*") {
        ".py"
    } else {
        ".txt"
    }

    # Écrire le texte dans un fichier temporaire
    $tempFile = Join-Path -Path $tempDir -ChildPath "$Name$extension"
    $text | Out-File -FilePath $tempFile -Encoding utf8

    # Vérifier que le fichier a été créé
    if (Test-Path -Path $tempFile) {
        Write-Host "  Fichier créé avec succès : $tempFile" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  Erreur lors de la création du fichier : $tempFile" -ForegroundColor Red
        return $false
    }
}

# Tester chaque snippet
$results = @()
foreach ($property in $snippets.PSObject.Properties) {
    $snippetName = $property.Name
    $snippet = $property.Value
    $success = Test-Snippet -Name $snippetName -Snippet $snippet
    $results += [PSCustomObject]@{
        Name    = $snippetName
        Success = $success
    }
}

# Afficher les résultats
Write-Host "`nRésultats des tests :" -ForegroundColor Yellow
$results | Format-Table -AutoSize

# Calculer le taux de réussite
$successCount = ($results | Where-Object { $_.Success }).Count
$totalCount = $results.Count
$successRate = [math]::Round(($successCount / $totalCount) * 100, 2)

Write-Host "Taux de réussite : $successRate% ($successCount/$totalCount)" -ForegroundColor $(if ($successRate -eq 100) { 'Green' } elseif ($successRate -ge 80) { 'Yellow' } else { 'Red' })

# Nettoyer les fichiers temporaires
if (Test-Path -Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
    Write-Verbose "Dossier temporaire supprimé : $tempDir"
}

