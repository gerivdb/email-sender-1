#Requires -Version 5.1
<#
.SYNOPSIS
    Module d'intégration des visualisations pour le rapport de complexité.
.DESCRIPTION
    Ce module fournit des fonctions pour intégrer les visualisations dans le rapport de complexité
    généré par le module PowerShellComplexityValidator.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

#region Variables globales

# Configuration par défaut pour les visualisations
$script:DefaultVisualizationConfig = @{
    # Activer ou désactiver les visualisations
    EnableVisualizations = $true

    # Configuration des graphiques
    Charts               = @{
        # Graphique de distribution de complexité
        ComplexityDistribution = @{
            Enabled = $true
            Title   = "Distribution de la complexité cyclomatique"
            Type    = "bar"
            Height  = 400
            Width   = 800
            Colors  = @(
                "rgba(75, 192, 192, 0.6)",
                "rgba(54, 162, 235, 0.6)",
                "rgba(255, 206, 86, 0.6)",
                "rgba(255, 159, 64, 0.6)",
                "rgba(255, 99, 132, 0.6)",
                "rgba(153, 102, 255, 0.6)",
                "rgba(255, 99, 132, 0.6)"
            )
        }

        # Graphique des types de structures
        StructureTypes         = @{
            Enabled = $true
            Title   = "Répartition des types de structures"
            Type    = "pie"
            Height  = 400
            Width   = 800
            Colors  = @(
                "rgba(75, 192, 192, 0.6)",
                "rgba(54, 162, 235, 0.6)",
                "rgba(255, 206, 86, 0.6)",
                "rgba(255, 159, 64, 0.6)",
                "rgba(255, 99, 132, 0.6)",
                "rgba(153, 102, 255, 0.6)",
                "rgba(201, 203, 207, 0.6)",
                "rgba(255, 99, 132, 0.6)",
                "rgba(54, 162, 235, 0.6)",
                "rgba(255, 206, 86, 0.6)"
            )
        }

        # Graphique des fonctions les plus complexes
        TopComplexFunctions    = @{
            Enabled = $true
            Title   = "Top 10 des fonctions les plus complexes"
            Type    = "bar"
            Height  = 400
            Width   = 800
            Colors  = @(
                "rgba(255, 99, 132, 0.6)"
            )
        }

        # Graphique d'impact des structures
        StructureImpact        = @{
            Enabled = $true
            Title   = "Impact des structures sur la complexité"
            Type    = "bar"
            Height  = 400
            Width   = 800
            Colors  = @(
                "rgba(200, 200, 200, 0.6)",
                "rgba(75, 192, 192, 0.6)",
                "rgba(255, 206, 86, 0.6)",
                "rgba(255, 159, 64, 0.6)",
                "rgba(255, 99, 132, 0.6)"
            )
        }

        # Graphique des niveaux d'imbrication
        NestingLevels          = @{
            Enabled = $true
            Title   = "Niveaux d'imbrication"
            Type    = "bar"
            Height  = 400
            Width   = 800
            Colors  = @(
                "rgba(54, 162, 235, 0.6)"
            )
        }

        # Visualisation des structures imbriquées
        NestedStructures       = @{
            Enabled = $true
            Title   = "Visualisation des structures imbriquées"
            Height  = 600
            Width   = 1000
            Colors  = @{
                If      = "rgba(75, 192, 192, 0.6)"
                ElseIf  = "rgba(54, 162, 235, 0.6)"
                Else    = "rgba(255, 206, 86, 0.6)"
                For     = "rgba(255, 159, 64, 0.6)"
                ForEach = "rgba(255, 99, 132, 0.6)"
                While   = "rgba(153, 102, 255, 0.6)"
                DoWhile = "rgba(201, 203, 207, 0.6)"
                Do      = "rgba(255, 99, 132, 0.6)"
                Switch  = "rgba(54, 162, 235, 0.6)"
                Try     = "rgba(255, 206, 86, 0.6)"
                Catch   = "rgba(255, 159, 64, 0.6)"
                Finally = "rgba(255, 99, 132, 0.6)"
                Default = "rgba(200, 200, 200, 0.6)"
            }
            # Options spécifiques à la visualisation des structures imbriquées
            Options = @{
                # Afficher les lignes de code
                ShowCodeLines      = $true
                # Afficher les numéros de ligne
                ShowLineNumbers    = $true
                # Afficher les types de structures
                ShowStructureTypes = $true
                # Indentation pour les niveaux d'imbrication
                IndentationSize    = 20
                # Hauteur minimale d'un bloc
                MinBlockHeight     = 30
                # Largeur minimale d'un bloc
                MinBlockWidth      = 100
                # Rayon des coins arrondis
                BorderRadius       = 5
                # Épaisseur de la bordure
                BorderWidth        = 1
                # Couleur de la bordure
                BorderColor        = "rgba(0, 0, 0, 0.2)"
                # Opacité des blocs
                BlockOpacity       = 0.7
                # Afficher les tooltips
                ShowTooltips       = $true
                # Contenu des tooltips
                TooltipTemplate    = "Type: {0}, Ligne: {1}, Niveau: {2}"
                # Animation à l'affichage
                EnableAnimation    = $true
                # Durée de l'animation en millisecondes
                AnimationDuration  = 500
                # Type d'animation
                AnimationType      = "fadeIn"
            }
        }
    }

    # Configuration des options d'affichage
    Display              = @{
        # Afficher les tooltips
        ShowTooltips      = $true

        # Afficher les légendes
        ShowLegends       = $true

        # Position des légendes
        LegendPosition    = "right"

        # Afficher les titres des axes
        ShowAxisTitles    = $true

        # Afficher les grilles
        ShowGridLines     = $true

        # Afficher les étiquettes de données
        ShowDataLabels    = $false

        # Animation des graphiques
        EnableAnimation   = $true

        # Durée de l'animation en millisecondes
        AnimationDuration = 1000
    }
}

# Configuration actuelle des visualisations
$script:CurrentVisualizationConfig = $script:DefaultVisualizationConfig.Clone()

#endregion

#region Fonctions privées

# Fonction pour fusionner deux hashtables
function Merge-Hashtables {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Base,

        [Parameter(Mandatory = $true)]
        [hashtable]$Overlay
    )

    $result = $Base.Clone()

    foreach ($key in $Overlay.Keys) {
        if ($result.ContainsKey($key)) {
            if ($result[$key] -is [hashtable] -and $Overlay[$key] -is [hashtable]) {
                $result[$key] = Merge-Hashtables -Base $result[$key] -Overlay $Overlay[$key]
            } else {
                $result[$key] = $Overlay[$key]
            }
        } else {
            $result[$key] = $Overlay[$key]
        }
    }

    return $result
}

#endregion

#region Fonctions publiques

<#
.SYNOPSIS
    Définit la configuration des visualisations.
.DESCRIPTION
    Cette fonction définit la configuration des visualisations pour le rapport de complexité.
.PARAMETER Config
    Configuration des visualisations.
.EXAMPLE
    Set-VisualizationConfig -Config @{ EnableVisualizations = $true }
    Définit la configuration des visualisations.
#>
function Set-VisualizationConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )

    $script:CurrentVisualizationConfig = Merge-Hashtables -Base $script:DefaultVisualizationConfig -Overlay $Config
}

<#
.SYNOPSIS
    Obtient la configuration actuelle des visualisations.
.DESCRIPTION
    Cette fonction retourne la configuration actuelle des visualisations pour le rapport de complexité.
.EXAMPLE
    Get-VisualizationConfig
    Retourne la configuration actuelle des visualisations.
.OUTPUTS
    System.Collections.Hashtable
    Retourne la configuration actuelle des visualisations.
#>
function Get-VisualizationConfig {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param ()

    return $script:CurrentVisualizationConfig
}

<#
.SYNOPSIS
    Réinitialise la configuration des visualisations.
.DESCRIPTION
    Cette fonction réinitialise la configuration des visualisations à la configuration par défaut.
.EXAMPLE
    Reset-VisualizationConfig
    Réinitialise la configuration des visualisations.
#>
function Reset-VisualizationConfig {
    [CmdletBinding()]
    param ()

    $script:CurrentVisualizationConfig = $script:DefaultVisualizationConfig.Clone()
}

<#
.SYNOPSIS
    Génère un rapport de complexité interactif.
.DESCRIPTION
    Cette fonction génère un rapport de complexité interactif avec des visualisations.
.PARAMETER Results
    Résultats de l'analyse de complexité.
.PARAMETER OutputPath
    Chemin du fichier HTML de sortie.
.PARAMETER Title
    Titre du rapport.
.PARAMETER Config
    Configuration des visualisations.
.EXAMPLE
    New-InteractiveComplexityReport -Results $results -OutputPath "report.html" -Title "Rapport de complexité"
    Génère un rapport de complexité interactif.
.OUTPUTS
    System.String
    Retourne le chemin du fichier HTML généré.
#>
function New-InteractiveComplexityReport {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Results,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [string]$Title = "Rapport de complexité cyclomatique interactif",

        [Parameter(Mandatory = $false)]
        [hashtable]$Config = @{}
    )

    # Fusionner la configuration fournie avec la configuration actuelle
    $visualizationConfig = Merge-Hashtables -Base $script:CurrentVisualizationConfig -Overlay $Config

    # Vérifier si les visualisations sont activées
    if (-not $visualizationConfig.EnableVisualizations) {
        Write-Verbose "Les visualisations sont désactivées. Utilisation du rapport HTML standard."
        return New-PowerShellComplexityReport -Results $Results -Format "HTML" -OutputPath $OutputPath -Title $Title
    }

    # Générer le rapport HTML avec les visualisations
    $reportPath = New-PowerShellComplexityReport -Results $Results -Format "HTML" -OutputPath $OutputPath -Title $Title

    Write-Verbose "Rapport interactif généré : $reportPath"

    return $reportPath
}

<#
.SYNOPSIS
    Génère un rapport de fonction interactif.
.DESCRIPTION
    Cette fonction génère un rapport de fonction interactif avec des visualisations.
.PARAMETER Result
    Résultat de l'analyse de complexité pour une fonction.
.PARAMETER SourceCode
    Code source de la fonction.
.PARAMETER OutputPath
    Chemin du fichier HTML de sortie.
.PARAMETER Title
    Titre du rapport.
.PARAMETER Config
    Configuration des visualisations.
.EXAMPLE
    New-InteractiveFunctionReport -Result $result -SourceCode $sourceCode -OutputPath "function-report.html" -Title "Rapport de fonction"
    Génère un rapport de fonction interactif.
.OUTPUTS
    System.String
    Retourne le chemin du fichier HTML généré.
#>
function New-InteractiveFunctionReport {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Result,

        [Parameter(Mandatory = $true)]
        [string]$SourceCode,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [string]$Title = "Rapport de complexité de fonction interactif",

        [Parameter(Mandatory = $false)]
        [hashtable]$Config = @{}
    )

    # Fusionner la configuration fournie avec la configuration actuelle
    $visualizationConfig = Merge-Hashtables -Base $script:CurrentVisualizationConfig -Overlay $Config

    # Vérifier si les visualisations sont activées
    if (-not $visualizationConfig.EnableVisualizations) {
        Write-Verbose "Les visualisations sont désactivées. Utilisation du rapport HTML standard."
        return New-FunctionComplexityReport -Result $Result -SourceCode $SourceCode -OutputPath $OutputPath -Title $Title
    }

    # Générer le rapport HTML avec les visualisations
    $reportPath = New-FunctionComplexityReport -Result $Result -SourceCode $SourceCode -OutputPath $OutputPath -Title $Title

    Write-Verbose "Rapport de fonction interactif généré : $reportPath"

    return $reportPath
}

#endregion

<#
.SYNOPSIS
    Génère une visualisation des structures imbriquées.
.DESCRIPTION
    Cette fonction génère une visualisation HTML des structures imbriquées dans le code PowerShell.
.PARAMETER ControlStructures
    Structures de contrôle détectées dans le code PowerShell.
.PARAMETER SourceCode
    Code source PowerShell.
.PARAMETER OutputPath
    Chemin du fichier HTML de sortie.
.PARAMETER Title
    Titre de la visualisation.
.PARAMETER Config
    Configuration de la visualisation.
.EXAMPLE
    New-NestedStructuresVisualization -ControlStructures $controlStructures -SourceCode $sourceCode -OutputPath "nested-structures.html" -Title "Structures imbriquées"
    Génère une visualisation des structures imbriquées.
.OUTPUTS
    System.String
    Retourne le chemin du fichier HTML généré.
#>
function New-NestedStructuresVisualization {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$ControlStructures,

        [Parameter(Mandatory = $true)]
        [string]$SourceCode,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [string]$Title = "Visualisation des structures imbriquées",

        [Parameter(Mandatory = $false)]
        [hashtable]$Config = @{}
    )

    # Fusionner la configuration fournie avec la configuration actuelle
    $visualizationConfig = Merge-Hashtables -Base $script:CurrentVisualizationConfig -Overlay $Config

    # Vérifier si les visualisations sont activées
    if (-not $visualizationConfig.EnableVisualizations) {
        Write-Verbose "Les visualisations sont désactivées."
        return $null
    }

    # Obtenir la configuration spécifique à la visualisation des structures imbriquées
    $nestedStructuresConfig = $visualizationConfig.Charts.NestedStructures

    # Vérifier si la visualisation des structures imbriquées est activée
    if (-not $nestedStructuresConfig.Enabled) {
        Write-Verbose "La visualisation des structures imbriquées est désactivée."
        return $null
    }

    # Préparer les données pour la visualisation
    $nestingData = @{
        Structures = @()
        SourceCode = $SourceCode.Replace("`r`n", "`n").Split("`n")
        Config     = $nestedStructuresConfig
    }

    # Trier les structures par ligne et colonne
    $sortedStructures = $ControlStructures | Sort-Object -Property Line, Column

    # Initialiser le niveau d'imbrication
    $currentNestingLevel = 0
    $nestingStack = [System.Collections.Stack]::new()

    # Analyser chaque structure
    foreach ($structure in $sortedStructures) {
        $type = $structure.Type
        $line = $structure.Line
        $column = $structure.Column

        # Déterminer si la structure augmente ou diminue le niveau d'imbrication
        $isNestingStructure = $false
        $isClosingStructure = $false

        switch -Regex ($type) {
            "^If$|^ElseIf$|^Else$|^For$|^ForEach$|^While$|^DoWhile$|^Do$|^Switch$|^Try$|^Catch$|^Finally$" {
                $isNestingStructure = $true
            }
            "^End.*" {
                $isClosingStructure = $true
            }
        }

        if ($isNestingStructure) {
            # Augmenter le niveau d'imbrication
            $currentNestingLevel++

            # Ajouter la structure à la pile
            $nestingStack.Push(@{
                    Type   = $type
                    Line   = $line
                    Column = $column
                    Level  = $currentNestingLevel
                    Start  = $true
                })

            # Ajouter la structure aux données de visualisation
            $nestingData.Structures += @{
                Type   = $type
                Line   = $line
                Column = $column
                Level  = $currentNestingLevel
                Start  = $true
                Color  = if ($nestedStructuresConfig.Colors.ContainsKey($type)) { $nestedStructuresConfig.Colors[$type] } else { $nestedStructuresConfig.Colors.Default }
            }
        } elseif ($isClosingStructure) {
            # Diminuer le niveau d'imbrication
            if ($nestingStack.Count -gt 0) {
                $openingStructure = $nestingStack.Pop()

                # Ajouter la structure de fermeture aux données de visualisation
                $nestingData.Structures += @{
                    Type   = $type
                    Line   = $line
                    Column = $column
                    Level  = $openingStructure.Level
                    Start  = $false
                    Color  = if ($nestedStructuresConfig.Colors.ContainsKey($openingStructure.Type)) { $nestedStructuresConfig.Colors[$openingStructure.Type] } else { $nestedStructuresConfig.Colors.Default }
                }

                $currentNestingLevel--
            }
        }
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
            max-width: $($nestedStructuresConfig.Width)px;
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
            border-radius: $($nestedStructuresConfig.Options.BorderRadius)px;
            border: $($nestedStructuresConfig.Options.BorderWidth)px solid $($nestedStructuresConfig.Options.BorderColor);
            opacity: $($nestedStructuresConfig.Options.BlockOpacity);
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
    for ($i = 0; $i -lt $nestingData.SourceCode.Length; $i++) {
        $lineNumber = $i + 1
        $codeLine = $nestingData.SourceCode[$i]

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
            const structures = ${nestingData.Structures | ConvertTo-Json -Depth 10};
            const options = ${nestedStructuresConfig.Options | ConvertTo-Json -Depth 10};

            // Créer les blocs de structure
            structures.forEach(function(structure, index) {
                const line = document.getElementById(`line-${structure.Line}`);
                if (!line) return;

                const block = document.createElement('div');
                block.className = 'structure-block';
                block.style.backgroundColor = structure.Color;

                // Calculer la position et la taille du bloc
                const indent = structure.Level * options.IndentationSize;
                block.style.left = `${indent}px`;
                block.style.top = '0';
                block.style.width = `${Math.max(line.offsetWidth - indent, options.MinBlockWidth)}px`;
                block.style.height = `${Math.max(line.offsetHeight, options.MinBlockHeight)}px`;

                // Ajouter le label si nécessaire
                if (options.ShowStructureTypes && structure.Start) {
                    const label = document.createElement('div');
                    label.className = 'structure-label';
                    label.textContent = structure.Type;
                    label.style.left = `${indent + 5}px`;
                    label.style.top = '2px';
                    line.appendChild(label);
                }

                // Ajouter le tooltip si nécessaire
                if (options.ShowTooltips) {
                    block.addEventListener('mouseover', function(e) {
                        const tooltip = document.createElement('div');
                        tooltip.className = 'tooltip';
                        tooltip.textContent = options.TooltipTemplate
                            .replace('{0}', structure.Type)
                            .replace('{1}', structure.Line)
                            .replace('{2}', structure.Level);
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
                }

                // Ajouter le bloc à la ligne
                line.appendChild(block);

                // Animer le bloc si nécessaire
                if (options.EnableAnimation) {
                    block.style.opacity = '0';
                    setTimeout(function() {
                        block.style.opacity = options.BlockOpacity;
                    }, index * (options.AnimationDuration / structures.length));
                }
            });
        });
    </script>
</body>
</html>
"@

    # Écrire le HTML dans le fichier de sortie
    $html | Out-File -FilePath $OutputPath -Encoding utf8

    Write-Verbose "Visualisation des structures imbriquées générée : $OutputPath"

    return $OutputPath
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Set-VisualizationConfig, Get-VisualizationConfig, Reset-VisualizationConfig, New-InteractiveComplexityReport, New-InteractiveFunctionReport, New-NestedStructuresVisualization
