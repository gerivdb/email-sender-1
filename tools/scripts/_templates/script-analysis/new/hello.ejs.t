---
to: scripts/analysis/<%= subFolder ? subFolder + '/' : '' %><%= name %>.ps1
---
#Requires -Version 5.1
<#
.SYNOPSIS
    <%= description %>

.DESCRIPTION
    <%= description %>
    <%= additionalDescription ? additionalDescription : '' %>

.PARAMETER InputPath
    Chemin du fichier ou du répertoire à analyser.

.PARAMETER OutputPath
    Chemin du fichier de sortie pour les résultats de l'analyse.

.PARAMETER Format
    Format de sortie des résultats (JSON, CSV, HTML).

.EXAMPLE
    .\<%= name %>.ps1 -InputPath "C:\Scripts" -OutputPath "C:\Results\analyse.json" -Format JSON
    Analyse le répertoire spécifié et génère un rapport au format JSON.

.NOTES
    Auteur: <%= author || 'EMAIL_SENDER_1' %>
    Version: 1.0
    Date de création: <%= new Date().toISOString().split('T')[0] %>
    Tags: <%= tags || 'analysis, scripts' %>
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "CSV", "HTML")]
    [string]$Format = "JSON"
)

# Importer les modules nécessaires
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules"
$analysisModulePath = Join-Path -Path $modulesPath -ChildPath "AnalysisTools.psm1"

if (Test-Path $analysisModulePath) {
    Import-Module $analysisModulePath -Force
    Write-Verbose "Module AnalysisTools importé depuis $analysisModulePath"
}
else {
    Write-Warning "Module AnalysisTools non trouvé à l'emplacement $analysisModulePath"
}

# Fonction pour afficher un message coloré
function Write-ColorMessage {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Success", "Error", "Info", "Warning")]
        [string]$Type = "Info"
    )
    
    $colors = @{
        "Success" = "Green"
        "Error" = "Red"
        "Info" = "Cyan"
        "Warning" = "Yellow"
    }
    
    $prefix = @{
        "Success" = "✓"
        "Error" = "✗"
        "Info" = "ℹ"
        "Warning" = "⚠"
    }
    
    Write-Host "$($prefix[$Type]) $Message" -ForegroundColor $colors[$Type]
}

# Fonction pour générer un nom de fichier de sortie par défaut
function Get-DefaultOutputPath {
    param (
        [Parameter(Mandatory=$true)]
        [string]$InputPath,
        
        [Parameter(Mandatory=$true)]
        [string]$Format
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $inputName = [System.IO.Path]::GetFileNameWithoutExtension($InputPath)
    
    if ([string]::IsNullOrEmpty($inputName)) {
        $inputName = "analysis"
    }
    
    $extension = $Format.ToLower()
    
    $outputFileName = "${inputName}_${timestamp}.$extension"
    $outputPath = Join-Path -Path (Get-Location).Path -ChildPath $outputFileName
    
    return $outputPath
}

# Fonction pour analyser un fichier
function Analyze-File {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    
    Write-Verbose "Analyse du fichier: $FilePath"
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-ColorMessage "Le fichier n'existe pas: $FilePath" -Type Error
        return $null
    }
    
    # Obtenir les informations de base sur le fichier
    $fileInfo = Get-Item -Path $FilePath
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
    
    if (-not $content) {
        Write-ColorMessage "Impossible de lire le contenu du fichier: $FilePath" -Type Error
        return $null
    }
    
    # Effectuer l'analyse
    $result = [PSCustomObject]@{
        FilePath = $FilePath
        FileName = $fileInfo.Name
        FileSize = $fileInfo.Length
        LastModified = $fileInfo.LastWriteTime
        Extension = $fileInfo.Extension
        LineCount = ($content -split "`n").Count
        CharacterCount = $content.Length
        # TODO: Ajoutez ici votre logique d'analyse spécifique
    }
    
    return $result
}

# Fonction pour analyser un répertoire
function Analyze-Directory {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DirectoryPath
    )
    
    Write-Verbose "Analyse du répertoire: $DirectoryPath"
    
    # Vérifier si le répertoire existe
    if (-not (Test-Path -Path $DirectoryPath -PathType Container)) {
        Write-ColorMessage "Le répertoire n'existe pas: $DirectoryPath" -Type Error
        return $null
    }
    
    # Obtenir tous les fichiers du répertoire
    $files = Get-ChildItem -Path $DirectoryPath -Recurse -File -ErrorAction SilentlyContinue
    
    if (-not $files -or $files.Count -eq 0) {
        Write-ColorMessage "Aucun fichier trouvé dans le répertoire: $DirectoryPath" -Type Warning
        return @()
    }
    
    Write-ColorMessage "Analyse de $($files.Count) fichiers..." -Type Info
    
    $results = @()
    
    foreach ($file in $files) {
        $result = Analyze-File -FilePath $file.FullName
        if ($result) {
            $results += $result
        }
    }
    
    return $results
}

# Fonction pour exporter les résultats
function Export-Results {
    param (
        [Parameter(Mandatory=$true)]
        [array]$Results,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$true)]
        [string]$Format
    )
    
    # Créer le répertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Parent $OutputPath
    if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    # Exporter les résultats selon le format spécifié
    switch ($Format) {
        "JSON" {
            $Results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
        }
        "CSV" {
            $Results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        }
        "HTML" {
            $htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport d'analyse</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .header { margin-bottom: 20px; }
        .summary { margin: 20px 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Rapport d'analyse</h1>
        <p>Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>
    <div class="summary">
        <h2>Résumé</h2>
        <p>Nombre de fichiers analysés: $($Results.Count)</p>
    </div>
    <h2>Résultats détaillés</h2>
    <table>
        <tr>
            <th>Nom du fichier</th>
            <th>Taille (octets)</th>
            <th>Dernière modification</th>
            <th>Extension</th>
            <th>Nombre de lignes</th>
            <th>Nombre de caractères</th>
        </tr>
"@
            
            $htmlRows = $Results | ForEach-Object {
                @"
        <tr>
            <td>$($_.FileName)</td>
            <td>$($_.FileSize)</td>
            <td>$($_.LastModified)</td>
            <td>$($_.Extension)</td>
            <td>$($_.LineCount)</td>
            <td>$($_.CharacterCount)</td>
        </tr>
"@
            }
            
            $htmlFooter = @"
    </table>
</body>
</html>
"@
            
            $htmlContent = $htmlHeader + [string]::Join("`n", $htmlRows) + $htmlFooter
            Set-Content -Path $OutputPath -Value $htmlContent -Encoding UTF8
        }
    }
    
    Write-ColorMessage "Résultats exportés vers: $OutputPath" -Type Success
}

# Fonction principale
function Start-<%= h.changeCase.pascal(name) %> {
    [CmdletBinding()]
    param()
    
    # Vérifier le chemin d'entrée
    if (-not (Test-Path -Path $InputPath)) {
        Write-ColorMessage "Le chemin d'entrée spécifié n'existe pas: $InputPath" -Type Error
        return $false
    }
    
    # Déterminer si le chemin d'entrée est un fichier ou un répertoire
    $isFile = Test-Path -Path $InputPath -PathType Leaf
    
    # Effectuer l'analyse
    $results = if ($isFile) {
        Write-ColorMessage "Analyse du fichier: $InputPath" -Type Info
        @(Analyze-File -FilePath $InputPath)
    }
    else {
        Write-ColorMessage "Analyse du répertoire: $InputPath" -Type Info
        Analyze-Directory -DirectoryPath $InputPath
    }
    
    # Vérifier si des résultats ont été obtenus
    if (-not $results -or $results.Count -eq 0) {
        Write-ColorMessage "Aucun résultat d'analyse obtenu." -Type Warning
        return $false
    }
    
    Write-ColorMessage "Analyse terminée. $($results.Count) éléments analysés." -Type Success
    
    # Déterminer le chemin de sortie
    $finalOutputPath = if ([string]::IsNullOrEmpty($OutputPath)) {
        Get-DefaultOutputPath -InputPath $InputPath -Format $Format
    }
    else {
        $OutputPath
    }
    
    # Exporter les résultats
    Export-Results -Results $results -OutputPath $finalOutputPath -Format $Format
    
    return $true
}

# Exécuter la fonction principale
$result = Start-<%= h.changeCase.pascal(name) %>

# Afficher un résumé
if ($result) {
    Write-Host "`nAnalyse terminée avec succès." -ForegroundColor Green
}
else {
    Write-Host "`nL'analyse a échoué ou n'a produit aucun résultat." -ForegroundColor Red
}
