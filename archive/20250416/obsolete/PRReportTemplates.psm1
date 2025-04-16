#Requires -Version 5.1
<#
.SYNOPSIS
    Module de templates pour les rapports d'analyse de pull requests.
.DESCRIPTION
    Fournit des templates réutilisables pour générer des rapports d'analyse
    de pull requests dans différents formats (HTML, Markdown, JSON).
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

# Registre des templates
$script:TemplateRegistry = @{}

# Fonction pour enregistrer un template
function Register-PRReportTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet("HTML", "Markdown", "JSON", "Text", "Email")]
        [string]$Format,

        [Parameter(Mandatory = $true)]
        [string]$TemplatePath,

        [Parameter()]
        [hashtable]$Metadata = @{},

        [Parameter()]
        [switch]$Force
    )

    # Vérifier si le chemin est valide
    if (-not $Force -and -not (Test-Path -Path $TemplatePath)) {
        throw "Le fichier template n'existe pas: $TemplatePath"
    }

    # Si Force est spécifié ou le fichier existe, enregistrer le template
    $templateContent = ""
    if (Test-Path -Path $TemplatePath) {
        $templateContent = Get-Content -Path $TemplatePath -Raw -ErrorAction SilentlyContinue
    }

    $script:TemplateRegistry["$Name.$Format"] = @{
        Name     = $Name
        Format   = $Format
        Path     = $TemplatePath
        Content  = $templateContent
        Metadata = $Metadata
    }

    Write-Verbose "Template '$Name' au format $Format enregistré avec succès."
}

# Fonction pour obtenir un template
function Get-PRReportTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet("HTML", "Markdown", "JSON", "Text", "Email")]
        [string]$Format
    )

    $key = "$Name.$Format"
    if (-not $script:TemplateRegistry.ContainsKey($key)) {
        throw "Template non trouvé: $key"
    }

    return $script:TemplateRegistry[$key]
}

# Fonction pour générer un rapport à partir d'un template
function New-PRReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("HTML", "Markdown", "JSON", "Text", "Email")]
        [string]$Format,

        [Parameter(Mandatory = $true)]
        [object]$Data,

        [Parameter()]
        [string]$OutputPath = ""
    )

    try {
        # Obtenir le template
        $template = Get-PRReportTemplate -Name $TemplateName -Format $Format
        $templateContent = $template.Content

        # Appliquer les données au template
        $report = $templateContent

        # Remplacer les variables dans le template
        foreach ($property in $Data.PSObject.Properties) {
            $placeholder = "{{$($property.Name)}}"
            $value = $property.Value

            # Traitement spécial pour les collections
            if (($value -is [array] -or $value -is [System.Collections.IEnumerable]) -and -not ($value -is [string])) {
                # Rechercher les sections de boucle
                $pattern = "{{#each $($property.Name)}}(.*?){{/each}}"
                $regexMatches = [regex]::Matches($report, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

                foreach ($match in $regexMatches) {
                    $sectionTemplate = $match.Groups[1].Value
                    $renderedItems = @()

                    foreach ($item in $value) {
                        $renderedItem = $sectionTemplate

                        # Remplacer les propriétés de l'élément
                        if ($item -is [PSCustomObject]) {
                            foreach ($itemProperty in $item.PSObject.Properties) {
                                $itemPlaceholder = "{{this.$($itemProperty.Name)}}"
                                $renderedItem = $renderedItem.Replace($itemPlaceholder, $itemProperty.Value)
                            }
                        } else {
                            $renderedItem = $renderedItem.Replace("{{this}}", $item)
                        }

                        $renderedItems += $renderedItem
                    }

                    $report = $report.Replace($match.Value, [string]::Join("`n", $renderedItems))
                }
            } else {
                # Remplacement simple
                $report = $report.Replace($placeholder, [string]$value)
            }
        }

        # Enregistrer le rapport si un chemin de sortie est spécifié
        if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
            $outputDir = Split-Path -Path $OutputPath -Parent
            if (-not [string]::IsNullOrWhiteSpace($outputDir) -and -not (Test-Path -Path $outputDir)) {
                New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
            }

            Set-Content -Path $OutputPath -Value $report -Encoding UTF8
            Write-Verbose "Rapport enregistré: $OutputPath"
        }

        return $report
    } catch {
        Write-Error "Erreur lors de la génération du rapport: $_"
        return $null
    }
}

# Fonction pour charger tous les templates d'un répertoire
function Import-PRReportTemplates {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplatesDirectory
    )

    if (-not (Test-Path -Path $TemplatesDirectory)) {
        throw "Le répertoire de templates n'existe pas: $TemplatesDirectory"
    }

    # Charger les templates HTML
    $htmlTemplates = Get-ChildItem -Path $TemplatesDirectory -Filter "*.html" -Recurse
    foreach ($template in $htmlTemplates) {
        $templateName = $template.BaseName
        Register-PRReportTemplate -Name $templateName -Format "HTML" -TemplatePath $template.FullName
    }

    # Charger les templates Markdown
    $mdTemplates = Get-ChildItem -Path $TemplatesDirectory -Filter "*.md" -Recurse
    foreach ($template in $mdTemplates) {
        $templateName = $template.BaseName
        Register-PRReportTemplate -Name $templateName -Format "Markdown" -TemplatePath $template.FullName
    }

    # Charger les templates JSON
    $jsonTemplates = Get-ChildItem -Path $TemplatesDirectory -Filter "*.json" -Recurse
    foreach ($template in $jsonTemplates) {
        $templateName = $template.BaseName
        Register-PRReportTemplate -Name $templateName -Format "JSON" -TemplatePath $template.FullName
    }

    # Charger les templates texte
    $txtTemplates = Get-ChildItem -Path $TemplatesDirectory -Filter "*.txt" -Recurse
    foreach ($template in $txtTemplates) {
        $templateName = $template.BaseName
        Register-PRReportTemplate -Name $templateName -Format "Text" -TemplatePath $template.FullName
    }

    Write-Verbose "Templates chargés: $($script:TemplateRegistry.Count)"
}

# Exporter les fonctions
Export-ModuleMember -Function Register-PRReportTemplate, Get-PRReportTemplate, New-PRReport, Import-PRReportTemplates
