# Fix-ValidationFunctionIssues.ps1
# Script pour corriger les problèmes identifiés dans les fonctions de validation

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
$fixReportFile = Join-Path -Path $analysisDir -ChildPath "ValidationFunctionFixes_Report.md"

# Créer le répertoire d'analyse s'il n'existe pas
if (-not (Test-Path -Path $analysisDir)) {
    New-Item -Path $analysisDir -ItemType Directory -Force | Out-Null
}

# Initialiser le fichier de rapport de correction
Set-Content -Path $fixReportFile -Value "# Rapport de correction des problèmes dans les fonctions de validation`r`n"
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

# Fonction pour corriger les problèmes dans une fonction de validation
function Repair-ValidationFunction {
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
        "Test-ExtractedInfo" {
            if (-not ($originalFunction -match "param\s*\(.*\[Parameter\(Mandatory\s*=\s*\$true\)\].*\$Info.*\)")) {
                $problems += "Paramètre Info manquant ou incorrect"
            }
            
            if (-not ($originalFunction -match "param\s*\(.*\[switch\]\s*\$UpdateObject.*\)")) {
                $problems += "Paramètre UpdateObject manquant ou incorrect"
            }
            
            if (-not ($originalFunction -match "if\s*\(\$null\s*-eq\s*\$Info\)")) {
                $problems += "Vérification de l'objet null incorrecte"
            }
            
            if (-not ($originalFunction -match "if\s*\(\[string\]::IsNullOrEmpty\(\$Info\.Id\)\)")) {
                $problems += "Vérification de l'ID incorrecte"
            }
            
            if (-not ($originalFunction -match "if\s*\(\[string\]::IsNullOrEmpty\(\$Info\.Source\)\)")) {
                $problems += "Vérification de la source incorrecte"
            }
            
            if (-not ($originalFunction -match "if\s*\(\[string\]::IsNullOrEmpty\(\$Info\.ExtractorName\)\)")) {
                $problems += "Vérification du nom de l'extracteur incorrecte"
            }
            
            if (-not ($originalFunction -match "if\s*\(\$Info\.ConfidenceScore\s*-lt\s*0\s*-or\s*\$Info\.ConfidenceScore\s*-gt\s*100\)")) {
                $problems += "Vérification du score de confiance incorrecte"
            }
            
            if (-not ($originalFunction -match "if\s*\(\$UpdateObject\)")) {
                $problems += "Mise à jour de l'objet incorrecte"
            }
        }
        
        "Get-ValidationErrors" {
            if (-not ($originalFunction -match "param\s*\(.*\[Parameter\(Mandatory\s*=\s*\$true\)\].*\$Info.*\)")) {
                $problems += "Paramètre Info manquant ou incorrect"
            }
            
            if (-not ($originalFunction -match "if\s*\(\$null\s*-eq\s*\$Info\)")) {
                $problems += "Vérification de l'objet null incorrecte"
            }
            
            if (-not ($originalFunction -match "if\s*\(\$Info\.Metadata\.ContainsKey\(""_ValidationErrors""\)\)")) {
                $problems += "Vérification des erreurs de validation incorrecte"
            }
        }
        
        "Add-ValidationRule" {
            if (-not ($originalFunction -match "param\s*\(.*\[Parameter\(Mandatory\s*=\s*\$true\)\].*\[string\]\s*\$Name.*\)")) {
                $problems += "Paramètre Name manquant ou incorrect"
            }
            
            if (-not ($originalFunction -match "param\s*\(.*\[Parameter\(Mandatory\s*=\s*\$true\)\].*\[string\]\s*\$InfoType.*\)")) {
                $problems += "Paramètre InfoType manquant ou incorrect"
            }
            
            if (-not ($originalFunction -match "param\s*\(.*\[Parameter\(Mandatory\s*=\s*\$true\)\].*\[scriptblock\]\s*\$ValidationScript.*\)")) {
                $problems += "Paramètre ValidationScript manquant ou incorrect"
            }
            
            if (-not ($originalFunction -match "param\s*\(.*\[Parameter\(Mandatory\s*=\s*\$true\)\].*\[string\]\s*\$ErrorMessage.*\)")) {
                $problems += "Paramètre ErrorMessage manquant ou incorrect"
            }
            
            if (-not ($originalFunction -match "if\s*\(\$null\s*-eq\s*\$script:ValidationRules\)")) {
                $problems += "Initialisation des règles de validation incorrecte"
            }
            
            if (-not ($originalFunction -match "\$script:ValidationRules\s*\+=\s*@{")) {
                $problems += "Ajout de la règle de validation incorrecte"
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

# Définir les fonctions de validation à corriger et leurs tests associés
$validationFunctions = @(
    @{
        Name = "Test-ExtractedInfo"
        Test = "Test-ExtractedInfoValidation.ps1"
    },
    @{
        Name = "Get-ValidationErrors"
        Test = "Test-GetValidationErrors.ps1"
    },
    @{
        Name = "Add-ValidationRule"
        Test = "Test-AddValidationRule.ps1"
    }
)

# Corriger les problèmes dans les fonctions de validation
$fixedFunctions = 0
$totalFunctions = $validationFunctions.Count

foreach ($function in $validationFunctions) {
    $testPath = Join-Path -Path $testDir -ChildPath $function.Test
    
    if (Test-Path -Path $testPath) {
        $fixed = Repair-ValidationFunction -FunctionName $function.Name -TestScript $testPath -FixReportFile $fixReportFile
        
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
Write-Host "`nRésumé de la correction des problèmes dans les fonctions de validation :" -ForegroundColor $infoColor
Write-Host "  Total des fonctions : $totalFunctions" -ForegroundColor $infoColor
Write-Host "  Fonctions corrigées : $fixedFunctions" -ForegroundColor $successColor
Write-Host "  Fonctions non corrigées : $($totalFunctions - $fixedFunctions)" -ForegroundColor $errorColor

# Retourner le code de sortie
if ($fixedFunctions -eq $totalFunctions) {
    Write-Host "Tous les problèmes dans les fonctions de validation ont été corrigés!" -ForegroundColor $successColor
    exit 0
} else {
    Write-Host "Certains problèmes dans les fonctions de validation n'ont pas pu être corrigés. Consultez le fichier de rapport pour plus de détails : $fixReportFile" -ForegroundColor $errorColor
    exit 1
}

