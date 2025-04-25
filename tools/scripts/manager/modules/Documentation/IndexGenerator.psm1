# Module de génération d'index pour le Script Manager
# Ce module génère un index global pour la documentation
# Author: Script Manager
# Version: 1.0
# Tags: documentation, index, scripts

function New-GlobalIndex {
    <#
    .SYNOPSIS
        Génère un index global pour la documentation
    .DESCRIPTION
        Crée un index global qui référence tous les scripts et dossiers documentés
    .PARAMETER Analysis
        Objet d'analyse des scripts
    .PARAMETER OutputPath
        Chemin où enregistrer l'index
    .PARAMETER FolderReadmes
        Résultats de la génération des README de dossiers
    .PARAMETER ScriptDocs
        Résultats de la génération de la documentation des scripts
    .EXAMPLE
        New-GlobalIndex -Analysis $analysis -OutputPath "docs" -FolderReadmes $readmes -ScriptDocs $docs
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Analysis,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$true)]
        [array]$FolderReadmes,
        
        [Parameter(Mandatory=$true)]
        [array]$ScriptDocs
    )
    
    Write-Host "Génération de l'index global..." -ForegroundColor Cyan
    
    # Créer le chemin du fichier d'index
    $IndexPath = Join-Path -Path $OutputPath -ChildPath "index.md"
    
    # Générer les statistiques
    $Stats = [PSCustomObject]@{
        TotalScripts = $Analysis.TotalScripts
        ScriptsByType = $Analysis.ScriptsByType
        TotalFolders = $FolderReadmes.Count
        DocumentedScripts = ($ScriptDocs | Where-Object { $_.Success } | Measure-Object).Count
        AverageQuality = [math]::Round($Analysis.AverageCodeQuality, 1)
        ScriptsWithProblems = $Analysis.ScriptsWithProblems
        ScriptsWithDependencies = $Analysis.ScriptsWithDependencies
    }
    
    # Générer la liste des dossiers
    $FoldersList = $FolderReadmes | ForEach-Object {
        "- [**$($_.FolderName)**](folders/$($_.FolderName)/README.md) - $($_.ScriptCount) scripts"
    }
    
    # Générer la liste des scripts par type
    $ScriptsByType = @{}
    foreach ($Script in $ScriptDocs | Where-Object { $_.Success }) {
        if (-not $ScriptsByType.ContainsKey($Script.Type)) {
            $ScriptsByType[$Script.Type] = @()
        }
        $ScriptsByType[$Script.Type] += $Script
    }
    
    $ScriptsLists = $ScriptsByType.Keys | Sort-Object | ForEach-Object {
        $Type = $_
        $TypeScripts = $ScriptsByType[$Type] | Sort-Object -Property ScriptName
        
        @"
### Scripts $Type

$($TypeScripts | ForEach-Object {
    "- [**$($_.ScriptName)**](scripts/$Type/$([System.IO.Path]::GetFileNameWithoutExtension($_.ScriptName)).md)"
} -join "`n")
"@
    }
    
    # Générer le contenu de l'index
    $IndexContent = @"
# Index de la documentation des scripts

## Vue d'ensemble

Cette documentation a été générée automatiquement par le Script Manager le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss").

### Statistiques

- **Nombre total de scripts:** $($Stats.TotalScripts)
- **Nombre de dossiers:** $($Stats.TotalFolders)
- **Scripts documentés:** $($Stats.DocumentedScripts)
- **Score de qualité moyen:** $($Stats.AverageQuality)/100
- **Scripts avec problèmes:** $($Stats.ScriptsWithProblems)
- **Scripts avec dépendances:** $($Stats.ScriptsWithDependencies)

### Répartition par type

$($Stats.ScriptsByType | ForEach-Object {
    "- **$($_.Type):** $($_.Count) scripts"
} -join "`n")

## Dossiers

$($FoldersList -join "`n")

## Scripts

$($ScriptsLists -join "`n`n")

## Recherche

Utilisez la fonction de recherche de votre navigateur (Ctrl+F) pour trouver rapidement un script ou un dossier.

## Mise à jour de la documentation

Pour mettre à jour cette documentation, exécutez :

```powershell
.\scripts\manager\Phase3-DocumentAndMonitor.ps1
```

---

*Documentation générée par le Script Manager*
"@
    
    # Enregistrer l'index
    try {
        Set-Content -Path $IndexPath -Value $IndexContent
        Write-Host "  Index global généré: $IndexPath" -ForegroundColor Green
        
        # Créer une copie de l'index comme README principal
        $ReadmePath = Join-Path -Path $OutputPath -ChildPath "README.md"
        Copy-Item -Path $IndexPath -Destination $ReadmePath -Force
        
        return [PSCustomObject]@{
            IndexPath = $IndexPath
            ReadmePath = $ReadmePath
            Success = $true
        }
    } catch {
        Write-Warning "Erreur lors de la création de l'index global : $_"
        
        return [PSCustomObject]@{
            IndexPath = $IndexPath
            Success = $false
            Error = $_.ToString()
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-GlobalIndex
