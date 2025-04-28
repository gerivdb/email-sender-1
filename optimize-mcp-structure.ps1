#Requires -Version 5.1
<#
.SYNOPSIS
    Optimise la structure des fichiers MCP dans le projet.
.DESCRIPTION
    Ce script analyse la structure actuelle des fichiers MCP, les déplace vers
    une structure optimisée et met à jour les références.
.PARAMETER ProjectRoot
    Chemin racine du projet. Par défaut, le répertoire courant.
.PARAMETER TargetRoot
    Chemin racine de la nouvelle structure MCP. Par défaut, "projet/mcp".
.PARAMETER DryRun
    Simule les opérations sans effectuer de modifications.
.PARAMETER Force
    Force l'exécution sans demander de confirmation.
.EXAMPLE
    .\optimize-mcp-structure.ps1 -DryRun
    Simule l'optimisation de la structure sans effectuer de modifications.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = ".",

    [Parameter(Mandatory = $false)]
    [string]$TargetRoot = "projet/mcp",

    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Initialisation
$ErrorActionPreference = "Stop"
$ProjectRoot = Resolve-Path $ProjectRoot
$TargetRoot = Join-Path -Path $ProjectRoot -ChildPath $TargetRoot

# Fonctions d'aide
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "White" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "TITLE" { "Cyan" }
        default { "White" }
    }

    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Analyze-CurrentStructure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $mcpFiles = @{
        Scripts        = @()
        Configurations = @()
        Documentation  = @()
        Modules        = @()
        Python         = @()
        Tests          = @()
        Servers        = @()
        Integrations   = @()
        Utils          = @()
    }

    # Rechercher tous les fichiers liés à MCP
    Write-Log "Recherche des fichiers MCP dans $ProjectRoot..." -Level "INFO"
    $allFiles = Get-ChildItem -Path $ProjectRoot -Recurse -File | Where-Object {
        $_.Name -like "*mcp*" -or
        $_.DirectoryName -like "*mcp*" -or
        (Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue) -like "*mcp*"
    }

    Write-Log "Trouvé $($allFiles.Count) fichiers potentiellement liés à MCP" -Level "INFO"

    # Catégoriser les fichiers
    foreach ($file in $allFiles) {
        if ($file.Extension -in ".ps1", ".cmd", ".bat") {
            if ($file.DirectoryName -like "*test*") {
                $mcpFiles.Tests += $file
            } elseif ($file.DirectoryName -like "*server*") {
                $mcpFiles.Servers += $file
            } else {
                $mcpFiles.Scripts += $file
            }
        } elseif ($file.Extension -in ".json", ".yaml", ".yml", ".config") {
            $mcpFiles.Configurations += $file
        } elseif ($file.Extension -in ".md", ".html", ".txt") {
            $mcpFiles.Documentation += $file
        } elseif ($file.Extension -in ".psm1", ".psd1") {
            $mcpFiles.Modules += $file
        } elseif ($file.Extension -in ".py") {
            $mcpFiles.Python += $file
        } elseif ($file.DirectoryName -like "*integration*") {
            $mcpFiles.Integrations += $file
        } elseif ($file.DirectoryName -like "*util*") {
            $mcpFiles.Utils += $file
        } elseif ($file.Name -like "*test*" -or $file.DirectoryName -like "*test*") {
            $mcpFiles.Tests += $file
        }
    }

    return $mcpFiles
}

function Create-TargetStructure {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TargetRoot,

        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )

    $directories = @(
        "core/client",
        "core/server",
        "core/common",
        "servers/filesystem",
        "servers/github",
        "servers/gcp",
        "servers/notion",
        "servers/gateway",
        "scripts/setup",
        "scripts/maintenance",
        "scripts/utils",
        "modules",
        "python",
        "tests/unit",
        "tests/integration",
        "tests/performance",
        "config",
        "config/templates",
        "config/environments",
        "docs/guides",
        "docs/api",
        "docs/servers",
        "docs/development",
        "integrations/n8n",
        "integrations/n8n/credentials",
        "integrations/n8n/workflows",
        "integrations/n8n/scripts",
        "monitoring/scripts",
        "monitoring/dashboards",
        "monitoring/alerts",
        "monitoring/logs",
        "versioning/scripts",
        "versioning/backups",
        "versioning/changelog",
        "dependencies/npm",
        "dependencies/pip",
        "dependencies/binary",
        "dependencies/scripts"
    )

    foreach ($dir in $directories) {
        $path = Join-Path -Path $TargetRoot -ChildPath $dir
        if (-not (Test-Path $path)) {
            if ($PSCmdlet.ShouldProcess($path, "Create directory")) {
                if (-not $DryRun) {
                    New-Item -Path $path -ItemType Directory -Force | Out-Null
                }
                Write-Log "Répertoire créé: $path" -Level "SUCCESS"
            }
        }
    }
}

function Plan-FileMovements {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$McpFiles,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$TargetRoot
    )

    $movements = @()

    # Planifier les déplacements pour les scripts
    foreach ($script in $McpFiles.Scripts) {
        $targetPath = Determine-TargetPath -File $script -Category "scripts" -ProjectRoot $ProjectRoot -TargetRoot $TargetRoot
        $movements += @{
            SourcePath = $script.FullName
            TargetPath = $targetPath
            FileType   = "Script"
        }
    }

    # Planifier les déplacements pour les configurations
    foreach ($config in $McpFiles.Configurations) {
        $targetPath = Determine-TargetPath -File $config -Category "config" -ProjectRoot $ProjectRoot -TargetRoot $TargetRoot
        $movements += @{
            SourcePath = $config.FullName
            TargetPath = $targetPath
            FileType   = "Configuration"
        }
    }

    # Planifier les déplacements pour la documentation
    foreach ($doc in $McpFiles.Documentation) {
        $targetPath = Determine-TargetPath -File $doc -Category "docs" -ProjectRoot $ProjectRoot -TargetRoot $TargetRoot
        $movements += @{
            SourcePath = $doc.FullName
            TargetPath = $targetPath
            FileType   = "Documentation"
        }
    }

    # Planifier les déplacements pour les modules
    foreach ($module in $McpFiles.Modules) {
        $targetPath = Determine-TargetPath -File $module -Category "modules" -ProjectRoot $ProjectRoot -TargetRoot $TargetRoot
        $movements += @{
            SourcePath = $module.FullName
            TargetPath = $targetPath
            FileType   = "Module"
        }
    }

    # Planifier les déplacements pour les fichiers Python
    foreach ($pyFile in $McpFiles.Python) {
        $targetPath = Determine-TargetPath -File $pyFile -Category "python" -ProjectRoot $ProjectRoot -TargetRoot $TargetRoot
        $movements += @{
            SourcePath = $pyFile.FullName
            TargetPath = $targetPath
            FileType   = "Python"
        }
    }

    # Planifier les déplacements pour les tests
    foreach ($test in $McpFiles.Tests) {
        $targetPath = Determine-TargetPath -File $test -Category "tests" -ProjectRoot $ProjectRoot -TargetRoot $TargetRoot
        $movements += @{
            SourcePath = $test.FullName
            TargetPath = $targetPath
            FileType   = "Test"
        }
    }

    # Planifier les déplacements pour les serveurs
    foreach ($server in $McpFiles.Servers) {
        $targetPath = Determine-TargetPath -File $server -Category "servers" -ProjectRoot $ProjectRoot -TargetRoot $TargetRoot
        $movements += @{
            SourcePath = $server.FullName
            TargetPath = $targetPath
            FileType   = "Server"
        }
    }

    # Planifier les déplacements pour les intégrations
    foreach ($integration in $McpFiles.Integrations) {
        $targetPath = Determine-TargetPath -File $integration -Category "integrations" -ProjectRoot $ProjectRoot -TargetRoot $TargetRoot
        $movements += @{
            SourcePath = $integration.FullName
            TargetPath = $targetPath
            FileType   = "Integration"
        }
    }

    # Planifier les déplacements pour les utilitaires
    foreach ($util in $McpFiles.Utils) {
        $targetPath = Determine-TargetPath -File $util -Category "utils" -ProjectRoot $ProjectRoot -TargetRoot $TargetRoot
        $movements += @{
            SourcePath = $util.FullName
            TargetPath = $targetPath
            FileType   = "Utility"
        }
    }

    return $movements
}

function Determine-TargetPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File,

        [Parameter(Mandatory = $true)]
        [string]$Category,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$TargetRoot
    )

    $fileName = $File.Name
    $relativePath = $File.FullName.Replace($ProjectRoot, "").TrimStart("\")

    switch ($Category) {
        "scripts" {
            if ($fileName -like "*setup*" -or $relativePath -like "*setup*") {
                return Join-Path -Path $TargetRoot -ChildPath "scripts\setup\$fileName"
            } elseif ($fileName -like "*maintenance*" -or $relativePath -like "*maintenance*") {
                return Join-Path -Path $TargetRoot -ChildPath "scripts\maintenance\$fileName"
            } elseif ($fileName -like "*start*" -or $fileName -like "*stop*" -or $fileName -like "*restart*") {
                return Join-Path -Path $TargetRoot -ChildPath "scripts\utils\$fileName"
            } else {
                return Join-Path -Path $TargetRoot -ChildPath "scripts\$fileName"
            }
        }
        "config" {
            if ($fileName -like "*template*") {
                return Join-Path -Path $TargetRoot -ChildPath "config\templates\$fileName"
            } elseif ($fileName -like "*dev*" -or $fileName -like "*development*") {
                return Join-Path -Path $TargetRoot -ChildPath "config\environments\development.json"
            } elseif ($fileName -like "*prod*" -or $fileName -like "*production*") {
                return Join-Path -Path $TargetRoot -ChildPath "config\environments\production.json"
            } else {
                return Join-Path -Path $TargetRoot -ChildPath "config\$fileName"
            }
        }
        "docs" {
            if ($fileName -like "*guide*" -or $fileName -like "*tutorial*" -or $fileName -like "*how-to*") {
                return Join-Path -Path $TargetRoot -ChildPath "docs\guides\$fileName"
            } elseif ($fileName -like "*api*") {
                return Join-Path -Path $TargetRoot -ChildPath "docs\api\$fileName"
            } elseif ($fileName -like "*server*") {
                return Join-Path -Path $TargetRoot -ChildPath "docs\servers\$fileName"
            } elseif ($fileName -like "*dev*" -or $fileName -like "*architecture*" -or $fileName -like "*design*") {
                return Join-Path -Path $TargetRoot -ChildPath "docs\development\$fileName"
            } else {
                return Join-Path -Path $TargetRoot -ChildPath "docs\$fileName"
            }
        }
        "modules" {
            return Join-Path -Path $TargetRoot -ChildPath "modules\$fileName"
        }
        "python" {
            if ($relativePath -like "*pymcpfy*") {
                $subPath = $relativePath -replace ".*pymcpfy", "pymcpfy"
                return Join-Path -Path $TargetRoot -ChildPath "python\$subPath"
            } else {
                return Join-Path -Path $TargetRoot -ChildPath "python\$fileName"
            }
        }
        "tests" {
            if ($fileName -like "*unit*" -or $relativePath -like "*unit*") {
                return Join-Path -Path $TargetRoot -ChildPath "tests\unit\$fileName"
            } elseif ($fileName -like "*integration*" -or $relativePath -like "*integration*") {
                return Join-Path -Path $TargetRoot -ChildPath "tests\integration\$fileName"
            } elseif ($fileName -like "*performance*" -or $relativePath -like "*performance*") {
                return Join-Path -Path $TargetRoot -ChildPath "tests\performance\$fileName"
            } else {
                return Join-Path -Path $TargetRoot -ChildPath "tests\$fileName"
            }
        }
        "servers" {
            if ($fileName -like "*filesystem*" -or $relativePath -like "*filesystem*") {
                return Join-Path -Path $TargetRoot -ChildPath "servers\filesystem\$fileName"
            } elseif ($fileName -like "*github*" -or $relativePath -like "*github*") {
                return Join-Path -Path $TargetRoot -ChildPath "servers\github\$fileName"
            } elseif ($fileName -like "*gcp*" -or $relativePath -like "*gcp*") {
                return Join-Path -Path $TargetRoot -ChildPath "servers\gcp\$fileName"
            } elseif ($fileName -like "*notion*" -or $relativePath -like "*notion*") {
                return Join-Path -Path $TargetRoot -ChildPath "servers\notion\$fileName"
            } elseif ($fileName -like "*gateway*" -or $relativePath -like "*gateway*") {
                return Join-Path -Path $TargetRoot -ChildPath "servers\gateway\$fileName"
            } else {
                return Join-Path -Path $TargetRoot -ChildPath "servers\$fileName"
            }
        }
        "integrations" {
            if ($fileName -like "*n8n*" -or $relativePath -like "*n8n*") {
                if ($fileName -like "*credential*") {
                    return Join-Path -Path $TargetRoot -ChildPath "integrations\n8n\credentials\$fileName"
                } elseif ($fileName -like "*workflow*") {
                    return Join-Path -Path $TargetRoot -ChildPath "integrations\n8n\workflows\$fileName"
                } else {
                    return Join-Path -Path $TargetRoot -ChildPath "integrations\n8n\scripts\$fileName"
                }
            } else {
                return Join-Path -Path $TargetRoot -ChildPath "integrations\$fileName"
            }
        }
        "utils" {
            return Join-Path -Path $TargetRoot -ChildPath "scripts\utils\$fileName"
        }
        default {
            return Join-Path -Path $TargetRoot -ChildPath $fileName
        }
    }
}

function Execute-FileMovements {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Movements,

        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )

    $results = @{
        Succeeded = @()
        Failed    = @()
    }

    foreach ($movement in $Movements) {
        try {
            # Créer le répertoire cible s'il n'existe pas
            $targetDir = Split-Path -Parent $movement.TargetPath
            if (-not (Test-Path $targetDir)) {
                if ($PSCmdlet.ShouldProcess($targetDir, "Create directory")) {
                    if (-not $DryRun) {
                        New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
                    }
                }
            }

            # Copier le fichier
            if ($PSCmdlet.ShouldProcess($movement.SourcePath, "Copy to $($movement.TargetPath)")) {
                if (-not $DryRun) {
                    Copy-Item -Path $movement.SourcePath -Destination $movement.TargetPath -Force
                }
                $results.Succeeded += $movement
                Write-Log "Fichier copié: $($movement.SourcePath) -> $($movement.TargetPath)" -Level "SUCCESS"
            }
        } catch {
            $results.Failed += @{
                Movement = $movement
                Error    = $_
            }
            Write-Log "Erreur lors de la copie de $($movement.SourcePath): $_" -Level "ERROR"
        }
    }

    return $results
}

function Update-References {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Movements,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )

    $results = @{
        Updated = @()
        Failed  = @()
    }

    # Créer une table de mappage des anciens chemins vers les nouveaux
    $pathMapping = @{}
    foreach ($movement in $Movements) {
        $relativeSrc = $movement.SourcePath.Replace($ProjectRoot, "").TrimStart("\")
        $relativeDst = $movement.TargetPath.Replace($ProjectRoot, "").TrimStart("\")
        $pathMapping[$relativeSrc] = $relativeDst
    }

    # Rechercher tous les fichiers de code qui pourraient contenir des références
    $codeFiles = Get-ChildItem -Path $ProjectRoot -Recurse -File | Where-Object {
        $_.Extension -in ".ps1", ".psm1", ".psd1", ".cmd", ".bat", ".py", ".json", ".yaml", ".yml"
    }

    foreach ($file in $codeFiles) {
        try {
            $content = Get-Content -Path $file.FullName -Raw
            $modified = $false

            foreach ($oldPath in $pathMapping.Keys) {
                $newPath = $pathMapping[$oldPath]
                if ($content -match [regex]::Escape($oldPath)) {
                    $content = $content -replace [regex]::Escape($oldPath), $newPath
                    $modified = $true
                }
            }

            if ($modified) {
                if ($PSCmdlet.ShouldProcess($file.FullName, "Update references")) {
                    if (-not $DryRun) {
                        Set-Content -Path $file.FullName -Value $content -Force
                    }
                    $results.Updated += $file.FullName
                    Write-Log "Références mises à jour dans: $($file.FullName)" -Level "SUCCESS"
                }
            }
        } catch {
            $results.Failed += @{
                File  = $file.FullName
                Error = $_
            }
            Write-Log "Erreur lors de la mise à jour des références dans $($file.FullName): $_" -Level "ERROR"
        }
    }

    return $results
}

function Generate-Report {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$McpFiles,

        [Parameter(Mandatory = $true)]
        [hashtable]$MoveResults,

        [Parameter(Mandatory = $true)]
        [hashtable]$RefResults,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )

    $reportPath = Join-Path -Path $ProjectRoot -ChildPath "mcp-optimization-report.md"

    $totalFiles = $McpFiles.Scripts.Count + $McpFiles.Configurations.Count + $McpFiles.Documentation.Count + $McpFiles.Modules.Count + $McpFiles.Python.Count + $McpFiles.Tests.Count + $McpFiles.Servers.Count + $McpFiles.Integrations.Count + $McpFiles.Utils.Count

    $report = @"
# Rapport d'optimisation de la structure MCP

## Résumé
- Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- Mode: $(if ($DryRun) { "Simulation" } else { "Réel" })
- Fichiers analysés: $totalFiles
- Fichiers déplacés: $($MoveResults.Succeeded.Count)
- Références mises à jour: $($RefResults.Updated.Count)

## Détails des déplacements
$($MoveResults.Succeeded | ForEach-Object { "- $($_.SourcePath) -> $($_.TargetPath)" } | Out-String)

## Échecs de déplacement
$($MoveResults.Failed | ForEach-Object { "- $($_.Movement.SourcePath): $($_.Error.Message)" } | Out-String)

## Références mises à jour
$($RefResults.Updated | ForEach-Object { "- $_" } | Out-String)

## Échecs de mise à jour des références
$($RefResults.Failed | ForEach-Object { "- $($_.File): $($_.Error.Message)" } | Out-String)
"@

    if ($PSCmdlet.ShouldProcess($reportPath, "Generate report")) {
        if (-not $DryRun) {
            Set-Content -Path $reportPath -Value $report
        }
        Write-Log "Rapport généré: $reportPath" -Level "SUCCESS"
    }
}

# Corps principal du script
try {
    Write-Log "Démarrage de l'optimisation de la structure MCP..." -Level "TITLE"

    # Étape 1: Analyser la structure actuelle
    Write-Log "Analyse de la structure actuelle..." -Level "TITLE"
    $mcpFiles = Analyze-CurrentStructure -ProjectRoot $ProjectRoot
    Write-Log "Analyse terminée. Trouvé $($mcpFiles.Scripts.Count) scripts, $($mcpFiles.Configurations.Count) fichiers de configuration, $($mcpFiles.Documentation.Count) fichiers de documentation." -Level "SUCCESS"

    # Étape 2: Créer la structure cible
    Write-Log "Création de la structure cible..." -Level "TITLE"
    Create-TargetStructure -TargetRoot $TargetRoot -DryRun:$DryRun

    # Étape 3: Planifier les déplacements
    Write-Log "Planification des déplacements de fichiers..." -Level "TITLE"
    $movements = Plan-FileMovements -McpFiles $mcpFiles -ProjectRoot $ProjectRoot -TargetRoot $TargetRoot
    Write-Log "Planification terminée. $($movements.Count) fichiers à déplacer." -Level "SUCCESS"

    # Demander confirmation si nécessaire
    if (-not $Force -and -not $DryRun) {
        $confirmation = Read-Host "Voulez-vous procéder à l'optimisation de la structure MCP ? (O/N)"
        if ($confirmation -ne "O" -and $confirmation -ne "o") {
            Write-Log "Optimisation annulée par l'utilisateur." -Level "WARNING"
            exit 0
        }
    }

    # Étape 4: Exécuter les déplacements
    Write-Log "Exécution des déplacements de fichiers..." -Level "TITLE"
    $moveResults = Execute-FileMovements -Movements $movements -DryRun:$DryRun
    Write-Log "Déplacements terminés. $($moveResults.Succeeded.Count) réussis, $($moveResults.Failed.Count) échoués." -Level "SUCCESS"

    # Étape 5: Mettre à jour les références
    Write-Log "Mise à jour des références..." -Level "TITLE"
    $refResults = Update-References -Movements $moveResults.Succeeded -ProjectRoot $ProjectRoot -DryRun:$DryRun
    Write-Log "Mise à jour des références terminée. $($refResults.Updated.Count) fichiers mis à jour, $($refResults.Failed.Count) échecs." -Level "SUCCESS"

    # Étape 6: Générer un rapport
    Write-Log "Génération du rapport..." -Level "TITLE"
    Generate-Report -McpFiles $mcpFiles -MoveResults $moveResults -RefResults $refResults -ProjectRoot $ProjectRoot -DryRun:$DryRun

    Write-Log "Optimisation de la structure MCP terminée avec succès." -Level "SUCCESS"

    if ($DryRun) {
        Write-Log "REMARQUE: Ceci était une simulation. Aucune modification n'a été effectuée." -Level "WARNING"
        Write-Log "Pour appliquer les modifications, exécutez le script sans le paramètre -DryRun." -Level "INFO"
    }
} catch {
    Write-Log "Erreur lors de l'optimisation: $_" -Level "ERROR"
    exit 1
}
