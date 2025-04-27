# Module de gÃ©nÃ©ration d'index pour le Script Manager
# Ce module gÃ©nÃ¨re un index global pour la documentation
# Author: Script Manager
# Version: 1.0
# Tags: documentation, index, scripts

function New-GlobalIndex {
    <#
    .SYNOPSIS
        GÃ©nÃ¨re un index global pour la documentation
    .DESCRIPTION
        CrÃ©e un index global qui rÃ©fÃ©rence tous les scripts et dossiers documentÃ©s
    .PARAMETER Analysis
        Objet d'analyse des scripts
    .PARAMETER OutputPath
        Chemin oÃ¹ enregistrer l'index
    .PARAMETER FolderReadmes
        RÃ©sultats de la gÃ©nÃ©ration des README de dossiers
    .PARAMETER ScriptDocs
        RÃ©sultats de la gÃ©nÃ©ration de la documentation des scripts
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
    
    Write-Host "GÃ©nÃ©ration de l'index global..." -ForegroundColor Cyan
    
    # CrÃ©er le chemin du fichier d'index
    $IndexPath = Join-Path -Path $OutputPath -ChildPath "index.md"
    
    # GÃ©nÃ©rer les statistiques
    $Stats = [PSCustomObject]@{
        TotalScripts = $Analysis.TotalScripts
        ScriptsByType = $Analysis.ScriptsByType
        TotalFolders = $FolderReadmes.Count
        DocumentedScripts = ($ScriptDocs | Where-Object { $_.Success } | Measure-Object).Count
        AverageQuality = [math]::Round($Analysis.AverageCodeQuality, 1)
        ScriptsWithProblems = $Analysis.ScriptsWithProblems
        ScriptsWithDependencies = $Analysis.ScriptsWithDependencies
    }
    
    # GÃ©nÃ©rer la liste des dossiers
    $FoldersList = $FolderReadmes | ForEach-Object {
        "- [**$($_.FolderName)**](folders/$($_.FolderName)/README.md) - $($_.ScriptCount) scripts"
    }
    
    # GÃ©nÃ©rer la liste des scripts par type
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
    
    # GÃ©nÃ©rer le contenu de l'index
    $IndexContent = @"
# Index de la documentation des scripts

## Vue d'ensemble

Cette documentation a Ã©tÃ© gÃ©nÃ©rÃ©e automatiquement par le Script Manager le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss").

### Statistiques

- **Nombre total de scripts:** $($Stats.TotalScripts)
- **Nombre de dossiers:** $($Stats.TotalFolders)
- **Scripts documentÃ©s:** $($Stats.DocumentedScripts)
- **Score de qualitÃ© moyen:** $($Stats.AverageQuality)/100
- **Scripts avec problÃ¨mes:** $($Stats.ScriptsWithProblems)
- **Scripts avec dÃ©pendances:** $($Stats.ScriptsWithDependencies)

### RÃ©partition par type

$($Stats.ScriptsByType | ForEach-Object {
    "- **$($_.Type):** $($_.Count) scripts"
} -join "`n")

## Dossiers

$($FoldersList -join "`n")

## Scripts

$($ScriptsLists -join "`n`n")

## Recherche

Utilisez la fonction de recherche de votre navigateur (Ctrl+F) pour trouver rapidement un script ou un dossier.

## Mise Ã  jour de la documentation

Pour mettre Ã  jour cette documentation, exÃ©cutez :

```powershell
.\scripts\manager\Phase3-DocumentAndMonitor.ps1
```

---

*Documentation gÃ©nÃ©rÃ©e par le Script Manager*
"@
    
    # Enregistrer l'index
    try {
        Set-Content -Path $IndexPath -Value $IndexContent
        Write-Host "  Index global gÃ©nÃ©rÃ©: $IndexPath" -ForegroundColor Green
        
        # CrÃ©er une copie de l'index comme README principal
        $ReadmePath = Join-Path -Path $OutputPath -ChildPath "README.md"
        Copy-Item -Path $IndexPath -Destination $ReadmePath -Force
        
        return [PSCustomObject]@{
            IndexPath = $IndexPath
            ReadmePath = $ReadmePath
            Success = $true
        }
    } catch {
        Write-Warning "Erreur lors de la crÃ©ation de l'index global : $_"
        
        return [PSCustomObject]@{
            IndexPath = $IndexPath
            Success = $false
            Error = $_.ToString()
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-GlobalIndex
