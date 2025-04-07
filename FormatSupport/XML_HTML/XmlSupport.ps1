# Module principal pour le support XML
# Ce script sert de point d'entrée pour utiliser toutes les fonctionnalités XML

# Importer les modules
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$implementationPath = Join-Path -Path $scriptPath -ChildPath "Implementation"
$converterPath = Join-Path -Path $implementationPath -ChildPath "RoadmapXmlConverter.ps1"
$detectorPath = Join-Path -Path $implementationPath -ChildPath "XmlElementDetector.ps1"
$validatorPath = Join-Path -Path $implementationPath -ChildPath "XmlValidator.ps1"

# Importer les modules
. $converterPath
. $detectorPath
. $validatorPath

# Fonction pour afficher l'aide
function Show-XmlSupportHelp {
    Write-Host "Module de support XML" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Ce module fournit des fonctionnalités pour travailler avec les fichiers XML," -ForegroundColor Yellow
    Write-Host "notamment pour convertir entre le format Roadmap (Markdown) et XML." -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Fonctions de conversion Roadmap-XML:" -ForegroundColor Green
    Write-Host "  ConvertFrom-RoadmapToXml           - Convertit une chaîne Roadmap en XML"
    Write-Host "  ConvertFrom-XmlToRoadmap           - Convertit une chaîne XML en Roadmap"
    Write-Host "  ConvertFrom-RoadmapFileToXmlFile   - Convertit un fichier Roadmap en fichier XML"
    Write-Host "  ConvertFrom-XmlFileToRoadmapFile   - Convertit un fichier XML en fichier Roadmap"
    Write-Host ""
    
    Write-Host "Fonctions de détection XML:" -ForegroundColor Green
    Write-Host "  Get-XmlElements                    - Détecte les éléments XML dans une chaîne"
    Write-Host "  Get-XmlElementsFromFile            - Détecte les éléments XML dans un fichier"
    Write-Host "  Get-XmlStructureReport             - Génère un rapport sur la structure XML"
    Write-Host "  Get-XmlStructureReportFromFile     - Génère un rapport sur la structure XML d'un fichier"
    Write-Host "  ConvertTo-RoadmapMapping           - Mappe les éléments XML vers la structure de roadmap"
    Write-Host ""
    
    Write-Host "Fonctions de validation XML:" -ForegroundColor Green
    Write-Host "  Test-XmlContent                    - Valide une chaîne XML"
    Write-Host "  Test-XmlFile                       - Valide un fichier XML"
    Write-Host "  Get-XmlValidationReport            - Génère un rapport de validation XML"
    Write-Host "  Test-XmlFileWithReport             - Valide un fichier XML et génère un rapport"
    Write-Host "  Test-XmlFileAgainstSchema          - Valide un fichier XML par rapport à un schéma XSD"
    Write-Host "  New-XsdSchemaFromXml               - Génère un schéma XSD à partir d'un fichier XML"
    Write-Host ""
    
    Write-Host "Exemples:" -ForegroundColor Yellow
    Write-Host "  # Convertir un fichier Roadmap en XML"
    Write-Host "  ConvertFrom-RoadmapFileToXmlFile -RoadmapPath 'roadmap.md' -XmlPath 'roadmap.xml'"
    Write-Host ""
    
    Write-Host "  # Convertir un fichier XML en Roadmap"
    Write-Host "  ConvertFrom-XmlFileToRoadmapFile -XmlPath 'roadmap.xml' -RoadmapPath 'roadmap.md'"
    Write-Host ""
    
    Write-Host "  # Générer un rapport sur la structure XML"
    Write-Host "  Get-XmlStructureReportFromFile -XmlPath 'roadmap.xml' -OutputPath 'report.html' -AsHtml"
    Write-Host ""
    
    Write-Host "  # Valider un fichier XML"
    Write-Host "  Test-XmlFileWithReport -XmlPath 'roadmap.xml' -OutputPath 'validation.html' -AsHtml"
    Write-Host ""
}

# Fonction pour exécuter les tests
function Invoke-XmlSupportTests {
    $testsPath = Join-Path -Path $scriptPath -ChildPath "Tests"
    $converterTestPath = Join-Path -Path $testsPath -ChildPath "Test-RoadmapXmlConverter.ps1"
    $toolsTestPath = Join-Path -Path $testsPath -ChildPath "Test-XmlTools.ps1"
    
    Write-Host "Exécution des tests du module de support XML..." -ForegroundColor Yellow
    
    $results = @{
        TotalTests = 0
        PassedTests = 0
        FailedTests = 0
    }
    
    # Exécuter les tests du convertisseur
    if (Test-Path -Path $converterTestPath) {
        Write-Host "Exécution des tests du convertisseur Roadmap-XML..." -ForegroundColor Cyan
        $converterResults = & $converterTestPath
        
        $results.TotalTests += $converterResults.TotalTests
        $results.PassedTests += $converterResults.PassedTests
        $results.FailedTests += $converterResults.FailedTests
    }
    else {
        Write-Host "Le script de tests du convertisseur est introuvable: $converterTestPath" -ForegroundColor Red
    }
    
    # Exécuter les tests des outils XML
    if (Test-Path -Path $toolsTestPath) {
        Write-Host "Exécution des tests des outils XML..." -ForegroundColor Cyan
        $toolsResults = & $toolsTestPath
        
        $results.TotalTests += $toolsResults.TotalTests
        $results.PassedTests += $toolsResults.PassedTests
        $results.FailedTests += $toolsResults.FailedTests
    }
    else {
        Write-Host "Le script de tests des outils XML est introuvable: $toolsTestPath" -ForegroundColor Red
    }
    
    # Afficher le résumé des tests
    Write-Host "Résumé des tests:" -ForegroundColor Yellow
    Write-Host "  Total: $($results.TotalTests)" -ForegroundColor Cyan
    Write-Host "  Réussis: $($results.PassedTests)" -ForegroundColor Green
    Write-Host "  Échoués: $($results.FailedTests)" -ForegroundColor Red
    
    return $results
}

# Fonction pour convertir un fichier d'un format à un autre
function Convert-FormatFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputPath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("roadmap", "xml")]
        [string]$InputFormat,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("roadmap", "xml")]
        [string]$OutputFormat,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ConversionSettings
    )
    
    # Vérifier si les formats d'entrée et de sortie sont identiques
    if ($InputFormat -eq $OutputFormat) {
        Write-Error "Les formats d'entrée et de sortie sont identiques: $InputFormat"
        return $false
    }
    
    # Vérifier si le fichier d'entrée existe
    if (-not (Test-Path -Path $InputPath)) {
        Write-Error "Le fichier d'entrée n'existe pas: $InputPath"
        return $false
    }
    
    try {
        # Convertir le fichier
        switch ("$InputFormat-$OutputFormat") {
            "roadmap-xml" {
                ConvertFrom-RoadmapFileToXmlFile -RoadmapPath $InputPath -XmlPath $OutputPath -Settings $ConversionSettings
            }
            "xml-roadmap" {
                ConvertFrom-XmlFileToRoadmapFile -XmlPath $InputPath -RoadmapPath $OutputPath -Settings $ConversionSettings
            }
            default {
                Write-Error "Conversion non prise en charge: $InputFormat -> $OutputFormat"
                return $false
            }
        }
        
        Write-Host "Conversion réussie: $InputPath -> $OutputPath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Erreur lors de la conversion: $_"
        return $false
    }
}

# Fonction pour analyser un fichier XML
function Invoke-XmlAnalysis {
    param (
        [Parameter(Mandatory = $true)]
        [string]$XmlPath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$AsHtml,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeValidation,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeStructure,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeMapping
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $InputPath)) {
        Write-Error "Le fichier XML n'existe pas: $InputPath"
        return $false
    }
    
    # Créer le répertoire de sortie si nécessaire
    if ($OutputPath) {
        $outputDir = Split-Path -Path $OutputPath -Parent
        
        if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
    }
    
    # Lire le contenu du fichier XML
    $xmlContent = Get-Content -Path $XmlPath -Raw
    
    # Initialiser le rapport
    $report = ""
    
    # Ajouter l'en-tête du rapport
    if ($AsHtml) {
        $report += @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport d'analyse XML</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        h2 { color: #666; }
        pre { background-color: #f5f5f5; padding: 10px; border: 1px solid #ddd; }
        .success { color: green; }
        .error { color: red; }
        .warning { color: orange; }
    </style>
</head>
<body>
    <h1>Rapport d'analyse XML</h1>
    <p>Fichier: $XmlPath</p>
    
"@
    }
    else {
        $report += "Rapport d'analyse XML`n"
        $report += "=====================`n`n"
        $report += "Fichier: $XmlPath`n`n"
    }
    
    # Ajouter la validation
    if ($IncludeValidation) {
        $validationResult = Test-XmlFile -XmlPath $XmlPath
        
        if ($AsHtml) {
            $report += "<h2>Validation XML</h2>`n"
            $report += "<p>Validation: <span class=`"$($validationResult.IsValid ? "success" : "error")`">$($validationResult.IsValid ? "Réussie" : "Échouée")</span></p>`n"
            $report += "<p>Version XML: $($validationResult.XmlVersion)</p>`n"
            $report += "<p>Encodage: $($validationResult.Encoding)</p>`n"
            $report += "<p>Autonome: $($validationResult.Standalone)</p>`n"
            $report += "<p>Erreurs: $($validationResult.Errors.Count)</p>`n"
            $report += "<p>Avertissements: $($validationResult.Warnings.Count)</p>`n"
            
            if ($validationResult.Errors.Count -gt 0) {
                $report += "<h3>Erreurs</h3>`n"
                $report += "<ul>`n"
                
                foreach ($error in $validationResult.Errors) {
                    $report += "<li><span class=`"error`">$($error.ToString())</span></li>`n"
                }
                
                $report += "</ul>`n"
            }
            
            if ($validationResult.Warnings.Count -gt 0) {
                $report += "<h3>Avertissements</h3>`n"
                $report += "<ul>`n"
                
                foreach ($warning in $validationResult.Warnings) {
                    $report += "<li><span class=`"warning`">$($warning.ToString())</span></li>`n"
                }
                
                $report += "</ul>`n"
            }
        }
        else {
            $report += "Validation XML`n"
            $report += "-------------`n`n"
            $report += "Validation: $($validationResult.IsValid ? "Réussie" : "Échouée")`n"
            $report += "Version XML: $($validationResult.XmlVersion)`n"
            $report += "Encodage: $($validationResult.Encoding)`n"
            $report += "Autonome: $($validationResult.Standalone)`n"
            $report += "Erreurs: $($validationResult.Errors.Count)`n"
            $report += "Avertissements: $($validationResult.Warnings.Count)`n`n"
            
            if ($validationResult.Errors.Count -gt 0) {
                $report += "Erreurs:`n"
                
                foreach ($error in $validationResult.Errors) {
                    $report += "- $($error.ToString())`n"
                }
                
                $report += "`n"
            }
            
            if ($validationResult.Warnings.Count -gt 0) {
                $report += "Avertissements:`n"
                
                foreach ($warning in $validationResult.Warnings) {
                    $report += "- $($warning.ToString())`n"
                }
                
                $report += "`n"
            }
        }
    }
    
    # Ajouter la structure
    if ($IncludeStructure) {
        $elements = Get-XmlElements -XmlContent $xmlContent
        
        if ($AsHtml) {
            $report += "<h2>Structure XML</h2>`n"
            $report += "<p>Nombre d'éléments: $($elements.Count)</p>`n"
            $report += "<p>Profondeur maximale: $($elements | Measure-Object -Property Depth -Maximum | Select-Object -ExpandProperty Maximum)</p>`n"
            
            $report += "<h3>Éléments</h3>`n"
            $report += "<table>`n"
            $report += "<tr><th>Nom</th><th>Chemin</th><th>Profondeur</th><th>Attributs</th><th>Valeur</th></tr>`n"
            
            foreach ($element in $elements) {
                $report += "<tr>`n"
                $report += "<td>$($element.Name)</td>`n"
                $report += "<td>$($element.Path)</td>`n"
                $report += "<td>$($element.Depth)</td>`n"
                $report += "<td>"
                
                if ($element.Attributes.Count -gt 0) {
                    $report += "<ul>`n"
                    
                    foreach ($attrName in $element.Attributes.Keys) {
                        $report += "<li>$attrName = $($element.Attributes[$attrName])</li>`n"
                    }
                    
                    $report += "</ul>`n"
                }
                
                $report += "</td>`n"
                $report += "<td>$($element.Value)</td>`n"
                $report += "</tr>`n"
            }
            
            $report += "</table>`n"
        }
        else {
            $report += "Structure XML`n"
            $report += "------------`n`n"
            $report += "Nombre d'éléments: $($elements.Count)`n"
            $report += "Profondeur maximale: $($elements | Measure-Object -Property Depth -Maximum | Select-Object -ExpandProperty Maximum)`n`n"
            
            $report += "Éléments:`n"
            
            foreach ($element in $elements) {
                $indent = "  " * $element.Depth
                $report += "$indent- $($element.Name) ($($element.Path))`n"
                
                if ($element.Attributes.Count -gt 0) {
                    $report += "$indent  Attributs:`n"
                    
                    foreach ($attrName in $element.Attributes.Keys) {
                        $report += "$indent    $attrName = $($element.Attributes[$attrName])`n"
                    }
                }
                
                if ($element.Value) {
                    $report += "$indent  Valeur: $($element.Value)`n"
                }
                
                $report += "`n"
            }
        }
    }
    
    # Ajouter le mapping
    if ($IncludeMapping) {
        $mappingResult = ConvertTo-RoadmapMapping -XmlContent $xmlContent
        $mapping = $mappingResult.Mapping
        
        if ($AsHtml) {
            $report += "<h2>Mapping XML vers Roadmap</h2>`n"
            
            $report += "<h3>Élément racine</h3>`n"
            $report += "<p>$($mapping.RootElement.Name) ($($mapping.RootElement.Path))</p>`n"
            
            $report += "<h3>Sections ($($mapping.Sections.Count))</h3>`n"
            $report += "<ul>`n"
            
            foreach ($section in $mapping.Sections) {
                $report += "<li>$($section.Name) ($($section.Path))`n"
                $report += "<ul>`n"
                $report += "<li>ID: $($section.Attributes["id"])</li>`n"
                $report += "<li>Titre: $($section.Attributes["title"])</li>`n"
                $report += "</ul>`n"
                $report += "</li>`n"
            }
            
            $report += "</ul>`n"
            
            $report += "<h3>Phases ($($mapping.Phases.Count))</h3>`n"
            $report += "<ul>`n"
            
            foreach ($phase in $mapping.Phases) {
                $report += "<li>$($phase.Name) ($($phase.Path))`n"
                $report += "<ul>`n"
                $report += "<li>ID: $($phase.Attributes["id"])</li>`n"
                $report += "<li>Titre: $($phase.Attributes["title"])</li>`n"
                $report += "<li>Terminée: $($phase.Attributes["completed"])</li>`n"
                $report += "</ul>`n"
                $report += "</li>`n"
            }
            
            $report += "</ul>`n"
            
            $report += "<h3>Tâches ($($mapping.Tasks.Count))</h3>`n"
            $report += "<ul>`n"
            
            foreach ($task in $mapping.Tasks) {
                $report += "<li>$($task.Name) ($($task.Path))`n"
                $report += "<ul>`n"
                $report += "<li>Titre: $($task.Attributes["title"])</li>`n"
                $report += "<li>Temps estimé: $($task.Attributes["estimatedTime"])</li>`n"
                $report += "<li>Date de début: $($task.Attributes["startDate"])</li>`n"
                $report += "<li>Terminée: $($task.Attributes["completed"])</li>`n"
                $report += "</ul>`n"
                $report += "</li>`n"
            }
            
            $report += "</ul>`n"
            
            $report += "<h3>Sous-tâches ($($mapping.Subtasks.Count))</h3>`n"
            $report += "<ul>`n"
            
            foreach ($subtask in $mapping.Subtasks) {
                $report += "<li>$($subtask.Name) ($($subtask.Path))`n"
                $report += "<ul>`n"
                $report += "<li>Titre: $($subtask.Attributes["title"])</li>`n"
                $report += "<li>Terminée: $($subtask.Attributes["completed"])</li>`n"
                $report += "</ul>`n"
                $report += "</li>`n"
            }
            
            $report += "</ul>`n"
            
            $report += "<h3>Notes ($($mapping.Notes.Count))</h3>`n"
            $report += "<ul>`n"
            
            foreach ($note in $mapping.Notes) {
                $report += "<li>$($note.Name) ($($note.Path))`n"
                $report += "<ul>`n"
                $report += "<li>Texte: $($note.Value)</li>`n"
                $report += "</ul>`n"
                $report += "</li>`n"
            }
            
            $report += "</ul>`n"
        }
        else {
            $report += "Mapping XML vers Roadmap`n"
            $report += "======================`n`n"
            
            $report += "Élément racine: $($mapping.RootElement.Name) ($($mapping.RootElement.Path))`n`n"
            
            $report += "Sections ($($mapping.Sections.Count)):`n"
            
            foreach ($section in $mapping.Sections) {
                $report += "  - $($section.Name) ($($section.Path))`n"
                $report += "    ID: $($section.Attributes["id"])`n"
                $report += "    Titre: $($section.Attributes["title"])`n`n"
            }
            
            $report += "Phases ($($mapping.Phases.Count)):`n"
            
            foreach ($phase in $mapping.Phases) {
                $report += "  - $($phase.Name) ($($phase.Path))`n"
                $report += "    ID: $($phase.Attributes["id"])`n"
                $report += "    Titre: $($phase.Attributes["title"])`n"
                $report += "    Terminée: $($phase.Attributes["completed"])`n`n"
            }
            
            $report += "Tâches ($($mapping.Tasks.Count)):`n"
            
            foreach ($task in $mapping.Tasks) {
                $report += "  - $($task.Name) ($($task.Path))`n"
                $report += "    Titre: $($task.Attributes["title"])`n"
                $report += "    Temps estimé: $($task.Attributes["estimatedTime"])`n"
                $report += "    Date de début: $($task.Attributes["startDate"])`n"
                $report += "    Terminée: $($task.Attributes["completed"])`n`n"
            }
            
            $report += "Sous-tâches ($($mapping.Subtasks.Count)):`n"
            
            foreach ($subtask in $mapping.Subtasks) {
                $report += "  - $($subtask.Name) ($($subtask.Path))`n"
                $report += "    Titre: $($subtask.Attributes["title"])`n"
                $report += "    Terminée: $($subtask.Attributes["completed"])`n`n"
            }
            
            $report += "Notes ($($mapping.Notes.Count)):`n"
            
            foreach ($note in $mapping.Notes) {
                $report += "  - $($note.Name) ($($note.Path))`n"
                $report += "    Texte: $($note.Value)`n`n"
            }
        }
    }
    
    # Ajouter le pied de page du rapport
    if ($AsHtml) {
        $report += @"
</body>
</html>
"@
    }
    
    # Enregistrer le rapport si un chemin de sortie est spécifié
    if ($OutputPath) {
        # Déterminer l'encodage en fonction du format
        $encoding = if ($AsHtml) { "UTF8" } else { "ASCII" }
        
        # Enregistrer le rapport
        Set-Content -Path $OutputPath -Value $report -Encoding $encoding
        
        Write-Host "Rapport d'analyse XML généré: $OutputPath" -ForegroundColor Green
        return $OutputPath
    }
    
    return $report
}

# Exporter les fonctions
Export-ModuleMember -Function Show-XmlSupportHelp, Invoke-XmlSupportTests, Convert-FormatFile, Invoke-XmlAnalysis

# Exporter les fonctions des modules importés
Export-ModuleMember -Function ConvertFrom-RoadmapToXml, ConvertFrom-XmlToRoadmap
Export-ModuleMember -Function ConvertFrom-RoadmapFileToXmlFile, ConvertFrom-XmlFileToRoadmapFile
Export-ModuleMember -Function Get-XmlElements, Get-XmlElementsFromFile
Export-ModuleMember -Function Get-XmlStructureReport, Get-XmlStructureReportFromFile
Export-ModuleMember -Function ConvertTo-RoadmapMapping
Export-ModuleMember -Function Test-XmlContent, Test-XmlFile
Export-ModuleMember -Function Get-XmlValidationReport, Test-XmlFileWithReport
Export-ModuleMember -Function Test-XmlFileAgainstSchema, New-XsdSchemaFromXml

# Afficher un message d'accueil
Write-Host "Module de support XML chargé." -ForegroundColor Cyan
Write-Host "Utilisez Show-XmlSupportHelp pour afficher l'aide." -ForegroundColor Cyan
