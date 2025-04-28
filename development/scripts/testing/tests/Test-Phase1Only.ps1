<#
.SYNOPSIS
    Teste uniquement la Phase 1 (dÃ©tection des rÃ©fÃ©rences brisÃ©es) sur un fichier spÃ©cifique.
.DESCRIPTION
    Ce script exÃ©cute un test ciblÃ© sur le script Detect-BrokenReferences.ps1
    pour vÃ©rifier qu'il fonctionne correctement.
.PARAMETER TestFile
    Chemin du fichier Ã  tester. Par dÃ©faut: scripts\maintenance\encoding\Detect-BrokenReferences.ps1
.EXAMPLE
    .\Test-Phase1Only.ps1
    Teste le script Detect-BrokenReferences.ps1.
#>

param (
    [string]$TestFile = "scripts\maintenance\encoding\Detect-BrokenReferences.ps1"
)

# Fonction pour Ã©crire des messages de log
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

# Fonction pour tester la Phase 1 : Mise Ã  jour des rÃ©fÃ©rences
function Test-Phase1 {
    param (
        [string]$TestFile
    )
    
    Write-Log "Test de la Phase 1 : Mise Ã  jour des rÃ©fÃ©rences" -Level "TITLE"
    
    # VÃ©rifier si le fichier de test existe
    if (-not (Test-Path -Path $TestFile)) {
        Write-Log "Le fichier de test n'existe pas: $TestFile" -Level "ERROR"
        return $false
    }
    
    Write-Log "Le fichier de test existe: $TestFile" -Level "SUCCESS"
    
    # CrÃ©er un fichier de test temporaire
    $TestDir = "scripts\tests\temp"
    if (-not (Test-Path -Path $TestDir)) {
        New-Item -ItemType Directory -Path $TestDir -Force | Out-Null
    }
    
    $TestFileCopy = Join-Path -Path $TestDir -ChildPath "test_script.ps1"
    Copy-Item -Path $TestFile -Destination $TestFileCopy -Force
    
    Write-Log "Fichier de test copiÃ©: $TestFileCopy" -Level "INFO"
    
    # ExÃ©cuter le script de test
    Write-Log "ExÃ©cution du script de test..." -Level "INFO"
    
    try {
        $OutputPath = Join-Path -Path $TestDir -ChildPath "test_report.json"
        $Result = & $TestFile -Path $TestDir -OutputPath $OutputPath -ShowDetails
        
        # VÃ©rifier si le rapport a Ã©tÃ© gÃ©nÃ©rÃ©
        if (Test-Path -Path $OutputPath) {
            Write-Log "Rapport gÃ©nÃ©rÃ© avec succÃ¨s: $OutputPath" -Level "SUCCESS"
            
            # Analyser le rapport (si possible)
            try {
                $Report = Get-Content -Path $OutputPath -Raw | ConvertFrom-Json
                Write-Log "Rapport analysÃ© avec succÃ¨s" -Level "SUCCESS"
                Write-Log "Timestamp: $($Report.Timestamp)" -Level "INFO"
                Write-Log "Nombre total de fichiers analysÃ©s: $($Report.TotalFiles)" -Level "INFO"
                Write-Log "Nombre de rÃ©fÃ©rences brisÃ©es: $($Report.BrokenReferences.Count)" -Level "INFO"
            } catch {
                Write-Log "Impossible d'analyser le rapport: $_" -Level "WARNING"
            }
            
            # Nettoyer les fichiers temporaires
            Remove-Item -Path $TestFileCopy -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $OutputPath -Force -ErrorAction SilentlyContinue
            
            return $true
        } else {
            Write-Log "Le rapport n'a pas Ã©tÃ© gÃ©nÃ©rÃ©: $OutputPath" -Level "WARNING"
            return $false
        }
    } catch {
        Write-Log "Erreur lors de l'exÃ©cution du script de test: $_" -Level "ERROR"
        return $false
    }
}

# ExÃ©cuter le test
$Success = Test-Phase1 -TestFile $TestFile

# Afficher le rÃ©sultat
if ($Success) {
    Write-Log "Test rÃ©ussi!" -Level "SUCCESS"
    exit 0
} else {
    Write-Log "Test Ã©chouÃ©!" -Level "ERROR"
    exit 1
}
