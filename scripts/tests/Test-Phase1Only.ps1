<#
.SYNOPSIS
    Teste uniquement la Phase 1 (détection des références brisées) sur un fichier spécifique.
.DESCRIPTION
    Ce script exécute un test ciblé sur le script Detect-BrokenReferences.ps1
    pour vérifier qu'il fonctionne correctement.
.PARAMETER TestFile
    Chemin du fichier à tester. Par défaut: scripts\maintenance\encoding\Detect-BrokenReferences.ps1
.EXAMPLE
    .\Test-Phase1Only.ps1
    Teste le script Detect-BrokenReferences.ps1.
#>

param (
    [string]$TestFile = "scripts\maintenance\encoding\Detect-BrokenReferences.ps1"
)

# Fonction pour écrire des messages de log
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "TITLE")]
        [string]$Level = "INFO"
    )
    
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
        "TITLE" = "Cyan"
    }
    
    $Color = $ColorMap[$Level]
    $FormattedMessage = "[$TimeStamp] [$Level] $Message"
    
    Write-Host $FormattedMessage -ForegroundColor $Color
}

# Fonction pour tester la Phase 1 : Mise à jour des références
function Test-Phase1 {
    param (
        [string]$TestFile
    )
    
    Write-Log "Test de la Phase 1 : Mise à jour des références" -Level "TITLE"
    
    # Vérifier si le fichier de test existe
    if (-not (Test-Path -Path $TestFile)) {
        Write-Log "Le fichier de test n'existe pas: $TestFile" -Level "ERROR"
        return $false
    }
    
    Write-Log "Le fichier de test existe: $TestFile" -Level "SUCCESS"
    
    # Créer un fichier de test temporaire
    $TestDir = "scripts\tests\temp"
    if (-not (Test-Path -Path $TestDir)) {
        New-Item -ItemType Directory -Path $TestDir -Force | Out-Null
    }
    
    $TestFileCopy = Join-Path -Path $TestDir -ChildPath "test_script.ps1"
    Copy-Item -Path $TestFile -Destination $TestFileCopy -Force
    
    Write-Log "Fichier de test copié: $TestFileCopy" -Level "INFO"
    
    # Exécuter le script de test
    Write-Log "Exécution du script de test..." -Level "INFO"
    
    try {
        $OutputPath = Join-Path -Path $TestDir -ChildPath "test_report.json"
        $Result = & $TestFile -Path $TestDir -OutputPath $OutputPath -ShowDetails
        
        # Vérifier si le rapport a été généré
        if (Test-Path -Path $OutputPath) {
            Write-Log "Rapport généré avec succès: $OutputPath" -Level "SUCCESS"
            
            # Analyser le rapport (si possible)
            try {
                $Report = Get-Content -Path $OutputPath -Raw | ConvertFrom-Json
                Write-Log "Rapport analysé avec succès" -Level "SUCCESS"
                Write-Log "Timestamp: $($Report.Timestamp)" -Level "INFO"
                Write-Log "Nombre total de fichiers analysés: $($Report.TotalFiles)" -Level "INFO"
                Write-Log "Nombre de références brisées: $($Report.BrokenReferences.Count)" -Level "INFO"
            } catch {
                Write-Log "Impossible d'analyser le rapport: $_" -Level "WARNING"
            }
            
            # Nettoyer les fichiers temporaires
            Remove-Item -Path $TestFileCopy -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $OutputPath -Force -ErrorAction SilentlyContinue
            
            return $true
        } else {
            Write-Log "Le rapport n'a pas été généré: $OutputPath" -Level "WARNING"
            return $false
        }
    } catch {
        Write-Log "Erreur lors de l'exécution du script de test: $_" -Level "ERROR"
        return $false
    }
}

# Exécuter le test
$Success = Test-Phase1 -TestFile $TestFile

# Afficher le résultat
if ($Success) {
    Write-Log "Test réussi!" -Level "SUCCESS"
    exit 0
} else {
    Write-Log "Test échoué!" -Level "ERROR"
    exit 1
}
