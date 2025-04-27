﻿# Module de documentation des scripts pour le Script Manager
# Ce module gÃ©nÃ¨re de la documentation pour chaque script
# Author: Script Manager
# Version: 1.0
# Tags: documentation, scripts, manager

function New-ScriptDocumentation {
    <#
    .SYNOPSIS
        GÃ©nÃ¨re la documentation pour chaque script
    .DESCRIPTION
        Analyse chaque script et gÃ©nÃ¨re un fichier de documentation avec
        les informations sur le script, ses fonctions, paramÃ¨tres et exemples
    .PARAMETER Analysis
        Objet d'analyse des scripts
    .PARAMETER OutputPath
        Chemin oÃ¹ enregistrer la documentation
    .PARAMETER IncludeExamples
        Inclut des exemples d'utilisation dans la documentation
    .EXAMPLE
        New-ScriptDocumentation -Analysis $analysis -OutputPath "docs" -IncludeExamples
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Analysis,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [switch]$IncludeExamples
    )
    
    # CrÃ©er un tableau pour stocker les rÃ©sultats
    $Results = @()
    
    # CrÃ©er le dossier de documentation des scripts
    $ScriptsDocPath = Join-Path -Path $OutputPath -ChildPath "scripts"
    if (-not (Test-Path -Path $ScriptsDocPath)) {
        New-Item -ItemType Directory -Path $ScriptsDocPath -Force | Out-Null
    }
    
    Write-Host "GÃ©nÃ©ration de documentation pour $($Analysis.TotalScripts) scripts..." -ForegroundColor Cyan
    
    # Traiter chaque script
    $Counter = 0
    $Total = $Analysis.Scripts.Count
    
    foreach ($Script in $Analysis.Scripts) {
        $Counter++
        $Progress = [math]::Round(($Counter / $Total) * 100)
        Write-Progress -Activity "Documentation des scripts" -Status "$Counter / $Total ($Progress%)" -PercentComplete $Progress
        
        # CrÃ©er le dossier pour le type de script
        $ScriptTypeFolder = Join-Path -Path $ScriptsDocPath -ChildPath $Script.Type
        if (-not (Test-Path -Path $ScriptTypeFolder)) {
            New-Item -ItemType Directory -Path $ScriptTypeFolder -Force | Out-Null
        }
        
        # CrÃ©er le nom du fichier de documentation
        $DocFileName = [System.IO.Path]::GetFileNameWithoutExtension($Script.Name) + ".md"
        $DocFilePath = Join-Path -Path $ScriptTypeFolder -ChildPath $DocFileName
        
        # GÃ©nÃ©rer le contenu de la documentation
        $DocContent = Get-ScriptDocContent -Script $Script -IncludeExamples:$IncludeExamples
        
        # Enregistrer la documentation
        try {
            Set-Content -Path $DocFilePath -Value $DocContent
            
            # Ajouter le rÃ©sultat au tableau
            $Results += [PSCustomObject]@{
                ScriptPath = $Script.Path
                ScriptName = $Script.Name
                DocPath = $DocFilePath
                Type = $Script.Type
                Success = $true
            }
        } catch {
            Write-Warning "Erreur lors de la crÃ©ation de la documentation pour $($Script.Path) : $_"
            
            # Ajouter le rÃ©sultat au tableau
            $Results += [PSCustomObject]@{
                ScriptPath = $Script.Path
                ScriptName = $Script.Name
                DocPath = $DocFilePath
                Type = $Script.Type
                Success = $false
                Error = $_.ToString()
            }
        }
    }
    
    Write-Progress -Activity "Documentation des scripts" -Completed
    
    Write-Host "Documentation gÃ©nÃ©rÃ©e pour $($Results | Where-Object { $_.Success } | Measure-Object).Count scripts" -ForegroundColor Green
    
    return $Results
}

function Get-ScriptDocContent {
    <#
    .SYNOPSIS
        GÃ©nÃ¨re le contenu de la documentation pour un script
    .DESCRIPTION
        CrÃ©e un contenu de documentation adaptÃ© au script, incluant
        les informations sur le script, ses fonctions, paramÃ¨tres et exemples
    .PARAMETER Script
        Objet script Ã  documenter
    .PARAMETER IncludeExamples
        Inclut des exemples d'utilisation dans la documentation
    .EXAMPLE
        Get-ScriptDocContent -Script $script -IncludeExamples
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script,
        
        [switch]$IncludeExamples
    )
    
    # Lire le contenu du script
    $Content = Get-Content -Path $Script.Path -Raw -ErrorAction SilentlyContinue
    
    # Extraire les informations du script
    $ScriptInfo = @{
        Name = $Script.Name
        Path = $Script.Path
        Type = $Script.Type
        Size = $Script.StaticAnalysis.LineCount
        Functions = $Script.StaticAnalysis.Functions
        Dependencies = $Script.Dependencies | ForEach-Object { $_.Name }
        Description = ""
        Author = ""
        Version = ""
        Tags = @()
    }
    
    # Essayer d'extraire des mÃ©tadonnÃ©es des commentaires
    $CommentLines = (Get-Content -Path $Script.Path -TotalCount 20) -match "^#"
    foreach ($Line in $CommentLines) {
        if ($Line -match "^#\s*Description:?\s*(.+)$") {
            $ScriptInfo.Description = $Matches[1]
        } elseif ($Line -match "^#\s*Author:?\s*(.+)$") {
            $ScriptInfo.Author = $Matches[1]
        } elseif ($Line -match "^#\s*Version:?\s*(.+)$") {
            $ScriptInfo.Version = $Matches[1]
        } elseif ($Line -match "^#\s*Tags?:?\s*(.+)$") {
            $ScriptInfo.Tags = $Matches[1] -split "," | ForEach-Object { $_.Trim() }
        }
    }
    
    # Si aucune description n'a Ã©tÃ© trouvÃ©e, utiliser la premiÃ¨re ligne de commentaire
    if ([string]::IsNullOrWhiteSpace($ScriptInfo.Description) -and $CommentLines.Count -gt 0) {
        $ScriptInfo.Description = $CommentLines[0] -replace "^#\s*", ""
    }
    
    # GÃ©nÃ©rer la documentation des fonctions
    $FunctionDocs = @()
    foreach ($Function in $ScriptInfo.Functions) {
        # Essayer de trouver la dÃ©finition de la fonction
        $FunctionMatch = [regex]::Match($Content, "function\s+$([regex]::Escape($Function))\s*{([^}]*)}|function\s+$([regex]::Escape($Function))\s*\(([^)]*)\)")
        
        if ($FunctionMatch.Success) {
            $FunctionContent = $FunctionMatch.Value
            
            # Essayer d'extraire les paramÃ¨tres
            $Parameters = @()
            $ParamMatches = [regex]::Matches($FunctionContent, "\[Parameter\([^\)]*\)\]\s*\[([^\]]*)\]\s*\$(\w+)")
            
            foreach ($ParamMatch in $ParamMatches) {
                $Parameters += [PSCustomObject]@{
                    Name = $ParamMatch.Groups[2].Value
                    Type = $ParamMatch.Groups[1].Value
                }
            }
            
            # Essayer d'extraire la documentation de la fonction (commentaires help)
            $HelpMatch = [regex]::Match($FunctionContent, "<#(.*?)#>", [System.Text.RegularExpressions.RegexOptions]::Singleline)
            $Synopsis = ""
            $Description = ""
            $Example = ""
            
            if ($HelpMatch.Success) {
                $HelpContent = $HelpMatch.Groups[1].Value
                
                # Extraire le synopsis
                $SynopsisMatch = [regex]::Match($HelpContent, "\.SYNOPSIS\s*(.*?)(\.\w+|$)", [System.Text.RegularExpressions.RegexOptions]::Singleline)
                if ($SynopsisMatch.Success) {
                    $Synopsis = $SynopsisMatch.Groups[1].Value.Trim()
                }
                
                # Extraire la description
                $DescriptionMatch = [regex]::Match($HelpContent, "\.DESCRIPTION\s*(.*?)(\.\w+|$)", [System.Text.RegularExpressions.RegexOptions]::Singleline)
                if ($DescriptionMatch.Success) {
                    $Description = $DescriptionMatch.Groups[1].Value.Trim()
                }
                
                # Extraire un exemple
                $ExampleMatch = [regex]::Match($HelpContent, "\.EXAMPLE\s*(.*?)(\.\w+|$)", [System.Text.RegularExpressions.RegexOptions]::Singleline)
                if ($ExampleMatch.Success) {
                    $Example = $ExampleMatch.Groups[1].Value.Trim()
                }
            }
            
            $FunctionDocs += [PSCustomObject]@{
                Name = $Function
                Synopsis = $Synopsis
                Description = $Description
                Parameters = $Parameters
                Example = $Example
            }
        }
    }
    
    # GÃ©nÃ©rer des exemples d'utilisation
    $Examples = @()
    if ($IncludeExamples) {
        switch ($Script.Type) {
            "PowerShell" {
                $Examples += @"
### Exemple d'utilisation basique

```powershell
# ExÃ©cuter le script
.\$($Script.Name)
```
"@
                
                # Si le script a des fonctions, ajouter des exemples pour les fonctions
                if ($FunctionDocs.Count -gt 0) {
                    $Examples += @"
### Exemple d'utilisation des fonctions

```powershell
# Importer le script comme module
Import-Module .\$($Script.Name)

# Utiliser les fonctions
$($FunctionDocs[0].Name) -Parameter Value
```
"@
                }
            }
            "Python" {
                $Examples += @"
### Exemple d'utilisation basique

```python
# ExÃ©cuter le script
python $($Script.Name)
```
"@
            }
            "Batch" {
                $Examples += @"
### Exemple d'utilisation basique

```batch
# ExÃ©cuter le script
$($Script.Name)
```
"@
            }
            "Shell" {
                $Examples += @"
### Exemple d'utilisation basique

```bash
# ExÃ©cuter le script
bash $($Script.Name)
```
"@
            }
        }
    }
    
    # GÃ©nÃ©rer le contenu complet de la documentation
    $DocContent = @"
# $($Script.Name)

## Informations gÃ©nÃ©rales

- **Nom:** $($Script.Name)
- **Type:** $($Script.Type)
- **Chemin:** $($Script.Path)
- **Taille:** $($Script.StaticAnalysis.LineCount) lignes
- **Auteur:** $($ScriptInfo.Author)
- **Version:** $($ScriptInfo.Version)
- **Tags:** $($ScriptInfo.Tags -join ", ")

## Description

$($ScriptInfo.Description)

## DÃ©pendances

$($ScriptInfo.Dependencies -join ", ")

## Fonctions

$($FunctionDocs | ForEach-Object {
@"
### $($_.Name)

$($_.Synopsis)

$($_.Description)

#### ParamÃ¨tres

$($_.Parameters | ForEach-Object { "- **$($_.Name)** ($($_.Type))" } -join "`n")

#### Exemple

```powershell
$($_.Example)
```

"@
})

## Exemples d'utilisation

$($Examples -join "`n`n")

## ProblÃ¨mes potentiels

$($Script.Problems | ForEach-Object {
@"
- **$($_.Type) - $($_.Severity):** $($_.Message)
  - $($_.Details)
  - Recommandation: $($_.Recommendation)
"@
} -join "`n")

## QualitÃ© du code

- **Score:** $($Script.CodeQuality.Score)/$($Script.CodeQuality.MaxScore)
- **Ratio de commentaires:** $([math]::Round($Script.CodeQuality.Metrics.CommentRatio * 100, 1))%
- **ComplexitÃ©:** $($Script.CodeQuality.Metrics.ComplexityScore)

## Recommandations

$($Script.CodeQuality.Recommendations -join "`n")

---

*Documentation gÃ©nÃ©rÃ©e automatiquement par le Script Manager le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*
"@
    
    return $DocContent
}

# Exporter les fonctions
Export-ModuleMember -Function New-ScriptDocumentation, Get-ScriptDocContent
