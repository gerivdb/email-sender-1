# Module de dÃ©tection des anti-patterns pour le Script Manager
# Ce module dÃ©tecte les anti-patterns dans les scripts
# Author: Script Manager
# Version: 1.0
# Tags: optimization, anti-patterns, scripts

function Find-CodeAntiPatterns {
    <#
    .SYNOPSIS
        DÃ©tecte les anti-patterns dans les scripts
    .DESCRIPTION
        Analyse les scripts pour dÃ©tecter les anti-patterns courants
    .PARAMETER Analysis
        Objet d'analyse des scripts
    .PARAMETER OutputPath
        Chemin oÃ¹ enregistrer les rÃ©sultats de la dÃ©tection
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
    
    # CrÃ©er le dossier des anti-patterns
    $AntiPatternsPath = Join-Path -Path $OutputPath -ChildPath "anti-patterns"
    if (-not (Test-Path -Path $AntiPatternsPath)) {
        New-Item -ItemType Directory -Path $AntiPatternsPath -Force | Out-Null
    }
    
    Write-Host "DÃ©tection des anti-patterns..." -ForegroundColor Cyan
    
    # CrÃ©er un tableau pour stocker les rÃ©sultats
    $ScriptResults = @()
    
    # Traiter chaque script
    $Counter = 0
    $Total = $Analysis.Scripts.Count
    
    foreach ($Script in $Analysis.Scripts) {
        $Counter++
        $Progress = [math]::Round(($Counter / $Total) * 100)
        Write-Progress -Activity "DÃ©tection des anti-patterns" -Status "$Counter / $Total ($Progress%)" -PercentComplete $Progress
        
        # DÃ©tecter les anti-patterns selon le type de script
        $Patterns = @()
        
        # Lire le contenu du script
        $Content = Get-Content -Path $Script.Path -Raw -ErrorAction SilentlyContinue
        
        if ($null -ne $Content) {
            # DÃ©tecter les anti-patterns communs
            $Patterns += Find-CommonAntiPatterns -Script $Script -Content $Content
            
            # DÃ©tecter les anti-patterns spÃ©cifiques au type de script
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
        
        # Ajouter les rÃ©sultats au tableau
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
    
    Write-Progress -Activity "DÃ©tection des anti-patterns" -Completed
    
    # Enregistrer les rÃ©sultats dans un fichier
    $AntiPatternsFilePath = Join-Path -Path $AntiPatternsPath -ChildPath "anti_patterns.json"
    $AntiPatternsObject = [PSCustomObject]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TotalScripts = $Analysis.TotalScripts
        ScriptsWithAntiPatterns = $ScriptResults.Count
        TotalAntiPatterns = ($ScriptResults | Measure-Object -Property PatternCount -Sum).Sum
        ScriptResults = $ScriptResults
    }
    
    $AntiPatternsObject | ConvertTo-Json -Depth 10 | Set-Content -Path $AntiPatternsFilePath
    
    Write-Host "  Anti-patterns dÃ©tectÃ©s dans $($ScriptResults.Count) scripts" -ForegroundColor Green
    Write-Host "  Total des anti-patterns: $($AntiPatternsObject.TotalAntiPatterns)" -ForegroundColor Green
    Write-Host "  RÃ©sultats enregistrÃ©s dans: $AntiPatternsFilePath" -ForegroundColor Green
    
    return $AntiPatternsObject
}

# Exporter les fonctions
Export-ModuleMember -Function Find-CodeAntiPatterns
