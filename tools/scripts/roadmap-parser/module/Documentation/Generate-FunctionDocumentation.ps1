<#
.SYNOPSIS
    Génère la documentation des fonctions du module RoadmapParser.

.DESCRIPTION
    Ce script analyse les fonctions du module RoadmapParser et génère
    une documentation complète au format Markdown. Il extrait les commentaires
    d'aide, les paramètres, les types de retour et les exemples.

.PARAMETER OutputPath
    Chemin où enregistrer la documentation générée. Par défaut: "docs/api".

.PARAMETER IncludePrivateFunctions
    Indique s'il faut inclure les fonctions privées dans la documentation.

.PARAMETER GenerateHtmlDocs
    Indique s'il faut générer également une documentation HTML.

.EXAMPLE
    .\Generate-FunctionDocumentation.ps1 -OutputPath "docs/api" -GenerateHtmlDocs

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-05-15
#>

[CmdletBinding()]
param(
    [string]$OutputPath = "docs/api",
    
    [switch]$IncludePrivateFunctions,
    
    [switch]$GenerateHtmlDocs
)

# Déterminer le chemin du module
$moduleRoot = Split-Path -Path $PSScriptRoot -Parent

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire de documentation créé: $OutputPath" -ForegroundColor Green
}

# Importer le module
Import-Module $moduleRoot\RoadmapParser.psm1 -Force

# Récupérer les fonctions du module
$functions = Get-Command -Module RoadmapParser | Where-Object {
    $_.CommandType -eq "Function" -and
    ($IncludePrivateFunctions -or $_.Name -notmatch "^(Get-|Set-|New-|Remove-|Test-|Convert-|Format-|Measure-|Search-|Select-|Sort-|Group-|Compare-|Copy-|Move-|Rename-|Clear-|Show-|Hide-|Enable-|Disable-|Start-|Stop-|Restart-|Resume-|Suspend-|Wait-|Use-|Import-|Export-|Mount-|Dismount-|Add-|Remove-|Install-|Uninstall-|Register-|Unregister-|Invoke-|ConvertFrom-|ConvertTo-|Update-|Push-|Pop-|Join-|Split-|Compress-|Expand-|Backup-|Restore-|Sync-|Optimize-|Debug-|Trace-|Repair-|Test-|Approve-|Assert-|Complete-|Confirm-|Deny-|Deploy-|Disconnect-|Edit-|Enter-|Exit-|Find-|Initialize-|Limit-|Lock-|Out-|Ping-|Protect-|Publish-|Read-|Receive-|Redo-|Reset-|Resize-|Resolve-|Revoke-|Save-|Send-|Skip-|Step-|Switch-|Undo-|Unlock-|Unpublish-|Unprotect-|Watch-|Write-)")
}

# Créer un index des fonctions
$indexPath = Join-Path -Path $OutputPath -ChildPath "index.md"
$indexContent = @"
# Documentation de l'API RoadmapParser

Cette documentation décrit les fonctions disponibles dans le module RoadmapParser.

## Fonctions publiques

| Nom | Description |
|-----|-------------|
"@

# Créer la documentation pour chaque fonction
foreach ($function in $functions | Sort-Object Name) {
    Write-Host "Génération de la documentation pour $($function.Name)..." -ForegroundColor Yellow
    
    # Récupérer l'aide de la fonction
    $help = Get-Help -Name $function.Name -Full
    
    # Déterminer si la fonction est publique ou privée
    $isPublic = $function.Name -notmatch "^(Private|Internal)"
    $functionType = if ($isPublic) { "publique" } else { "privée" }
    
    # Récupérer le chemin du fichier source
    $functionPath = $function.ScriptBlock.File
    $relativePath = if ($functionPath) {
        $functionPath.Replace($moduleRoot, "").TrimStart("\")
    } else {
        "Inconnu"
    }
    
    # Créer le contenu de la documentation
    $docContent = @"
# $($function.Name)

## Résumé

$($help.Synopsis)

## Description

$($help.Description.Text)

## Syntaxe

```powershell
$($help.Syntax.SyntaxItem.Name) $($help.Syntax.SyntaxItem.Parameter | ForEach-Object { "[-$($_.Name) <$($_.Type.Name)>] " })
```

## Paramètres

"@
    
    # Ajouter les paramètres
    foreach ($parameter in $help.Parameters.Parameter) {
        $docContent += @"
### -$($parameter.Name)

$($parameter.Description.Text)

- Type: $($parameter.Type.Name)
- Position: $($parameter.Position)
- Défaut: $($parameter.DefaultValue)
- Accepte les entrées de pipeline: $($parameter.PipelineInput)
- Accepte les caractères génériques: $($parameter.Globbing)

"@
    }
    
    # Ajouter les entrées
    if ($help.InputTypes) {
        $docContent += @"
## Entrées

$($help.InputTypes.InputType.Type.Name)

"@
    }
    
    # Ajouter les sorties
    if ($help.ReturnValues) {
        $docContent += @"
## Sorties

$($help.ReturnValues.ReturnValue.Type.Name)

"@
    }
    
    # Ajouter les notes
    if ($help.Notes) {
        $docContent += @"
## Notes

$($help.Notes)

"@
    }
    
    # Ajouter les exemples
    if ($help.Examples) {
        $docContent += @"
## Exemples

"@
        
        foreach ($example in $help.Examples.Example) {
            $docContent += @"
### Exemple $($example.Title.Replace("-------------------------- EXEMPLE ", "").Replace(" --------------------------", ""))

```powershell
$($example.Code)
```

$($example.Remarks.Text)

"@
        }
    }
    
    # Ajouter les liens
    $docContent += @"
## Liens

- [Source]($relativePath)
- [Module RoadmapParser](../index.md)

"@
    
    # Enregistrer la documentation
    $docPath = Join-Path -Path $OutputPath -ChildPath "$($function.Name).md"
    $docContent | Set-Content -Path $docPath -Encoding UTF8
    
    # Ajouter à l'index
    $indexContent += @"
| [$($function.Name)]($($function.Name).md) | $($help.Synopsis) |
"@
    
    # Générer la documentation HTML si demandé
    if ($GenerateHtmlDocs) {
        $htmlPath = Join-Path -Path $OutputPath -ChildPath "$($function.Name).html"
        $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>$($function.Name) - Documentation RoadmapParser</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        pre {
            background-color: #f8f9fa;
            border-radius: 5px;
            padding: 15px;
            overflow-x: auto;
        }
        code {
            font-family: Consolas, monospace;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 10px;
            border: 1px solid #ddd;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        .parameter {
            margin-bottom: 20px;
        }
        .parameter h3 {
            margin-bottom: 5px;
        }
        .parameter-details {
            margin-left: 20px;
        }
        .example {
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <h1>$($function.Name)</h1>
    
    <h2>Résumé</h2>
    <p>$($help.Synopsis)</p>
    
    <h2>Description</h2>
    <p>$($help.Description.Text)</p>
    
    <h2>Syntaxe</h2>
    <pre><code>$($help.Syntax.SyntaxItem.Name) $($help.Syntax.SyntaxItem.Parameter | ForEach-Object { "[-$($_.Name) &lt;$($_.Type.Name)&gt;] " })</code></pre>
    
    <h2>Paramètres</h2>
"@
        
        # Ajouter les paramètres
        foreach ($parameter in $help.Parameters.Parameter) {
            $htmlContent += @"
    <div class="parameter">
        <h3>-$($parameter.Name)</h3>
        <p>$($parameter.Description.Text)</p>
        <div class="parameter-details">
            <p><strong>Type:</strong> $($parameter.Type.Name)</p>
            <p><strong>Position:</strong> $($parameter.Position)</p>
            <p><strong>Défaut:</strong> $($parameter.DefaultValue)</p>
            <p><strong>Accepte les entrées de pipeline:</strong> $($parameter.PipelineInput)</p>
            <p><strong>Accepte les caractères génériques:</strong> $($parameter.Globbing)</p>
        </div>
    </div>
"@
        }
        
        # Ajouter les entrées
        if ($help.InputTypes) {
            $htmlContent += @"
    <h2>Entrées</h2>
    <p>$($help.InputTypes.InputType.Type.Name)</p>
"@
        }
        
        # Ajouter les sorties
        if ($help.ReturnValues) {
            $htmlContent += @"
    <h2>Sorties</h2>
    <p>$($help.ReturnValues.ReturnValue.Type.Name)</p>
"@
        }
        
        # Ajouter les notes
        if ($help.Notes) {
            $htmlContent += @"
    <h2>Notes</h2>
    <p>$($help.Notes)</p>
"@
        }
        
        # Ajouter les exemples
        if ($help.Examples) {
            $htmlContent += @"
    <h2>Exemples</h2>
"@
            
            foreach ($example in $help.Examples.Example) {
                $htmlContent += @"
    <div class="example">
        <h3>Exemple $($example.Title.Replace("-------------------------- EXEMPLE ", "").Replace(" --------------------------", ""))</h3>
        <pre><code>$($example.Code)</code></pre>
        <p>$($example.Remarks.Text)</p>
    </div>
"@
            }
        }
        
        # Ajouter les liens
        $htmlContent += @"
    <h2>Liens</h2>
    <ul>
        <li><a href="$relativePath">Source</a></li>
        <li><a href="../index.html">Module RoadmapParser</a></li>
    </ul>
</body>
</html>
"@
        
        # Enregistrer la documentation HTML
        $htmlContent | Set-Content -Path $htmlPath -Encoding UTF8
    }
}

# Enregistrer l'index
$indexContent | Set-Content -Path $indexPath -Encoding UTF8

# Générer l'index HTML si demandé
if ($GenerateHtmlDocs) {
    $htmlIndexPath = Join-Path -Path $OutputPath -ChildPath "index.html"
    $htmlIndexContent = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Documentation de l'API RoadmapParser</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 10px;
            border: 1px solid #ddd;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
    </style>
</head>
<body>
    <h1>Documentation de l'API RoadmapParser</h1>
    <p>Cette documentation décrit les fonctions disponibles dans le module RoadmapParser.</p>
    
    <h2>Fonctions publiques</h2>
    <table>
        <tr>
            <th>Nom</th>
            <th>Description</th>
        </tr>
"@
    
    foreach ($function in $functions | Sort-Object Name) {
        $help = Get-Help -Name $function.Name
        $htmlIndexContent += @"
        <tr>
            <td><a href="$($function.Name).html">$($function.Name)</a></td>
            <td>$($help.Synopsis)</td>
        </tr>
"@
    }
    
    $htmlIndexContent += @"
    </table>
</body>
</html>
"@
    
    # Enregistrer l'index HTML
    $htmlIndexContent | Set-Content -Path $htmlIndexPath -Encoding UTF8
}

Write-Host "`nDocumentation générée avec succès dans $OutputPath" -ForegroundColor Green
if ($GenerateHtmlDocs) {
    Write-Host "Documentation HTML générée avec succès dans $OutputPath" -ForegroundColor Green
}

# Retourner le nombre de fonctions documentées
return $functions.Count
