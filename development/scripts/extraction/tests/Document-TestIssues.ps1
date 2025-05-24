# Document-TestIssues.ps1
# Script pour documenter les problèmes identifiés dans les tests

# Définir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

# Définir le chemin du répertoire des résultats
$resultsDir = Join-Path -Path $PSScriptRoot -ChildPath "Results"
$analysisDir = Join-Path -Path $resultsDir -ChildPath "Analysis"
$docsDir = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Docs"

# Créer les répertoires s'ils n'existent pas
if (-not (Test-Path -Path $analysisDir)) {
    New-Item -Path $analysisDir -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path $docsDir)) {
    New-Item -Path $docsDir -ItemType Directory -Force | Out-Null
}

# Définir le fichier de documentation des problèmes
$issuesFile = Join-Path -Path $docsDir -ChildPath "TestIssues.md"

# Initialiser le fichier de documentation des problèmes
Set-Content -Path $issuesFile -Value "# Problèmes identifiés dans les tests`r`n"
Add-Content -Path $issuesFile -Value "Date de documentation : $(Get-Date)`r`n"
Add-Content -Path $issuesFile -Value "Ce document recense les problèmes identifiés lors de l'exécution des tests unitaires et d'intégration du module ExtractedInfoModuleV2.`r`n"

# Fonction pour extraire les détails des problèmes d'un fichier de résultats
function Export-TestIssueDetails {
    param (
        [string]$ResultsFile
    )
    
    if (-not (Test-Path -Path $ResultsFile)) {
        Write-Host "Le fichier de résultats n'existe pas : $ResultsFile" -ForegroundColor $errorColor
        return @()
    }
    
    $content = Get-Content -Path $ResultsFile -Raw
    if ([string]::IsNullOrEmpty($content)) {
        Write-Host "Le fichier de résultats est vide : $ResultsFile" -ForegroundColor $warningColor
        return @()
    }
    
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($ResultsFile)
    
    # Extraire les tests en échec avec leurs détails
    $failedTestsDetails = @()
    
    $failedMatches = [regex]::Matches($content, "\[(.+?)\] ÉCHEC[\r\n]+(Output:[\r\n]+)?([\s\S]+?)(?=\[|$)")
    foreach ($match in $failedMatches) {
        $testName = $match.Groups[1].Value
        $output = $match.Groups[3].Value.Trim()
        
        $failedTestsDetails += @{
            Name = $testName
            Type = "Échec"
            File = $fileName
            Output = $output
        }
    }
    
    # Extraire les tests en erreur avec leurs détails
    $errorMatches = [regex]::Matches($content, "\[(.+?)\] ERREUR : (.+?)(?=\[|$)")
    foreach ($match in $errorMatches) {
        $testName = $match.Groups[1].Value
        $errorMessage = $match.Groups[2].Value.Trim()
        
        $failedTestsDetails += @{
            Name = $testName
            Type = "Erreur"
            File = $fileName
            Output = $errorMessage
        }
    }
    
    return $failedTestsDetails
}

# Fonction pour analyser les problèmes et suggérer des solutions
function Test-TestIssue {
    param (
        [hashtable]$Issue
    )
    
    $suggestion = ""
    
    # Analyser le problème en fonction du type et du message d'erreur
    if ($Issue.Type -eq "Échec") {
        if ($Issue.Output -match "Expected: .+, Actual: .+") {
            $suggestion = "Vérifier les valeurs attendues et réelles dans le test."
        } elseif ($Issue.Output -match "NullReferenceException") {
            $suggestion = "Vérifier que tous les objets sont correctement initialisés avant d'être utilisés."
        } elseif ($Issue.Output -match "ArgumentException") {
            $suggestion = "Vérifier les arguments passés aux fonctions."
        } elseif ($Issue.Output -match "InvalidOperationException") {
            $suggestion = "Vérifier l'état des objets avant d'effectuer des opérations."
        } else {
            $suggestion = "Examiner le message d'erreur pour identifier la cause du problème."
        }
    } elseif ($Issue.Type -eq "Erreur") {
        if ($Issue.Output -match "Could not find file") {
            $suggestion = "Vérifier que le fichier existe et est accessible."
        } elseif ($Issue.Output -match "Access denied") {
            $suggestion = "Vérifier les permissions d'accès au fichier ou au répertoire."
        } elseif ($Issue.Output -match "The term '.+' is not recognized") {
            $suggestion = "Vérifier que la commande ou la fonction est disponible et correctement importée."
        } else {
            $suggestion = "Examiner le message d'erreur pour identifier la cause du problème."
        }
    }
    
    return $suggestion
}

# Trouver tous les fichiers de résultats
$allResultsFiles = @(
    "BaseFunctionTests_Results.txt",
    "MetadataFunctionTests_Results.txt",
    "CollectionFunctionTests_Results.txt",
    "SerializationFunctionTests_Results.txt",
    "ValidationFunctionTests_Results.txt",
    "ExtractionWorkflowTests_Results.txt",
    "CollectionWorkflowTests_Results.txt",
    "SerializationWorkflowTests_Results.txt",
    "ValidationWorkflowTests_Results.txt"
)

# Extraire les détails des problèmes
$allIssueDetails = @()

foreach ($resultsFile in $allResultsFiles) {
    $resultsFilePath = Join-Path -Path $resultsDir -ChildPath $resultsFile
    $issueDetails = Export-TestIssueDetails -ResultsFile $resultsFilePath
    $allIssueDetails += $issueDetails
}

# Ajouter les détails des problèmes au fichier de documentation
if ($allIssueDetails.Count -eq 0) {
    Add-Content -Path $issuesFile -Value "## Aucun problème identifié`r`n"
    Add-Content -Path $issuesFile -Value "Tous les tests ont réussi!`r`n"
} else {
    Add-Content -Path $issuesFile -Value "## Problèmes identifiés`r`n"
    
    # Regrouper par fichier
    $issuesByFile = $allIssueDetails | Group-Object -Property File
    
    foreach ($file in $issuesByFile) {
        Add-Content -Path $issuesFile -Value "### $($file.Name)`r`n"
        
        # Regrouper par type
        $issuesByType = $file.Group | Group-Object -Property Type
        
        foreach ($type in $issuesByType) {
            Add-Content -Path $issuesFile -Value "#### $($type.Name)`r`n"
            
            foreach ($issue in $type.Group) {
                Add-Content -Path $issuesFile -Value "##### $($issue.Name)`r`n"
                Add-Content -Path $issuesFile -Value "**Message d'erreur :**`r`n"
                Add-Content -Path $issuesFile -Value "```"
                Add-Content -Path $issuesFile -Value $issue.Output
                Add-Content -Path $issuesFile -Value "```"
                
                # Analyser le problème et suggérer une solution
                $suggestion = Test-TestIssue -Issue $issue
                
                if (-not [string]::IsNullOrEmpty($suggestion)) {
                    Add-Content -Path $issuesFile -Value "`r`n**Suggestion :**`r`n"
                    Add-Content -Path $issuesFile -Value $suggestion
                }
                
                Add-Content -Path $issuesFile -Value "`r`n---`r`n"
            }
        }
    }
}

# Ajouter des recommandations générales
Add-Content -Path $issuesFile -Value "## Recommandations générales`r`n"
Add-Content -Path $issuesFile -Value "1. **Vérifier les dépendances** : Assurez-vous que toutes les dépendances du module sont correctement installées et accessibles."
Add-Content -Path $issuesFile -Value "2. **Vérifier les chemins** : Assurez-vous que tous les chemins de fichiers et de répertoires sont corrects et accessibles."
Add-Content -Path $issuesFile -Value "3. **Vérifier les permissions** : Assurez-vous que les permissions d'accès aux fichiers et répertoires sont correctes."
Add-Content -Path $issuesFile -Value "4. **Vérifier les valeurs attendues** : Assurez-vous que les valeurs attendues dans les tests correspondent aux valeurs réelles."
Add-Content -Path $issuesFile -Value "5. **Vérifier les initialisations** : Assurez-vous que tous les objets sont correctement initialisés avant d'être utilisés."
Add-Content -Path $issuesFile -Value "6. **Vérifier les arguments** : Assurez-vous que les arguments passés aux fonctions sont corrects."
Add-Content -Path $issuesFile -Value "7. **Vérifier les états** : Assurez-vous que les objets sont dans un état valide avant d'effectuer des opérations."

# Ajouter le résumé
Add-Content -Path $issuesFile -Value "`r`n## Résumé`r`n"
Add-Content -Path $issuesFile -Value "- Total des problèmes identifiés : $($allIssueDetails.Count)"

$issuesByType = $allIssueDetails | Group-Object -Property Type
foreach ($type in $issuesByType) {
    Add-Content -Path $issuesFile -Value "- Problèmes de type $($type.Name) : $($type.Count)"
}

# Afficher le résumé
Write-Host "`nRésumé des problèmes identifiés :" -ForegroundColor $infoColor
Write-Host "  Total des problèmes identifiés : $($allIssueDetails.Count)" -ForegroundColor $infoColor

$issuesByType = $allIssueDetails | Group-Object -Property Type
foreach ($type in $issuesByType) {
    $color = switch ($type.Name) {
        "Échec" { $errorColor }
        "Erreur" { $errorColor }
        default { $infoColor }
    }
    
    Write-Host "  Problèmes de type $($type.Name) : $($type.Count)" -ForegroundColor $color
}

if ($allIssueDetails.Count -eq 0) {
    Write-Host "`nAucun problème identifié. Tous les tests ont réussi!" -ForegroundColor $successColor
    exit 0
} else {
    Write-Host "`nDes problèmes ont été identifiés. Consultez le fichier de documentation pour plus de détails : $issuesFile" -ForegroundColor $warningColor
    exit 1
}

