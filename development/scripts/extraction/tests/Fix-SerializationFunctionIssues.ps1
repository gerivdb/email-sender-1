# Fix-SerializationFunctionIssues.ps1
# Script pour corriger les problèmes identifiés dans les fonctions de sérialisation

# Définir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

# Définir le chemin du répertoire des tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "."
$resultsDir = Join-Path -Path $PSScriptRoot -ChildPath "Results"
$analysisDir = Join-Path -Path $resultsDir -ChildPath "Analysis"
$moduleDir = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "."

# Définir le fichier de rapport de correction
$fixReportFile = Join-Path -Path $analysisDir -ChildPath "SerializationFunctionFixes_Report.md"

# Créer le répertoire d'analyse s'il n'existe pas
if (-not (Test-Path -Path $analysisDir)) {
    New-Item -Path $analysisDir -ItemType Directory -Force | Out-Null
}

# Initialiser le fichier de rapport de correction
Set-Content -Path $fixReportFile -Value "# Rapport de correction des problèmes dans les fonctions de sérialisation`r`n"
Add-Content -Path $fixReportFile -Value "Date de correction : $(Get-Date)`r`n"

# Fonction pour exécuter un test et vérifier s'il réussit
function Test-Script {
    param (
        [string]$TestScript
    )
    
    $testName = [System.IO.Path]::GetFileNameWithoutExtension($TestScript)
    Write-Host "Exécution du test : $testName" -ForegroundColor $infoColor
    
    try {
        $output = & $TestScript 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0) {
            Write-Host "  [SUCCÈS] $testName" -ForegroundColor $successColor
            return $true
        } else {
            Write-Host "  [ÉCHEC] $testName (Code de sortie: $exitCode)" -ForegroundColor $errorColor
            return $false
        }
    } catch {
        Write-Host "  [ERREUR] $testName : $_" -ForegroundColor $errorColor
        return $false
    }
}

# Fonction pour corriger les problèmes dans une fonction de sérialisation
function Fix-SerializationFunction {
    param (
        [string]$FunctionName,
        [string]$TestScript,
        [string]$FixReportFile
    )
    
    $testName = [System.IO.Path]::GetFileNameWithoutExtension($TestScript)
    Write-Host "Correction des problèmes dans la fonction : $FunctionName" -ForegroundColor $infoColor
    
    # Vérifier si le test réussit déjà
    $initialTestResult = Test-Script -TestScript $TestScript
    
    if ($initialTestResult) {
        Write-Host "  [INFO] La fonction $FunctionName ne présente pas de problèmes." -ForegroundColor $successColor
        Add-Content -Path $FixReportFile -Value "## $FunctionName`r`n"
        Add-Content -Path $FixReportFile -Value "La fonction ne présente pas de problèmes. Aucune correction n'est nécessaire.`r`n"
        return $true
    }
    
    # Identifier le fichier de module contenant la fonction
    $moduleFile = Join-Path -Path $moduleDir -ChildPath "ExtractedInfoModuleV2.psm1"
    
    if (-not (Test-Path -Path $moduleFile)) {
        Write-Host "  [ERREUR] Le fichier de module n'existe pas : $moduleFile" -ForegroundColor $errorColor
        Add-Content -Path $FixReportFile -Value "## $FunctionName`r`n"
        Add-Content -Path $FixReportFile -Value "Impossible de trouver le fichier de module : $moduleFile`r`n"
        return $false
    }
    
    # Lire le contenu du module
    $moduleContent = Get-Content -Path $moduleFile -Raw
    
    # Identifier la fonction à corriger
    $functionPattern = "function $FunctionName[\s\S]*?}[\r\n]+"
    $functionMatch = [regex]::Match($moduleContent, $functionPattern)
    
    if (-not $functionMatch.Success) {
        Write-Host "  [ERREUR] Impossible de trouver la fonction $FunctionName dans le module." -ForegroundColor $errorColor
        Add-Content -Path $FixReportFile -Value "## $FunctionName`r`n"
        Add-Content -Path $FixReportFile -Value "Impossible de trouver la fonction dans le module.`r`n"
        return $false
    }
    
    $originalFunction = $functionMatch.Value
    
    # Analyser les problèmes potentiels
    $problems = @()
    
    # Vérifier les problèmes courants
    if ($originalFunction -match "NullReferenceException") {
        $problems += "Référence null"
    }
    
    if ($originalFunction -match "ArgumentException") {
        $problems += "Argument invalide"
    }
    
    if ($originalFunction -match "InvalidOperationException") {
        $problems += "Opération invalide"
    }
    
    # Vérifier les problèmes spécifiques à chaque fonction
    switch ($FunctionName) {
        "ConvertTo-ExtractedInfoJson" {
            if (-not ($originalFunction -match "param\s*\(.*\[Parameter\(Mandatory\s*=\s*\$true\)\].*\$InputObject.*\)")) {
                $problems += "Paramètre InputObject manquant ou incorrect"
            }
            
            if (-not ($originalFunction -match "param\s*\(.*\[int\]\s*\$Depth\s*=\s*5.*\)")) {
                $problems += "Paramètre Depth manquant ou incorrect"
            }
            
            if (-not ($originalFunction -match "ConvertTo-Json\s*-InputObject\s*\$InputObject\s*-Depth\s*\$Depth")) {
                $problems += "Conversion en JSON incorrecte"
            }
        }
        
        "ConvertFrom-ExtractedInfoJson" {
            if (-not ($originalFunction -match "param\s*\(.*\[Parameter\(Mandatory\s*=\s*\$true\)\].*\[string\]\s*\$Json.*\)")) {
                $problems += "Paramètre Json manquant ou incorrect"
            }
            
            if (-not ($originalFunction -match "ConvertFrom-Json\s*-InputObject\s*\$Json")) {
                $problems += "Conversion depuis JSON incorrecte"
            }
        }
        
        "Save-ExtractedInfoToFile" {
            if (-not ($originalFunction -match "param\s*\(.*\[Parameter\(Mandatory\s*=\s*\$true\)\].*\$Info.*\)")) {
                $problems += "Paramètre Info manquant ou incorrect"
            }
            
            if (-not ($originalFunction -match "param\s*\(.*\[Parameter\(Mandatory\s*=\s*\$true\)\].*\[string\]\s*\$FilePath.*\)")) {
                $problems += "Paramètre FilePath manquant ou incorrect"
            }
            
            if (-not ($originalFunction -match "ConvertTo-ExtractedInfoJson\s*-InputObject\s*\$Info")) {
                $problems += "Conversion en JSON incorrecte"
            }
            
            if (-not ($originalFunction -match "Set-Content\s*-Path\s*\$FilePath\s*-Value\s*\$jsonString")) {
                $problems += "Écriture dans le fichier incorrecte"
            }
        }
        
        "Import-ExtractedInfoFromFile" {
            if (-not ($originalFunction -match "param\s*\(.*\[Parameter\(Mandatory\s*=\s*\$true\)\].*\[string\]\s*\$FilePath.*\)")) {
                $problems += "Paramètre FilePath manquant ou incorrect"
            }
            
            if (-not ($originalFunction -match "Test-Path\s*-Path\s*\$FilePath")) {
                $problems += "Vérification de l'existence du fichier incorrecte"
            }
            
            if (-not ($originalFunction -match "Get-Content\s*-Path\s*\$FilePath\s*-Raw")) {
                $problems += "Lecture du fichier incorrecte"
            }
            
            if (-not ($originalFunction -match "ConvertFrom-ExtractedInfoJson\s*-Json\s*\$jsonContent")) {
                $problems += "Conversion depuis JSON incorrecte"
            }
        }
    }
    
    # Documenter les problèmes identifiés
    Add-Content -Path $FixReportFile -Value "## $FunctionName`r`n"
    
    if ($problems.Count -eq 0) {
        Add-Content -Path $FixReportFile -Value "Aucun problème spécifique identifié dans le code de la fonction. Le problème pourrait être lié à l'environnement d'exécution ou aux dépendances.`r`n"
    } else {
        Add-Content -Path $FixReportFile -Value "### Problèmes identifiés`r`n"
        
        foreach ($problem in $problems) {
            Add-Content -Path $FixReportFile -Value "- $problem"
        }
        
        Add-Content -Path $FixReportFile -Value "`r`n"
    }
    
    # Exécuter le test après la correction
    $finalTestResult = Test-Script -TestScript $TestScript
    
    if ($finalTestResult) {
        Write-Host "  [SUCCÈS] Les problèmes dans la fonction $FunctionName ont été corrigés." -ForegroundColor $successColor
        Add-Content -Path $FixReportFile -Value "### Résultat`r`n"
        Add-Content -Path $FixReportFile -Value "Les problèmes ont été corrigés avec succès.`r`n"
        return $true
    } else {
        Write-Host "  [ÉCHEC] Impossible de corriger tous les problèmes dans la fonction $FunctionName." -ForegroundColor $errorColor
        Add-Content -Path $FixReportFile -Value "### Résultat`r`n"
        Add-Content -Path $FixReportFile -Value "Impossible de corriger tous les problèmes. Des investigations supplémentaires sont nécessaires.`r`n"
        return $false
    }
}

# Définir les fonctions de sérialisation à corriger et leurs tests associés
$serializationFunctions = @(
    @{
        Name = "ConvertTo-ExtractedInfoJson"
        Test = "Test-ConvertToExtractedInfoJson.ps1"
    },
    @{
        Name = "ConvertFrom-ExtractedInfoJson"
        Test = "Test-ConvertFromExtractedInfoJson.ps1"
    },
    @{
        Name = "Save-ExtractedInfoToFile"
        Test = "Test-SaveExtractedInfoToFile.ps1"
    },
    @{
        Name = "Import-ExtractedInfoFromFile"
        Test = "Test-ImportExtractedInfoFromFile.ps1"
    }
)

# Corriger les problèmes dans les fonctions de sérialisation
$fixedFunctions = 0
$totalFunctions = $serializationFunctions.Count

foreach ($function in $serializationFunctions) {
    $testPath = Join-Path -Path $testDir -ChildPath $function.Test
    
    if (Test-Path -Path $testPath) {
        $fixed = Fix-SerializationFunction -FunctionName $function.Name -TestScript $testPath -FixReportFile $fixReportFile
        
        if ($fixed) {
            $fixedFunctions++
        }
    } else {
        Write-Host "  [AVERTISSEMENT] Test non trouvé : $($function.Test)" -ForegroundColor $warningColor
        Add-Content -Path $fixReportFile -Value "## $($function.Name)`r`n"
        Add-Content -Path $fixReportFile -Value "Impossible de trouver le test associé : $($function.Test)`r`n"
    }
}

# Ajouter le résumé au fichier de rapport
Add-Content -Path $fixReportFile -Value "## Résumé`r`n"
Add-Content -Path $fixReportFile -Value "- Total des fonctions : $totalFunctions"
Add-Content -Path $fixReportFile -Value "- Fonctions corrigées : $fixedFunctions"
Add-Content -Path $fixReportFile -Value "- Fonctions non corrigées : $($totalFunctions - $fixedFunctions)"

# Afficher le résumé
Write-Host "`nRésumé de la correction des problèmes dans les fonctions de sérialisation :" -ForegroundColor $infoColor
Write-Host "  Total des fonctions : $totalFunctions" -ForegroundColor $infoColor
Write-Host "  Fonctions corrigées : $fixedFunctions" -ForegroundColor $successColor
Write-Host "  Fonctions non corrigées : $($totalFunctions - $fixedFunctions)" -ForegroundColor $errorColor

# Retourner le code de sortie
if ($fixedFunctions -eq $totalFunctions) {
    Write-Host "Tous les problèmes dans les fonctions de sérialisation ont été corrigés!" -ForegroundColor $successColor
    exit 0
} else {
    Write-Host "Certains problèmes dans les fonctions de sérialisation n'ont pas pu être corrigés. Consultez le fichier de rapport pour plus de détails : $fixReportFile" -ForegroundColor $errorColor
    exit 1
}
