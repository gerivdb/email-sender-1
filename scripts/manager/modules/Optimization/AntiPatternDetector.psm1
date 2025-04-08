# Module de détection des anti-patterns pour le Script Manager
# Ce module détecte les anti-patterns dans les scripts
# Author: Script Manager
# Version: 1.0
# Tags: optimization, anti-patterns, scripts

function Find-CodeAntiPatterns {
    <#
    .SYNOPSIS
        Détecte les anti-patterns dans les scripts
    .DESCRIPTION
        Analyse les scripts pour détecter les anti-patterns courants
    .PARAMETER Analysis
        Objet d'analyse des scripts
    .PARAMETER OutputPath
        Chemin où enregistrer les résultats de la détection
    .EXAMPLE
        Find-CodeAntiPatterns -Analysis $analysis -OutputPath "optimization"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Analysis,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    # Créer le dossier des anti-patterns
    $AntiPatternsPath = Join-Path -Path $OutputPath -ChildPath "anti-patterns"
    if (-not (Test-Path -Path $AntiPatternsPath)) {
        New-Item -ItemType Directory -Path $AntiPatternsPath -Force | Out-Null
    }
    
    Write-Host "Détection des anti-patterns..." -ForegroundColor Cyan
    
    # Créer un tableau pour stocker les résultats
    $ScriptResults = @()
    
    # Traiter chaque script
    $Counter = 0
    $Total = $Analysis.Scripts.Count
    
    foreach ($Script in $Analysis.Scripts) {
        $Counter++
        $Progress = [math]::Round(($Counter / $Total) * 100)
        Write-Progress -Activity "Détection des anti-patterns" -Status "$Counter / $Total ($Progress%)" -PercentComplete $Progress
        
        # Détecter les anti-patterns selon le type de script
        $Patterns = @()
        
        # Lire le contenu du script
        $Content = Get-Content -Path $Script.Path -Raw -ErrorAction SilentlyContinue
        
        if ($null -ne $Content) {
            # Détecter les anti-patterns communs
            $Patterns += Find-CommonAntiPatterns -Script $Script -Content $Content
            
            # Détecter les anti-patterns spécifiques au type de script
            switch ($Script.Type) {
                "PowerShell" {
                    $Patterns += Find-PowerShellAntiPatterns -Script $Script -Content $Content
                }
                "Python" {
                    $Patterns += Find-PythonAntiPatterns -Script $Script -Content $Content
                }
                "Batch" {
                    $Patterns += Find-BatchAntiPatterns -Script $Script -Content $Content
                }
                "Shell" {
                    $Patterns += Find-ShellAntiPatterns -Script $Script -Content $Content
                }
            }
        }
        
        # Ajouter les résultats au tableau
        if ($Patterns.Count -gt 0) {
            $ScriptResults += [PSCustomObject]@{
                Path = $Script.Path
                Name = $Script.Name
                Type = $Script.Type
                PatternCount = $Patterns.Count
                Patterns = $Patterns
            }
        }
    }
    
    Write-Progress -Activity "Détection des anti-patterns" -Completed
    
    # Enregistrer les résultats dans un fichier
    $AntiPatternsFilePath = Join-Path -Path $AntiPatternsPath -ChildPath "anti_patterns.json"
    $AntiPatternsObject = [PSCustomObject]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TotalScripts = $Analysis.TotalScripts
        ScriptsWithAntiPatterns = $ScriptResults.Count
        TotalAntiPatterns = ($ScriptResults | Measure-Object -Property PatternCount -Sum).Sum
        ScriptResults = $ScriptResults
    }
    
    $AntiPatternsObject | ConvertTo-Json -Depth 10 | Set-Content -Path $AntiPatternsFilePath
    
    Write-Host "  Anti-patterns détectés dans $($ScriptResults.Count) scripts" -ForegroundColor Green
    Write-Host "  Total des anti-patterns: $($AntiPatternsObject.TotalAntiPatterns)" -ForegroundColor Green
    Write-Host "  Résultats enregistrés dans: $AntiPatternsFilePath" -ForegroundColor Green
    
    return $AntiPatternsObject
}

# Exporter les fonctions
Export-ModuleMember -Function Find-CodeAntiPatterns
