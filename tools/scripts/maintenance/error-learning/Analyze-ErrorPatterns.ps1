#Requires -Version 5.1
<#
.SYNOPSIS
    Analyse les patterns d'erreurs inédits dans les scripts PowerShell.
.DESCRIPTION
    Ce script analyse les erreurs PowerShell pour identifier des patterns inédits,
    les classifier et les corréler pour améliorer la détection et la prévention des erreurs.
.PARAMETER LogPath
    Chemin vers le fichier de log d'erreurs à analyser.
.PARAMETER OutputPath
    Chemin où enregistrer le rapport d'analyse.
.PARAMETER IncludeExamples
    Inclure des exemples d'erreurs dans le rapport.
.PARAMETER OnlyInedited
    Ne montrer que les patterns d'erreurs inédits.
.EXAMPLE
    .\Analyze-ErrorPatterns.ps1 -LogPath "C:\Logs\errors.log" -OutputPath "C:\Reports\error_analysis.md"
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Date: 2025-04-15
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$LogPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "error_pattern_report.md"),
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeExamples,
    
    [Parameter(Mandatory = $false)]
    [switch]$OnlyInedited,
    
    [Parameter(Mandatory = $false)]
    [switch]$Interactive
)

# Importer le module d'analyse des patterns d'erreur
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ErrorPatternAnalyzer.psm1"

if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module ErrorPatternAnalyzer non trouvé: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Fonction pour analyser les erreurs à partir d'un fichier de log
function Analyze-ErrorLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogPath
    )
    
    if (-not (Test-Path -Path $LogPath)) {
        Write-Error "Fichier de log non trouvé: $LogPath"
        return
    }
    
    Write-Host "Analyse du fichier de log: $LogPath" -ForegroundColor Cyan
    
    # Lire le fichier de log
    $logContent = Get-Content -Path $LogPath -Raw
    
    # Extraire les erreurs du log
    $errorPattern = '(?ms)Exception\s*:\s*([^\r\n]+).*?at\s+([^\r\n]+)'
    $matches = [regex]::Matches($logContent, $errorPattern)
    
    Write-Host "Nombre d'erreurs trouvées: $($matches.Count)" -ForegroundColor Yellow
    
    # Analyser chaque erreur
    foreach ($match in $matches) {
        $exceptionMessage = $match.Groups[1].Value.Trim()
        $stackTrace = $match.Groups[2].Value.Trim()
        
        # Créer un objet ErrorRecord
        $exception = New-Object System.Exception $exceptionMessage
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            $exception,
            "LogFileError",
            [System.Management.Automation.ErrorCategory]::NotSpecified,
            $null
        )
        
        # Ajouter des informations supplémentaires
        $errorRecord.PSObject.Properties.Add(
            (New-Object System.Management.Automation.PSNoteProperty "ScriptStackTrace", $stackTrace)
        )
        
        # Ajouter l'erreur à la base de données
        $patternId = Add-ErrorRecord -ErrorRecord $errorRecord -Source $LogPath
        
        Write-Host "Erreur analysée: $exceptionMessage (Pattern: $patternId)" -ForegroundColor Green
    }
}

# Fonction pour analyser les erreurs à partir de la variable $Error
function Analyze-ErrorVariable {
    [CmdletBinding()]
    param ()
    
    Write-Host "Analyse de la variable `$Error" -ForegroundColor Cyan
    
    # Analyser chaque erreur
    for ($i = 0; $i -lt $Error.Count; $i++) {
        $errorRecord = $Error[$i]
        
        # Ajouter l'erreur à la base de données
        $patternId = Add-ErrorRecord -ErrorRecord $errorRecord -Source "ErrorVariable"
        
        Write-Host "Erreur analysée: $($errorRecord.Exception.Message) (Pattern: $patternId)" -ForegroundColor Green
    }
}

# Fonction pour afficher un menu interactif
function Show-InteractiveMenu {
    [CmdletBinding()]
    param ()
    
    $continue = $true
    
    while ($continue) {
        Clear-Host
        Write-Host "=== Analyse des patterns d'erreurs inédits ===" -ForegroundColor Cyan
        Write-Host "1. Analyser un fichier de log"
        Write-Host "2. Analyser la variable `$Error"
        Write-Host "3. Afficher les patterns d'erreur"
        Write-Host "4. Valider un pattern d'erreur"
        Write-Host "5. Générer un rapport d'analyse"
        Write-Host "6. Quitter"
        Write-Host ""
        
        $choice = Read-Host "Choisissez une option (1-6)"
        
        switch ($choice) {
            "1" {
                $logPath = Read-Host "Entrez le chemin du fichier de log"
                if (Test-Path -Path $logPath) {
                    Analyze-ErrorLog -LogPath $logPath
                }
                else {
                    Write-Warning "Fichier non trouvé: $logPath"
                }
                
                Read-Host "Appuyez sur Entrée pour continuer"
            }
            "2" {
                Analyze-ErrorVariable
                Read-Host "Appuyez sur Entrée pour continuer"
            }
            "3" {
                $patterns = Get-ErrorPattern -IncludeExamples
                
                if ($patterns.Count -eq 0) {
                    Write-Host "Aucun pattern d'erreur trouvé." -ForegroundColor Yellow
                }
                else {
                    foreach ($pattern in $patterns) {
                        Write-Host "=== $($pattern.Name) ===" -ForegroundColor Cyan
                        Write-Host "ID: $($pattern.Id)"
                        Write-Host "Description: $($pattern.Description)"
                        Write-Host "Occurrences: $($pattern.Occurrences)"
                        Write-Host "Inédit: $($pattern.IsInedited)"
                        Write-Host "Statut de validation: $($pattern.ValidationStatus)"
                        Write-Host ""
                        
                        if ($pattern.Examples.Count -gt 0) {
                            Write-Host "Exemple de message d'erreur:" -ForegroundColor Yellow
                            Write-Host $pattern.Examples[0].Message
                            Write-Host ""
                        }
                    }
                }
                
                Read-Host "Appuyez sur Entrée pour continuer"
            }
            "4" {
                $patternId = Read-Host "Entrez l'ID du pattern à valider"
                $pattern = Get-ErrorPattern -PatternId $patternId
                
                if ($pattern) {
                    Write-Host "=== $($pattern.Name) ===" -ForegroundColor Cyan
                    Write-Host "Description: $($pattern.Description)"
                    Write-Host "Occurrences: $($pattern.Occurrences)"
                    Write-Host "Inédit: $($pattern.IsInedited)"
                    Write-Host "Statut de validation: $($pattern.ValidationStatus)"
                    Write-Host ""
                    
                    $validationStatus = Read-Host "Entrez le statut de validation (Valid, Invalid, Duplicate)"
                    $name = Read-Host "Entrez un nouveau nom (laisser vide pour conserver l'actuel)"
                    $description = Read-Host "Entrez une nouvelle description (laisser vide pour conserver l'actuelle)"
                    $isInedited = Read-Host "Est-ce un pattern inédit? (true/false, laisser vide pour conserver l'actuel)"
                    
                    $params = @{
                        PatternId = $patternId
                        ValidationStatus = if ($validationStatus) { $validationStatus } else { "Valid" }
                    }
                    
                    if ($name) {
                        $params.Name = $name
                    }
                    
                    if ($description) {
                        $params.Description = $description
                    }
                    
                    if ($isInedited -eq "true") {
                        $params.IsInedited = $true
                    }
                    elseif ($isInedited -eq "false") {
                        $params.IsInedited = $false
                    }
                    
                    Confirm-ErrorPattern @params
                    
                    Write-Host "Pattern validé avec succès." -ForegroundColor Green
                }
                else {
                    Write-Warning "Pattern non trouvé: $patternId"
                }
                
                Read-Host "Appuyez sur Entrée pour continuer"
            }
            "5" {
                $outputPath = Read-Host "Entrez le chemin du rapport (laisser vide pour utiliser la valeur par défaut)"
                $includeExamples = (Read-Host "Inclure des exemples? (y/n)") -eq "y"
                $onlyInedited = (Read-Host "Ne montrer que les patterns inédits? (y/n)") -eq "y"
                
                $params = @{}
                
                if ($outputPath) {
                    $params.OutputPath = $outputPath
                }
                
                if ($includeExamples) {
                    $params.IncludeExamples = $true
                }
                
                if ($onlyInedited) {
                    $params.OnlyInedited = $true
                }
                
                $reportPath = New-ErrorPatternReport @params
                
                Write-Host "Rapport généré: $reportPath" -ForegroundColor Green
                
                Read-Host "Appuyez sur Entrée pour continuer"
            }
            "6" {
                $continue = $false
            }
            default {
                Write-Warning "Option invalide. Veuillez choisir une option entre 1 et 6."
                Read-Host "Appuyez sur Entrée pour continuer"
            }
        }
    }
}

# Exécution principale
if ($Interactive) {
    Show-InteractiveMenu
}
else {
    # Analyser le fichier de log si spécifié
    if ($LogPath) {
        Analyze-ErrorLog -LogPath $LogPath
    }
    else {
        # Sinon, analyser la variable $Error
        Analyze-ErrorVariable
    }
    
    # Générer un rapport d'analyse
    $reportPath = New-ErrorPatternReport -OutputPath $OutputPath -IncludeExamples:$IncludeExamples -OnlyInedited:$OnlyInedited
    
    Write-Host "Rapport généré: $reportPath" -ForegroundColor Green
}
