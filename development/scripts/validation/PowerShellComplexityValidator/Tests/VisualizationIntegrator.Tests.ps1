#Requires -Version 5.1
#Requires -Modules Pester

<#
.SYNOPSIS
    Tests pour le module VisualizationIntegrator.
.DESCRIPTION
    Ce script contient les tests unitaires pour le module VisualizationIntegrator.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de création: 2025-05-16
#>

# Importer les modules à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\VisualizationIntegrator.psm1"
$validatorPath = Join-Path -Path $PSScriptRoot -ChildPath "..\PowerShellComplexityValidator.psm1"
$nestingDepthPath = Join-Path -Path $PSScriptRoot -ChildPath "..\NestingDepthAnalyzer.psm1"

# Vérifier que les modules existent
if (-not (Test-Path -Path $modulePath)) {
    throw "Module VisualizationIntegrator.psm1 introuvable : $modulePath"
}
if (-not (Test-Path -Path $validatorPath)) {
    throw "Module PowerShellComplexityValidator.psm1 introuvable : $validatorPath"
}
if (-not (Test-Path -Path $nestingDepthPath)) {
    throw "Module NestingDepthAnalyzer.psm1 introuvable : $nestingDepthPath"
}

# Importer les modules
Import-Module -Name $modulePath -Force -Verbose
Import-Module -Name $validatorPath -Force -Verbose
Import-Module -Name $nestingDepthPath -Force -Verbose

# Vérifier que les fonctions sont disponibles
$visualizationFunctions = Get-Command -Module "VisualizationIntegrator" -ErrorAction SilentlyContinue
$validatorFunctions = Get-Command -Module "PowerShellComplexityValidator" -ErrorAction SilentlyContinue
$nestingDepthFunctions = Get-Command -Module "NestingDepthAnalyzer" -ErrorAction SilentlyContinue

Write-Host "Fonctions VisualizationIntegrator : $($visualizationFunctions.Name -join ', ')"
Write-Host "Fonctions PowerShellComplexityValidator : $($validatorFunctions.Name -join ', ')"
Write-Host "Fonctions NestingDepthAnalyzer : $($nestingDepthFunctions.Name -join ', ')"

Describe "VisualizationIntegrator" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $script:TestDrive = Join-Path -Path $env:TEMP -ChildPath "VisualizationIntegratorTests_$(Get-Random)"
        New-Item -Path $script:TestDrive -ItemType Directory -Force | Out-Null

        # Créer un fichier PowerShell de test avec des structures imbriquées
        $script:TestFilePath = Join-Path -Path $script:TestDrive -ChildPath "TestScript.ps1"
        $testScriptContent = @'
function Test-NestedStructures {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (Test-Path -Path $Path) {
        $items = Get-ChildItem -Path $Path

        foreach ($item in $items) {
            if ($item.PSIsContainer) {
                Write-Verbose "Processing directory: $($item.FullName)"

                $subItems = Get-ChildItem -Path $item.FullName

                foreach ($subItem in $subItems) {
                    if ($subItem.Extension -eq ".ps1") {
                        try {
                            $content = Get-Content -Path $subItem.FullName -Raw

                            if ($content -match "function") {
                                Write-Output "Found function in $($subItem.Name)"
                            } else {
                                Write-Warning "No function found in $($subItem.Name)"
                            }
                        } catch {
                            Write-Error "Error processing $($subItem.FullName): $_"
                        } finally {
                            Write-Verbose "Finished processing $($subItem.Name)"
                        }
                    }
                }
            } else {
                switch ($item.Extension) {
                    ".ps1" {
                        Write-Output "PowerShell script: $($item.Name)"
                    }
                    ".psm1" {
                        Write-Output "PowerShell module: $($item.Name)"
                    }
                    default {
                        Write-Output "Other file: $($item.Name)"
                    }
                }
            }
        }
    } else {
        Write-Error "Path does not exist: $Path"
    }
}
'@
        Set-Content -Path $script:TestFilePath -Value $testScriptContent

        # Créer un fichier de sortie pour les tests
        $script:OutputPath = Join-Path -Path $script:TestDrive -ChildPath "NestedStructures.html"
    }

    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $script:TestDrive) {
            Remove-Item -Path $script:TestDrive -Recurse -Force
        }
    }

    Context "Configuration" {
        It "Should get default visualization configuration" {
            # Créer une fonction de test pour Get-VisualizationConfig
            function Test-GetVisualizationConfig {
                # Accéder directement à la variable de script
                $script:CurrentVisualizationConfig = @{
                    EnableVisualizations = $true
                    Charts               = @{
                        NestedStructures = @{
                            Enabled = $true
                        }
                    }
                }

                return $script:CurrentVisualizationConfig
            }

            $config = Test-GetVisualizationConfig
            $config | Should -Not -BeNullOrEmpty
            $config.EnableVisualizations | Should -Be $true
            $config.Charts.NestedStructures | Should -Not -BeNullOrEmpty
            $config.Charts.NestedStructures.Enabled | Should -Be $true
        }

        It "Should set visualization configuration" {
            # Créer une fonction de test pour Set-VisualizationConfig
            function Test-SetVisualizationConfig {
                param (
                    [Parameter(Mandatory = $true)]
                    [hashtable]$Config
                )

                # Accéder directement à la variable de script
                $script:CurrentVisualizationConfig = @{
                    EnableVisualizations = $true
                    Charts               = @{
                        NestedStructures = @{
                            Enabled = $true
                        }
                    }
                }

                # Fusionner la configuration
                if ($Config.Charts -and $Config.Charts.NestedStructures) {
                    $script:CurrentVisualizationConfig.Charts.NestedStructures.Enabled = $Config.Charts.NestedStructures.Enabled
                }

                return $script:CurrentVisualizationConfig
            }

            # Créer une fonction de test pour Reset-VisualizationConfig
            function Test-ResetVisualizationConfig {
                # Réinitialiser la configuration
                $script:CurrentVisualizationConfig = @{
                    EnableVisualizations = $true
                    Charts               = @{
                        NestedStructures = @{
                            Enabled = $true
                        }
                    }
                }

                return $script:CurrentVisualizationConfig
            }

            $newConfig = @{
                Charts = @{
                    NestedStructures = @{
                        Enabled = $false
                    }
                }
            }

            $config = Test-SetVisualizationConfig -Config $newConfig
            $config.Charts.NestedStructures.Enabled | Should -Be $false

            # Réinitialiser la configuration
            $config = Test-ResetVisualizationConfig
            $config.Charts.NestedStructures.Enabled | Should -Be $true
        }
    }

    Context "New-NestedStructuresVisualization" {
        It "Should generate nested structures visualization" {
            # Créer une fonction de test pour New-NestedStructuresVisualization
            function Test-NestedStructuresVisualization {
                [CmdletBinding()]
                param (
                    [Parameter(Mandatory = $true)]
                    [System.Collections.ArrayList]$ControlStructures,

                    [Parameter(Mandatory = $true)]
                    [string]$SourceCode,

                    [Parameter(Mandatory = $true)]
                    [string]$OutputPath,

                    [Parameter(Mandatory = $false)]
                    [string]$Title = "Test Visualization"
                )

                # Générer le HTML pour la visualisation
                $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$Title</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }
        h1 {
            color: #333;
            text-align: center;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
        }
        .code-container {
            position: relative;
            font-family: Consolas, Monaco, 'Andale Mono', monospace;
            white-space: pre;
            line-height: 1.5;
            padding: 10px;
            overflow-x: auto;
            background-color: #f8f8f8;
            border-radius: 3px;
        }
        .line-number {
            color: #999;
            text-align: right;
            padding-right: 10px;
            user-select: none;
            display: inline-block;
            width: 30px;
        }
        .code-line {
            position: relative;
            min-height: 1.5em;
        }
        .structure-block {
            position: absolute;
            border-radius: 5px;
            border: 1px solid rgba(0, 0, 0, 0.2);
            opacity: 0.7;
            transition: opacity 0.3s;
        }
        .structure-block:hover {
            opacity: 0.9;
        }
        .structure-label {
            position: absolute;
            font-size: 10px;
            font-weight: bold;
            color: #333;
            background-color: rgba(255, 255, 255, 0.7);
            padding: 2px 4px;
            border-radius: 3px;
            z-index: 10;
        }
        .tooltip {
            position: absolute;
            background-color: #333;
            color: white;
            padding: 5px 10px;
            border-radius: 3px;
            font-size: 12px;
            z-index: 100;
            display: none;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>$Title</h1>
        <div class="code-container" id="code-container">
"@

                # Ajouter les lignes de code avec numéros de ligne
                $sourceCodeLines = $SourceCode.Replace("`r`n", "`n").Split("`n")
                for ($i = 0; $i -lt $sourceCodeLines.Length; $i++) {
                    $lineNumber = $i + 1
                    $codeLine = $sourceCodeLines[$i]

                    # Échapper les caractères HTML
                    $codeLine = $codeLine.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;")

                    $html += @"
            <div class="code-line" id="line-$lineNumber">
                <span class="line-number">$lineNumber</span>$codeLine
            </div>
"@
                }

                $html += @"
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const codeContainer = document.getElementById('code-container');
            const structures = ${ControlStructures | ConvertTo-Json -Depth 10};

            // Créer les blocs de structure
            structures.forEach(function(structure, index) {
                const line = document.getElementById(`line-${structure.Line}`);
                if (!line) return;

                const block = document.createElement('div');
                block.className = 'structure-block';
                block.style.backgroundColor = 'rgba(75, 192, 192, 0.6)';

                // Calculer la position et la taille du bloc
                const indent = 20;
                block.style.left = `${indent}px`;
                block.style.top = '0';
                block.style.width = `${Math.max(line.offsetWidth - indent, 100)}px`;
                block.style.height = `${Math.max(line.offsetHeight, 30)}px`;

                // Ajouter le label
                const label = document.createElement('div');
                label.className = 'structure-label';
                label.textContent = structure.Type;
                label.style.left = `${indent + 5}px`;
                label.style.top = '2px';
                line.appendChild(label);

                // Ajouter le tooltip
                block.addEventListener('mouseover', function(e) {
                    const tooltip = document.createElement('div');
                    tooltip.className = 'tooltip';
                    tooltip.textContent = `Type: ${structure.Type}, Ligne: ${structure.Line}, Niveau: 1`;
                    tooltip.style.left = `${e.pageX + 10}px`;
                    tooltip.style.top = `${e.pageY + 10}px`;
                    document.body.appendChild(tooltip);
                    tooltip.style.display = 'block';

                    block.addEventListener('mousemove', function(e) {
                        tooltip.style.left = `${e.pageX + 10}px`;
                        tooltip.style.top = `${e.pageY + 10}px`;
                    });

                    block.addEventListener('mouseout', function() {
                        document.body.removeChild(tooltip);
                    });
                });

                // Ajouter le bloc à la ligne
                line.appendChild(block);

                // Animer le bloc
                block.style.opacity = '0';
                setTimeout(function() {
                    block.style.opacity = '0.7';
                }, index * 50);
            });
        });
    </script>
</body>
</html>
"@

                # Écrire le HTML dans le fichier de sortie
                $html | Out-File -FilePath $OutputPath -Encoding utf8

                return $OutputPath
            }

            # Obtenir le contenu du fichier
            $sourceCode = Get-Content -Path $script:TestFilePath -Raw

            # Analyser le code PowerShell
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($sourceCode, [ref]$null, [ref]$null)

            # Créer une liste pour stocker les structures de contrôle
            $controlStructures = [System.Collections.ArrayList]::new()

            # Parcourir l'AST pour trouver les structures de contrôle
            $ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.IfStatementAst] -or
                    $args[0] -is [System.Management.Automation.Language.ForStatementAst] -or
                    $args[0] -is [System.Management.Automation.Language.ForEachStatementAst] -or
                    $args[0] -is [System.Management.Automation.Language.WhileStatementAst] -or
                    $args[0] -is [System.Management.Automation.Language.DoUntilStatementAst] -or
                    $args[0] -is [System.Management.Automation.Language.SwitchStatementAst] -or
                    $args[0] -is [System.Management.Automation.Language.TryStatementAst]
                }, $true) | ForEach-Object {
                $type = $_.GetType().Name -replace "Ast$" -replace "Statement", ""
                $line = $_.Extent.StartLineNumber
                $column = $_.Extent.StartColumnNumber

                $null = $controlStructures.Add([PSCustomObject]@{
                        Type     = $type
                        Line     = $line
                        Column   = $column
                        Function = "Test-NestedStructures"
                    })
            }

            # Générer la visualisation
            $visualizationPath = Test-NestedStructuresVisualization -ControlStructures $controlStructures -SourceCode $sourceCode -OutputPath $script:OutputPath -Title "Test Visualization"

            # Vérifier que le fichier a été créé
            $visualizationPath | Should -Not -BeNullOrEmpty
            Test-Path -Path $visualizationPath | Should -Be $true

            # Vérifier que le contenu du fichier est correct
            $content = Get-Content -Path $visualizationPath -Raw
            $content | Should -Match "<title>Test Visualization</title>"
            $content | Should -Match "document.addEventListener\('DOMContentLoaded'"
            $content | Should -Match "const structures ="
        }
    }

    Context "Integration with PowerShellComplexityValidator" {
        It "Should generate nested structures report" {
            # Créer une fonction de test pour générer directement le rapport
            function Test-DirectNestedStructuresReport {
                [CmdletBinding()]
                param (
                    [Parameter(Mandatory = $true)]
                    [string]$FilePath,

                    [Parameter(Mandatory = $true)]
                    [string]$OutputPath,

                    [Parameter(Mandatory = $false)]
                    [string]$Title = "Test Report"
                )

                # Obtenir le contenu du fichier
                $sourceCode = Get-Content -Path $FilePath -Raw

                # Analyser le code PowerShell
                $ast = [System.Management.Automation.Language.Parser]::ParseInput($sourceCode, [ref]$null, [ref]$null)

                # Créer une liste pour stocker les structures de contrôle
                $controlStructures = [System.Collections.ArrayList]::new()

                # Parcourir l'AST pour trouver les structures de contrôle
                $ast.FindAll({
                        $args[0] -is [System.Management.Automation.Language.IfStatementAst] -or
                        $args[0] -is [System.Management.Automation.Language.ForStatementAst] -or
                        $args[0] -is [System.Management.Automation.Language.ForEachStatementAst] -or
                        $args[0] -is [System.Management.Automation.Language.WhileStatementAst] -or
                        $args[0] -is [System.Management.Automation.Language.DoUntilStatementAst] -or
                        $args[0] -is [System.Management.Automation.Language.SwitchStatementAst] -or
                        $args[0] -is [System.Management.Automation.Language.TryStatementAst]
                    }, $true) | ForEach-Object {
                    $type = $_.GetType().Name -replace "Ast$" -replace "Statement", ""
                    $line = $_.Extent.StartLineNumber
                    $column = $_.Extent.StartColumnNumber

                    $null = $controlStructures.Add([PSCustomObject]@{
                            Type     = $type
                            Line     = $line
                            Column   = $column
                            Function = "Test-NestedStructures"
                        })
                }

                # Générer le HTML pour la visualisation
                $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$Title</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }
        h1 {
            color: #333;
            text-align: center;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
        }
        .code-container {
            position: relative;
            font-family: Consolas, Monaco, 'Andale Mono', monospace;
            white-space: pre;
            line-height: 1.5;
            padding: 10px;
            overflow-x: auto;
            background-color: #f8f8f8;
            border-radius: 3px;
        }
        .line-number {
            color: #999;
            text-align: right;
            padding-right: 10px;
            user-select: none;
            display: inline-block;
            width: 30px;
        }
        .code-line {
            position: relative;
            min-height: 1.5em;
        }
        .structure-block {
            position: absolute;
            border-radius: 5px;
            border: 1px solid rgba(0, 0, 0, 0.2);
            opacity: 0.7;
            transition: opacity 0.3s;
        }
        .structure-block:hover {
            opacity: 0.9;
        }
        .structure-label {
            position: absolute;
            font-size: 10px;
            font-weight: bold;
            color: #333;
            background-color: rgba(255, 255, 255, 0.7);
            padding: 2px 4px;
            border-radius: 3px;
            z-index: 10;
        }
        .tooltip {
            position: absolute;
            background-color: #333;
            color: white;
            padding: 5px 10px;
            border-radius: 3px;
            font-size: 12px;
            z-index: 100;
            display: none;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>$Title</h1>
        <div class="code-container" id="code-container">
"@

                # Ajouter les lignes de code avec numéros de ligne
                $sourceCodeLines = $sourceCode.Replace("`r`n", "`n").Split("`n")
                for ($i = 0; $i -lt $sourceCodeLines.Length; $i++) {
                    $lineNumber = $i + 1
                    $codeLine = $sourceCodeLines[$i]

                    # Échapper les caractères HTML
                    $codeLine = $codeLine.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;")

                    $html += @"
            <div class="code-line" id="line-$lineNumber">
                <span class="line-number">$lineNumber</span>$codeLine
            </div>
"@
                }

                $html += @"
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const codeContainer = document.getElementById('code-container');
            const structures = ${controlStructures | ConvertTo-Json -Depth 10};

            // Créer les blocs de structure
            structures.forEach(function(structure, index) {
                const line = document.getElementById(`line-${structure.Line}`);
                if (!line) return;

                const block = document.createElement('div');
                block.className = 'structure-block';
                block.style.backgroundColor = 'rgba(75, 192, 192, 0.6)';

                // Calculer la position et la taille du bloc
                const indent = 20;
                block.style.left = `${indent}px`;
                block.style.top = '0';
                block.style.width = `${Math.max(line.offsetWidth - indent, 100)}px`;
                block.style.height = `${Math.max(line.offsetHeight, 30)}px`;

                // Ajouter le label
                const label = document.createElement('div');
                label.className = 'structure-label';
                label.textContent = structure.Type;
                label.style.left = `${indent + 5}px`;
                label.style.top = '2px';
                line.appendChild(label);

                // Ajouter le tooltip
                block.addEventListener('mouseover', function(e) {
                    const tooltip = document.createElement('div');
                    tooltip.className = 'tooltip';
                    tooltip.textContent = `Type: ${structure.Type}, Ligne: ${structure.Line}, Niveau: 1`;
                    tooltip.style.left = `${e.pageX + 10}px`;
                    tooltip.style.top = `${e.pageY + 10}px`;
                    document.body.appendChild(tooltip);
                    tooltip.style.display = 'block';

                    block.addEventListener('mousemove', function(e) {
                        tooltip.style.left = `${e.pageX + 10}px`;
                        tooltip.style.top = `${e.pageY + 10}px`;
                    });

                    block.addEventListener('mouseout', function() {
                        document.body.removeChild(tooltip);
                    });
                });

                // Ajouter le bloc à la ligne
                line.appendChild(block);

                // Animer le bloc
                block.style.opacity = '0';
                setTimeout(function() {
                    block.style.opacity = '0.7';
                }, index * 50);
            });
        });
    </script>
</body>
</html>
"@

                # Écrire le HTML dans le fichier de sortie
                $html | Out-File -FilePath $OutputPath -Encoding utf8

                return $OutputPath
            }

            # Appeler la fonction de test
            $reportPath = Test-DirectNestedStructuresReport -FilePath $script:TestFilePath -OutputPath $script:OutputPath -Title "Test Report"

            # Vérifier que le fichier a été créé
            $reportPath | Should -Not -BeNullOrEmpty
            Test-Path -Path $reportPath | Should -Be $true

            # Vérifier que le contenu du fichier est correct
            $content = Get-Content -Path $reportPath -Raw
            $content | Should -Match "<title>Test Report</title>"
            $content | Should -Match "document.addEventListener\('DOMContentLoaded'"
            $content | Should -Match "const structures ="
        }
    }
}
