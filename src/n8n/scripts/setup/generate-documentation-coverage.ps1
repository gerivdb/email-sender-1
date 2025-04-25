<#
.SYNOPSIS
    Script de génération d'un rapport de couverture de documentation pour Hygen.

.DESCRIPTION
    Ce script analyse les fichiers de documentation et les composants Hygen
    pour générer un rapport de couverture de documentation.

.PARAMETER OutputPath
    Chemin du fichier de rapport de couverture. Par défaut, "n8n\docs\hygen-documentation-coverage-report.md".

.EXAMPLE
    .\generate-documentation-coverage.ps1
    Génère un rapport de couverture de documentation avec le chemin par défaut.

.EXAMPLE
    .\generate-documentation-coverage.ps1 -OutputPath "C:\Temp\coverage-report.md"
    Génère un rapport de couverture de documentation avec un chemin personnalisé.

.NOTES
    Auteur: Équipe n8n
    Date de création: 2023-05-11
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ""
)

# Définir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

# Fonction pour afficher un message de succès
function Write-Success {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "✓ $Message" -ForegroundColor $successColor
}

# Fonction pour afficher un message d'erreur
function Write-Error {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "✗ $Message" -ForegroundColor $errorColor
}

# Fonction pour afficher un message d'information
function Write-Info {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "ℹ $Message" -ForegroundColor $infoColor
}

# Fonction pour afficher un message d'avertissement
function Write-Warning {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "⚠ $Message" -ForegroundColor $warningColor
}

# Fonction pour obtenir le chemin du projet
function Get-ProjectPath {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = (Get-Item $scriptPath).Parent.Parent.Parent.FullName
    return $projectRoot
}

# Fonction pour analyser les fichiers de documentation
function Analyze-Documentation {
    $projectRoot = Get-ProjectPath
    $n8nRoot = Join-Path -Path $projectRoot -ChildPath "n8n"
    $docsFolder = Join-Path -Path $n8nRoot -ChildPath "docs"

    if (-not (Test-Path -Path $docsFolder)) {
        Write-Error "Le dossier de documentation n'existe pas: $docsFolder"
        return $null
    }

    $documentationFiles = @(
        @{
            Name     = "Guide d'utilisation de Hygen"
            Path     = Join-Path -Path $docsFolder -ChildPath "hygen-guide.md"
            Required = $true
        },
        @{
            Name     = "Guide de finalisation de l'installation"
            Path     = Join-Path -Path $docsFolder -ChildPath "hygen-installation-finalization.md"
            Required = $true
        },
        @{
            Name     = "Guide de validation des templates"
            Path     = Join-Path -Path $docsFolder -ChildPath "hygen-templates-validation.md"
            Required = $true
        },
        @{
            Name     = "Guide de validation des scripts d'utilitaires"
            Path     = Join-Path -Path $docsFolder -ChildPath "hygen-utilities-validation.md"
            Required = $true
        },
        @{
            Name     = "Rapport de validation des templates"
            Path     = Join-Path -Path $docsFolder -ChildPath "hygen-templates-validation-report.md"
            Required = $false
        },
        @{
            Name     = "Rapport de validation des scripts d'utilitaires"
            Path     = Join-Path -Path $docsFolder -ChildPath "hygen-utilities-validation-report.md"
            Required = $false
        },
        @{
            Name     = "Rapport de performance"
            Path     = Join-Path -Path $docsFolder -ChildPath "hygen-performance-report.md"
            Required = $false
        },
        @{
            Name     = "Rapport global des tests"
            Path     = Join-Path -Path $docsFolder -ChildPath "hygen-global-test-report.md"
            Required = $false
        },
        @{
            Name     = "Rapport d'installation"
            Path     = Join-Path -Path $docsFolder -ChildPath "hygen-installation-report.md"
            Required = $false
        }
    )

    $results = @()

    foreach ($file in $documentationFiles) {
        $exists = Test-Path -Path $file.Path
        $size = if ($exists) { (Get-Item -Path $file.Path).Length } else { 0 }
        $wordCount = if ($exists) { (Get-Content -Path $file.Path -Raw).Split().Count } else { 0 }
        $status = if ($exists) { "Présent" } else { if ($file.Required) { "Manquant (requis)" } else { "Manquant (optionnel)" } }

        $results += [PSCustomObject]@{
            Name      = $file.Name
            Path      = $file.Path
            Exists    = $exists
            Size      = $size
            WordCount = $wordCount
            Status    = $status
            Required  = $file.Required
        }
    }

    return $results
}

# Fonction pour analyser les scripts d'utilitaires
function Analyze-UtilityScripts {
    $projectRoot = Get-ProjectPath
    $n8nRoot = Join-Path -Path $projectRoot -ChildPath "n8n"
    $scriptsFolder = Join-Path -Path $n8nRoot -ChildPath "scripts"
    $cmdFolder = Join-Path -Path $n8nRoot -ChildPath "cmd"

    if (-not (Test-Path -Path $scriptsFolder)) {
        Write-Error "Le dossier de scripts n'existe pas: $scriptsFolder"
        return $null
    }

    if (-not (Test-Path -Path $cmdFolder)) {
        Write-Error "Le dossier de scripts CMD n'existe pas: $cmdFolder"
        return $null
    }

    $utilityScripts = @(
        @{
            Name     = "Generate-N8nComponent.ps1"
            Path     = Join-Path -Path $scriptsFolder -ChildPath "utils\Generate-N8nComponent.ps1"
            Required = $true
        },
        @{
            Name     = "generate-component.cmd"
            Path     = Join-Path -Path $cmdFolder -ChildPath "utils\generate-component.cmd"
            Required = $true
        },
        @{
            Name     = "install-hygen.ps1"
            Path     = Join-Path -Path $scriptsFolder -ChildPath "setup\install-hygen.ps1"
            Required = $true
        },
        @{
            Name     = "install-hygen.cmd"
            Path     = Join-Path -Path $cmdFolder -ChildPath "utils\install-hygen.cmd"
            Required = $true
        },
        @{
            Name     = "ensure-hygen-structure.ps1"
            Path     = Join-Path -Path $scriptsFolder -ChildPath "setup\ensure-hygen-structure.ps1"
            Required = $true
        },
        @{
            Name     = "verify-hygen-installation.ps1"
            Path     = Join-Path -Path $scriptsFolder -ChildPath "setup\verify-hygen-installation.ps1"
            Required = $true
        },
        @{
            Name     = "finalize-hygen-installation.ps1"
            Path     = Join-Path -Path $scriptsFolder -ChildPath "setup\finalize-hygen-installation.ps1"
            Required = $true
        },
        @{
            Name     = "finalize-hygen.cmd"
            Path     = Join-Path -Path $cmdFolder -ChildPath "utils\finalize-hygen.cmd"
            Required = $true
        },
        @{
            Name     = "validate-hygen-templates.ps1"
            Path     = Join-Path -Path $scriptsFolder -ChildPath "setup\validate-hygen-templates.ps1"
            Required = $true
        },
        @{
            Name     = "validate-templates.cmd"
            Path     = Join-Path -Path $cmdFolder -ChildPath "utils\validate-templates.cmd"
            Required = $true
        },
        @{
            Name     = "validate-hygen-utilities.ps1"
            Path     = Join-Path -Path $scriptsFolder -ChildPath "setup\validate-hygen-utilities.ps1"
            Required = $true
        },
        @{
            Name     = "validate-utilities.cmd"
            Path     = Join-Path -Path $cmdFolder -ChildPath "utils\validate-utilities.cmd"
            Required = $true
        },
        @{
            Name     = "run-all-hygen-tests.ps1"
            Path     = Join-Path -Path $scriptsFolder -ChildPath "setup\run-all-hygen-tests.ps1"
            Required = $true
        },
        @{
            Name     = "run-all-tests.cmd"
            Path     = Join-Path -Path $cmdFolder -ChildPath "utils\run-all-tests.cmd"
            Required = $true
        }
    )

    $results = @()

    foreach ($script in $utilityScripts) {
        $exists = Test-Path -Path $script.Path
        $size = if ($exists) { (Get-Item -Path $script.Path).Length } else { 0 }
        $lineCount = if ($exists) { (Get-Content -Path $script.Path).Count } else { 0 }
        $status = if ($exists) { "Présent" } else { if ($script.Required) { "Manquant (requis)" } else { "Manquant (optionnel)" } }

        $results += [PSCustomObject]@{
            Name      = $script.Name
            Path      = $script.Path
            Exists    = $exists
            Size      = $size
            LineCount = $lineCount
            Status    = $status
            Required  = $script.Required
        }
    }

    return $results
}

# Fonction pour analyser les templates
function Analyze-Templates {
    $projectRoot = Get-ProjectPath
    $templatesFolder = Join-Path -Path $projectRoot -ChildPath "n8n/_templates"

    if (-not (Test-Path -Path $templatesFolder)) {
        Write-Error "Le dossier de templates n'existe pas: $templatesFolder"
        return $null
    }

    $templates = @(
        @{
            Name     = "n8n-script"
            Path     = Join-Path -Path $templatesFolder -ChildPath "n8n-script"
            Required = $true
        },
        @{
            Name     = "n8n-workflow"
            Path     = Join-Path -Path $templatesFolder -ChildPath "n8n-workflow"
            Required = $true
        },
        @{
            Name     = "n8n-doc"
            Path     = Join-Path -Path $templatesFolder -ChildPath "n8n-doc"
            Required = $true
        },
        @{
            Name     = "n8n-integration"
            Path     = Join-Path -Path $templatesFolder -ChildPath "n8n-integration"
            Required = $true
        }
    )

    $results = @()

    foreach ($template in $templates) {
        $exists = Test-Path -Path $template.Path
        $newFolder = Join-Path -Path $template.Path -ChildPath "new"
        $newFolderExists = Test-Path -Path $newFolder
        $helloFile = Join-Path -Path $newFolder -ChildPath "hello.ejs.t"
        $helloFileExists = Test-Path -Path $helloFile
        $promptFile = Join-Path -Path $newFolder -ChildPath "prompt.js"
        $promptFileExists = Test-Path -Path $promptFile

        $status = if ($exists -and $newFolderExists -and $helloFileExists -and $promptFileExists) {
            "Complet"
        } elseif ($exists) {
            "Incomplet"
        } else {
            if ($template.Required) { "Manquant (requis)" } else { "Manquant (optionnel)" }
        }

        $results += [PSCustomObject]@{
            Name             = $template.Name
            Path             = $template.Path
            Exists           = $exists
            NewFolderExists  = $newFolderExists
            HelloFileExists  = $helloFileExists
            PromptFileExists = $promptFileExists
            Status           = $status
            Required         = $template.Required
        }
    }

    return $results
}

# Fonction pour générer un rapport de couverture
function Generate-CoverageReport {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$DocumentationResults,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$UtilityScriptResults,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$TemplateResults,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    if ($PSCmdlet.ShouldProcess($OutputPath, "Générer le rapport")) {
        $documentationPresent = ($DocumentationResults | Where-Object { $_.Exists }).Count
        $documentationTotal = $DocumentationResults.Count
        $documentationCoverage = ($documentationPresent / $documentationTotal) * 100

        $utilityScriptsPresent = ($UtilityScriptResults | Where-Object { $_.Exists }).Count
        $utilityScriptsTotal = $UtilityScriptResults.Count
        $utilityScriptsCoverage = ($utilityScriptsPresent / $utilityScriptsTotal) * 100

        $templatesComplete = ($TemplateResults | Where-Object { $_.Status -eq "Complet" }).Count
        $templatesTotal = $TemplateResults.Count
        $templatesCoverage = ($templatesComplete / $templatesTotal) * 100

        $totalCoverage = (($documentationCoverage + $utilityScriptsCoverage + $templatesCoverage) / 3)

        $report = @"
# Rapport de couverture de documentation Hygen

## Date
$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Résumé

- **Couverture de documentation**: $($documentationPresent)/$($documentationTotal) ($($documentationCoverage.ToString("0.00"))%)
- **Couverture de scripts d'utilitaires**: $($utilityScriptsPresent)/$($utilityScriptsTotal) ($($utilityScriptsCoverage.ToString("0.00"))%)
- **Couverture de templates**: $($templatesComplete)/$($templatesTotal) ($($templatesCoverage.ToString("0.00"))%)
- **Couverture globale**: $($totalCoverage.ToString("0.00"))%

## Documentation

| Document | Statut | Taille (octets) | Nombre de mots |
|----------|--------|-----------------|----------------|
"@

        foreach ($result in $DocumentationResults) {
            $report += "`n| $($result.Name) | $($result.Status) | $($result.Size) | $($result.WordCount) |"
        }

        $report += @"

## Scripts d'utilitaires

| Script | Statut | Taille (octets) | Nombre de lignes |
|--------|--------|-----------------|------------------|
"@

        foreach ($result in $UtilityScriptResults) {
            $report += "`n| $($result.Name) | $($result.Status) | $($result.Size) | $($result.LineCount) |"
        }

        $report += @"

## Templates

| Template | Statut | Dossier new | Fichier hello.ejs.t | Fichier prompt.js |
|----------|--------|-------------|---------------------|-------------------|
"@

        foreach ($result in $TemplateResults) {
            $newFolder = if ($result.NewFolderExists) { "✓" } else { "✗" }
            $helloFile = if ($result.HelloFileExists) { "✓" } else { "✗" }
            $promptFile = if ($result.PromptFileExists) { "✓" } else { "✗" }
            $report += "`n| $($result.Name) | $($result.Status) | $newFolder | $helloFile | $promptFile |"
        }

        $report += @"

## Recommandations

"@

        # Recommandations pour la documentation
        $missingDocumentation = $DocumentationResults | Where-Object { -not $_.Exists -and $_.Required }
        if ($missingDocumentation.Count -gt 0) {
            $report += "`n### Documentation manquante (requise)"
            foreach ($doc in $missingDocumentation) {
                $report += "`n- $($doc.Name) ($($doc.Path))"
            }
        }

        $optionalMissingDocumentation = $DocumentationResults | Where-Object { -not $_.Exists -and -not $_.Required }
        if ($optionalMissingDocumentation.Count -gt 0) {
            $report += "`n`n### Documentation manquante (optionnelle)"
            foreach ($doc in $optionalMissingDocumentation) {
                $report += "`n- $($doc.Name) ($($doc.Path))"
            }
        }

        # Recommandations pour les scripts d'utilitaires
        $missingScripts = $UtilityScriptResults | Where-Object { -not $_.Exists -and $_.Required }
        if ($missingScripts.Count -gt 0) {
            $report += "`n`n### Scripts d'utilitaires manquants (requis)"
            foreach ($script in $missingScripts) {
                $report += "`n- $($script.Name) ($($script.Path))"
            }
        }

        # Recommandations pour les templates
        $incompleteTemplates = $TemplateResults | Where-Object { $_.Status -eq "Incomplet" -or $_.Status -eq "Manquant (requis)" }
        if ($incompleteTemplates.Count -gt 0) {
            $report += "`n`n### Templates incomplets ou manquants"
            foreach ($template in $incompleteTemplates) {
                $report += "`n- $($template.Name) ($($template.Path))"
                if ($template.Exists -and -not $template.NewFolderExists) {
                    $report += "`n  - Dossier 'new' manquant"
                }
                if ($template.Exists -and $template.NewFolderExists -and -not $template.HelloFileExists) {
                    $report += "`n  - Fichier 'hello.ejs.t' manquant"
                }
                if ($template.Exists -and $template.NewFolderExists -and -not $template.PromptFileExists) {
                    $report += "`n  - Fichier 'prompt.js' manquant"
                }
            }
        }

        $report += @"

## Conclusion

"@

        if ($totalCoverage -ge 90) {
            $report += "`nLa couverture de documentation est excellente. Tous les éléments essentiels sont présents et bien documentés."
        } elseif ($totalCoverage -ge 75) {
            $report += "`nLa couverture de documentation est bonne. La plupart des éléments essentiels sont présents, mais quelques améliorations sont possibles."
        } elseif ($totalCoverage -ge 50) {
            $report += "`nLa couverture de documentation est moyenne. Plusieurs éléments essentiels sont manquants ou incomplets."
        } else {
            $report += "`nLa couverture de documentation est insuffisante. De nombreux éléments essentiels sont manquants ou incomplets."
        }

        $report += @"

## Prochaines étapes

1. Créer la documentation manquante
2. Compléter les templates incomplets
3. Ajouter les scripts d'utilitaires manquants
4. Améliorer la qualité de la documentation existante
"@

        Set-Content -Path $OutputPath -Value $report
        Write-Success "Rapport de couverture généré: $OutputPath"

        return $OutputPath
    } else {
        return $null
    }
}

# Fonction principale
function Start-DocumentationCoverageAnalysis {
    Write-Info "Analyse de la couverture de documentation Hygen..."

    # Déterminer le chemin de sortie
    $projectRoot = Get-ProjectPath
    $n8nRoot = Join-Path -Path $projectRoot -ChildPath "n8n"
    $docsFolder = Join-Path -Path $n8nRoot -ChildPath "docs"

    if ([string]::IsNullOrEmpty($OutputPath)) {
        $OutputPath = Join-Path -Path $docsFolder -ChildPath "hygen-documentation-coverage-report.md"
    }

    # Analyser la documentation
    Write-Info "Analyse des fichiers de documentation..."
    $documentationResults = Analyze-Documentation

    # Analyser les scripts d'utilitaires
    Write-Info "Analyse des scripts d'utilitaires..."
    $utilityScriptResults = Analyze-UtilityScripts

    # Analyser les templates
    Write-Info "Analyse des templates..."
    $templateResults = Analyze-Templates

    # Générer le rapport de couverture
    Write-Info "Génération du rapport de couverture..."
    $reportPath = Generate-CoverageReport -DocumentationResults $documentationResults -UtilityScriptResults $utilityScriptResults -TemplateResults $templateResults -OutputPath $OutputPath

    # Afficher le résultat
    if ($reportPath) {
        Write-Success "Rapport de couverture généré: $reportPath"
    } else {
        Write-Error "Impossible de générer le rapport de couverture"
    }

    return $reportPath
}

# Exécuter l'analyse
Start-DocumentationCoverageAnalysis
