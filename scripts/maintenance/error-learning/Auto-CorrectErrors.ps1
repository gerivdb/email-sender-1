<#
.SYNOPSIS
    Script pour automatiser intelligemment les corrections d'erreurs PowerShell.
.DESCRIPTION
    Ce script utilise la base de connaissances des erreurs pour suggérer et appliquer
    automatiquement des corrections aux scripts PowerShell problématiques.
.PARAMETER ScriptPath
    Chemin du script à analyser et corriger.
.PARAMETER ApplyCorrections
    Si spécifié, applique automatiquement les corrections suggérées.
.PARAMETER GenerateReport
    Si spécifié, génère un rapport détaillé des corrections suggérées.
.PARAMETER ReportPath
    Chemin où enregistrer le rapport. Par défaut, utilise le même répertoire que le script.
.PARAMETER LearningMode
    Si spécifié, active le mode d'apprentissage qui enregistre les corrections manuelles.
.EXAMPLE
    .\Auto-CorrectErrors.ps1 -ScriptPath "C:\Scripts\MonScript.ps1" -GenerateReport
    Analyse le script et génère un rapport des corrections suggérées.
.EXAMPLE
    .\Auto-CorrectErrors.ps1 -ScriptPath "C:\Scripts\MonScript.ps1" -ApplyCorrections
    Analyse le script et applique automatiquement les corrections suggérées.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ScriptPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$ApplyCorrections,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,
    
    [Parameter(Mandatory = $false)]
    [string]$ReportPath = "",
    
    [Parameter(Mandatory = $false)]
    [switch]$LearningMode
)

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ErrorLearningSystem.psm1"
Import-Module $modulePath -Force

# Initialiser le système
Initialize-ErrorLearningSystem

# Vérifier si le script existe
if (-not (Test-Path -Path $ScriptPath)) {
    Write-Error "Le script spécifié n'existe pas : $ScriptPath"
    exit 1
}

# Lire le contenu du script
$scriptContent = Get-Content -Path $ScriptPath -Raw
$scriptLines = Get-Content -Path $ScriptPath

# Fonction pour extraire les erreurs d'un script
function Get-ScriptErrors {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptContent,
        
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )
    
    $errors = @()
    
    # Analyser le script avec l'analyseur de syntaxe PowerShell
    try {
        $null = [System.Management.Automation.PSParser]::Tokenize($ScriptContent, [ref]$null)
    }
    catch {
        # Erreur de syntaxe détectée
        $errors += @{
            Type = "SyntaxError"
            Message = $_.Exception.Message
            Line = $_.InvocationInfo.ScriptLineNumber
            Position = $_.InvocationInfo.OffsetInLine
            Severity = "Error"
        }
    }
    
    # Analyser le script avec l'analyseur de script PowerShell
    try {
        $scriptBlock = [ScriptBlock]::Create($ScriptContent)
        $null = $scriptBlock.CheckRestrictedLanguage($null, $null, $true)
    }
    catch {
        # Erreur de langage restreint détectée
        if (-not ($errors | Where-Object { $_.Message -eq $_.Exception.Message })) {
            $errors += @{
                Type = "LanguageError"
                Message = $_.Exception.Message
                Line = $_.InvocationInfo.ScriptLineNumber
                Position = $_.InvocationInfo.OffsetInLine
                Severity = "Error"
            }
        }
    }
    
    # Utiliser PSScriptAnalyzer si disponible
    if (Get-Module -Name PSScriptAnalyzer -ListAvailable) {
        Import-Module PSScriptAnalyzer -Force
        $psaResults = Invoke-ScriptAnalyzer -Path $ScriptPath -Severity Error, Warning
        
        foreach ($result in $psaResults) {
            $errors += @{
                Type = $result.RuleName
                Message = $result.Message
                Line = $result.Line
                Position = $result.Column
                Severity = $result.Severity
            }
        }
    }
    else {
        Write-Warning "PSScriptAnalyzer n'est pas installé. Certaines erreurs pourraient ne pas être détectées."
    }
    
    # Analyser le script avec des patterns connus
    $errorPatterns = @(
        @{
            Name = "Chemin codé en dur"
            Pattern = '(?<!\\)["''](?:[A-Z]:\\|\\\\)[^"'']*["'']'
            Type = "HardcodedPath"
            Severity = "Warning"
        },
        @{
            Name = "Variable non déclarée"
            Pattern = '\$[a-zA-Z0-9_]+\s*='
            Type = "UndeclaredVariable"
            Severity = "Warning"
        },
        @{
            Name = "Absence de gestion d'erreurs"
            Pattern = '(?<!try\s*\{\s*)(?:Invoke-RestMethod|Invoke-WebRequest|New-Item|Remove-Item|Copy-Item|Move-Item|Get-Content|Set-Content)(?!\s*-ErrorAction)'
            Type = "NoErrorHandling"
            Severity = "Warning"
        },
        @{
            Name = "Utilisation de Write-Host"
            Pattern = 'Write-Host'
            Type = "WriteHostUsage"
            Severity = "Information"
        },
        @{
            Name = "Utilisation de cmdlets obsolètes"
            Pattern = '(Get-WmiObject|Invoke-Expression)'
            Type = "ObsoleteCmdlet"
            Severity = "Warning"
        }
    )
    
    foreach ($pattern in $errorPatterns) {
        $matches = [regex]::Matches($ScriptContent, $pattern.Pattern)
        
        foreach ($match in $matches) {
            # Trouver le numéro de ligne
            $lineNumber = ($ScriptContent.Substring(0, $match.Index).Split("`n")).Length
            
            # Extraire la ligne complète
            $line = $scriptLines[$lineNumber - 1].Trim()
            
            # Créer un objet pour l'erreur détectée
            $error = @{
                Type = $pattern.Type
                Message = "$($pattern.Name) détecté : $($match.Value)"
                Line = $lineNumber
                Position = $match.Index - $ScriptContent.Substring(0, $match.Index).LastIndexOf("`n") - 1
                Severity = $pattern.Severity
                Match = $match.Value
                FullLine = $line
            }
            
            $errors += $error
        }
    }
    
    return $errors
}

# Fonction pour obtenir des suggestions de correction
function Get-CorrectionSuggestions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Error
    )
    
    # Rechercher des erreurs similaires dans la base de données
    $errorType = $Error.Type
    $errorMessage = $Error.Message
    
    # Créer un ErrorRecord factice pour la recherche
    $exception = New-Object System.Exception($errorMessage)
    $errorRecord = New-Object System.Management.Automation.ErrorRecord(
        $exception,
        $errorType,
        [System.Management.Automation.ErrorCategory]::NotSpecified,
        $null
    )
    
    # Obtenir des suggestions
    $suggestions = Get-ErrorSuggestions -ErrorRecord $errorRecord
    
    # Si aucune suggestion n'est trouvée, utiliser des corrections prédéfinies
    if (-not $suggestions.Found) {
        $predefinedCorrections = @{
            "SyntaxError" = @{
                Description = "Erreur de syntaxe"
                Corrections = @(
                    @{
                        Pattern = 'if\s*\(\s*(.+)\s*\)\s*\{'
                        MissingClosingBrace = $true
                        Correction = 'if ($1) {'
                    },
                    @{
                        Pattern = 'foreach\s*\(\s*(.+)\s*\)\s*\{'
                        MissingClosingBrace = $true
                        Correction = 'foreach ($1) {'
                    }
                )
            }
            "HardcodedPath" = @{
                Description = "Chemin codé en dur"
                Corrections = @(
                    @{
                        Pattern = '["'']([A-Z]:\\[^"'']+)["'']'
                        Correction = '(Join-Path -Path $PSScriptRoot -ChildPath "CHEMIN_RELATIF")'
                    }
                )
            }
            "UndeclaredVariable" = @{
                Description = "Variable non déclarée"
                Corrections = @(
                    @{
                        Pattern = '\$([a-zA-Z0-9_]+)\s*='
                        Correction = '[string]$$1 ='
                    }
                )
            }
            "NoErrorHandling" = @{
                Description = "Absence de gestion d'erreurs"
                Corrections = @(
                    @{
                        Pattern = '(Invoke-RestMethod|Invoke-WebRequest|New-Item|Remove-Item|Copy-Item|Move-Item|Get-Content|Set-Content)(?!\s*-ErrorAction)'
                        Correction = '$1 -ErrorAction Stop'
                    }
                )
            }
            "WriteHostUsage" = @{
                Description = "Utilisation de Write-Host"
                Corrections = @(
                    @{
                        Pattern = 'Write-Host\s+(.+)'
                        Correction = 'Write-Output $1'
                    }
                )
            }
            "ObsoleteCmdlet" = @{
                Description = "Utilisation de cmdlets obsolètes"
                Corrections = @(
                    @{
                        Pattern = 'Get-WmiObject'
                        Correction = 'Get-CimInstance'
                    },
                    @{
                        Pattern = 'Invoke-Expression'
                        Correction = '# Éviter Invoke-Expression si possible'
                    }
                )
            }
        }
        
        # Rechercher des corrections prédéfinies pour ce type d'erreur
        if ($predefinedCorrections.ContainsKey($errorType)) {
            $corrections = $predefinedCorrections[$errorType].Corrections
            
            $result = @{
                Found = $true
                Message = "Corrections prédéfinies trouvées pour cette erreur."
                Suggestions = @()
            }
            
            foreach ($correction in $corrections) {
                $result.Suggestions += @{
                    Solution = "Remplacer $($correction.Pattern) par $($correction.Correction)"
                    Pattern = $correction.Pattern
                    Correction = $correction.Correction
                    MissingClosingBrace = $correction.MissingClosingBrace
                }
            }
            
            return $result
        }
        
        return $suggestions
    }
    
    return $suggestions
}

# Fonction pour appliquer les corrections
function Apply-Corrections {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $true)]
        [array]$Errors,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Suggestions
    )
    
    # Lire le contenu du script
    $scriptContent = Get-Content -Path $ScriptPath -Raw
    $scriptLines = Get-Content -Path $ScriptPath
    
    # Créer une sauvegarde du script
    $backupPath = "$ScriptPath.bak"
    Copy-Item -Path $ScriptPath -Destination $backupPath -Force
    
    # Trier les erreurs par numéro de ligne (décroissant) pour éviter les décalages
    $sortedErrors = $Errors | Sort-Object -Property Line -Descending
    
    # Appliquer les corrections
    $correctionsMade = 0
    
    foreach ($error in $sortedErrors) {
        $lineIndex = $error.Line - 1
        $originalLine = $scriptLines[$lineIndex]
        
        # Rechercher des suggestions pour cette erreur
        $errorSuggestions = Get-CorrectionSuggestions -Error $error
        
        if ($errorSuggestions.Found) {
            $corrected = $false
            
            foreach ($suggestion in $errorSuggestions.Suggestions) {
                if ($suggestion.Pattern -and $suggestion.Correction) {
                    # Appliquer la correction
                    $newLine = $originalLine -replace $suggestion.Pattern, $suggestion.Correction
                    
                    # Vérifier si la ligne a été modifiée
                    if ($newLine -ne $originalLine) {
                        $scriptLines[$lineIndex] = $newLine
                        $corrected = $true
                        $correctionsMade++
                        
                        Write-Verbose "Ligne $($error.Line) corrigée : $($error.Type)"
                        Write-Verbose "  Avant : $originalLine"
                        Write-Verbose "  Après : $newLine"
                        
                        # Vérifier s'il manque une accolade fermante
                        if ($suggestion.MissingClosingBrace) {
                            # Rechercher la dernière ligne du bloc
                            $braceCount = 0
                            $currentLine = $lineIndex
                            
                            while ($currentLine -lt $scriptLines.Count) {
                                $line = $scriptLines[$currentLine]
                                
                                $openBraces = ($line | Select-String -Pattern "{" -AllMatches).Matches.Count
                                $closeBraces = ($line | Select-String -Pattern "}" -AllMatches).Matches.Count
                                
                                $braceCount += $openBraces - $closeBraces
                                
                                if ($braceCount -eq 0) {
                                    break
                                }
                                
                                $currentLine++
                            }
                            
                            if ($braceCount -gt 0) {
                                # Ajouter une accolade fermante à la fin du bloc
                                $scriptLines += "}"
                                Write-Verbose "Accolade fermante ajoutée à la fin du script."
                                $correctionsMade++
                            }
                        }
                        
                        break
                    }
                }
            }
            
            if (-not $corrected) {
                Write-Warning "Impossible d'appliquer une correction pour l'erreur à la ligne $($error.Line) : $($error.Message)"
            }
        }
        else {
            Write-Warning "Aucune suggestion trouvée pour l'erreur à la ligne $($error.Line) : $($error.Message)"
        }
    }
    
    # Enregistrer le script corrigé
    $scriptLines | Out-File -FilePath $ScriptPath -Encoding utf8
    
    return @{
        CorrectionsMade = $correctionsMade
        BackupPath = $backupPath
    }
}

# Fonction pour générer un rapport
function Generate-CorrectionReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $true)]
        [array]$Errors,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$CorrectionResults,
        
        [Parameter(Mandatory = $false)]
        [string]$ReportPath = ""
    )
    
    if (-not $ReportPath) {
        $ReportPath = [System.IO.Path]::ChangeExtension($ScriptPath, "corrections.md")
    }
    
    $reportContent = @"
# Rapport de corrections automatiques
- **Script** : $ScriptPath
- **Date d'analyse** : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **Erreurs détectées** : $($Errors.Count)
- **Corrections appliquées** : $($CorrectionResults.CorrectionsMade)
- **Sauvegarde créée** : $($CorrectionResults.BackupPath)

## Détails des erreurs et corrections

"@

    foreach ($error in $Errors) {
        $errorSuggestions = Get-CorrectionSuggestions -Error $error
        
        $reportContent += @"

### [$($error.Severity)] $($error.Type) (Ligne $($error.Line))
- **Message** : $($error.Message)
- **Ligne** : ``$($error.FullLine)``

"@

        if ($errorSuggestions.Found) {
            $reportContent += "#### Suggestions de correction :`n"
            
            foreach ($suggestion in $errorSuggestions.Suggestions) {
                $reportContent += "- $($suggestion.Solution)`n"
            }
        }
        else {
            $reportContent += "#### Aucune suggestion de correction trouvée.`n"
        }
    }
    
    $reportContent | Out-File -FilePath $ReportPath -Encoding utf8
    
    return $ReportPath
}

# Fonction pour enregistrer les corrections manuelles
function Register-ManualCorrection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Error,
        
        [Parameter(Mandatory = $true)]
        [string]$OriginalCode,
        
        [Parameter(Mandatory = $true)]
        [string]$CorrectedCode
    )
    
    # Créer un ErrorRecord factice pour l'enregistrement
    $exception = New-Object System.Exception($Error.Message)
    $errorRecord = New-Object System.Management.Automation.ErrorRecord(
        $exception,
        $Error.Type,
        [System.Management.Automation.ErrorCategory]::NotSpecified,
        $null
    )
    
    # Enregistrer l'erreur avec la solution
    $solution = "Remplacer `"$OriginalCode`" par `"$CorrectedCode`""
    
    Register-PowerShellError -ErrorRecord $errorRecord -Source "ManualCorrection" -Category $Error.Type -Solution $solution
    
    Write-Verbose "Correction manuelle enregistrée pour l'erreur de type $($Error.Type)"
}

# Analyser le script pour détecter les erreurs
Write-Host "Analyse du script : $ScriptPath" -ForegroundColor Cyan
$errors = Get-ScriptErrors -ScriptContent $scriptContent -ScriptPath $ScriptPath

Write-Host "Erreurs détectées : $($errors.Count)" -ForegroundColor Yellow

if ($errors.Count -eq 0) {
    Write-Host "Aucune erreur détectée dans le script." -ForegroundColor Green
    exit 0
}

# Afficher les erreurs détectées
foreach ($error in $errors) {
    Write-Host "`n[$($error.Severity)] $($error.Type) (Ligne $($error.Line))" -ForegroundColor $(
        switch ($error.Severity) {
            "Error" { "Red" }
            "Warning" { "Yellow" }
            default { "White" }
        }
    )
    Write-Host "  Message : $($error.Message)"
    Write-Host "  Ligne : $($error.FullLine)"
    
    # Obtenir des suggestions de correction
    $suggestions = Get-CorrectionSuggestions -Error $error
    
    if ($suggestions.Found) {
        Write-Host "  Suggestions de correction :" -ForegroundColor Cyan
        
        foreach ($suggestion in $suggestions.Suggestions) {
            Write-Host "    - $($suggestion.Solution)" -ForegroundColor Green
        }
    }
    else {
        Write-Host "  Aucune suggestion de correction trouvée." -ForegroundColor Gray
    }
}

# Appliquer les corrections si demandé
if ($ApplyCorrections) {
    Write-Host "`nApplication des corrections..." -ForegroundColor Cyan
    
    $correctionResults = Apply-Corrections -ScriptPath $ScriptPath -Errors $errors -Suggestions $suggestions
    
    Write-Host "Corrections appliquées : $($correctionResults.CorrectionsMade)" -ForegroundColor Green
    Write-Host "Sauvegarde créée : $($correctionResults.BackupPath)" -ForegroundColor Yellow
}
elseif ($LearningMode) {
    Write-Host "`nMode d'apprentissage activé." -ForegroundColor Cyan
    Write-Host "Veuillez corriger manuellement le script, puis appuyez sur Entrée pour enregistrer les corrections."
    
    # Attendre que l'utilisateur corrige le script
    $null = Read-Host "Appuyez sur Entrée lorsque vous avez terminé"
    
    # Lire le contenu du script corrigé
    $correctedContent = Get-Content -Path $ScriptPath -Raw
    $correctedLines = Get-Content -Path $ScriptPath
    
    # Comparer les lignes originales et corrigées
    for ($i = 0; $i -lt [Math]::Min($scriptLines.Count, $correctedLines.Count); $i++) {
        $originalLine = $scriptLines[$i]
        $correctedLine = $correctedLines[$i]
        
        if ($originalLine -ne $correctedLine) {
            # Trouver l'erreur correspondant à cette ligne
            $lineNumber = $i + 1
            $error = $errors | Where-Object { $_.Line -eq $lineNumber } | Select-Object -First 1
            
            if ($error) {
                # Enregistrer la correction manuelle
                Register-ManualCorrection -Error $error -OriginalCode $originalLine -CorrectedCode $correctedLine
                
                Write-Host "Correction manuelle enregistrée pour la ligne $lineNumber" -ForegroundColor Green
            }
        }
    }
    
    Write-Host "Corrections manuelles enregistrées." -ForegroundColor Green
}

# Générer un rapport si demandé
if ($GenerateReport) {
    Write-Host "`nGénération du rapport..." -ForegroundColor Cyan
    
    $correctionResults = if ($ApplyCorrections) {
        $correctionResults
    }
    else {
        @{
            CorrectionsMade = 0
            BackupPath = ""
        }
    }
    
    $reportPath = Generate-CorrectionReport -ScriptPath $ScriptPath -Errors $errors -CorrectionResults $correctionResults -ReportPath $ReportPath
    
    Write-Host "Rapport généré : $reportPath" -ForegroundColor Green
}

Write-Host "`nAnalyse terminée." -ForegroundColor Cyan
