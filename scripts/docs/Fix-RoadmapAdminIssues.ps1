# Script pour corriger les problÃ¨mes spÃ©cifiques dans RoadmapAdmin.ps1
# Ce script corrige les 9 erreurs PSScriptAnalyzer identifiÃ©es


# Script pour corriger les problÃ¨mes spÃ©cifiques dans RoadmapAdmin.ps1
# Ce script corrige les 9 erreurs PSScriptAnalyzer identifiÃ©es

param (
    [Parameter(Mandatory = $false)

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal
]
    [string]$FilePath = "D"
)

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $FilePath)) {
    Write-Host "Le fichier n'existe pas: $FilePath" -ForegroundColor Red
    exit 1
}

# Lire le contenu du fichier
$content = Get-Content -Path $FilePath -Raw

# 1. Corriger le verbe non approuvÃ© (Parse-Roadmap -> Get-RoadmapContent)
$content = $content -replace "function Parse-Roadmap", "function Get-RoadmapContent"
$content = $content -replace "Parse-Roadmap", "Get-RoadmapContent"

# 2, 3, 4. Corriger les comparaisons avec $null
$content = $content -replace "(\$currentSection) -ne \$null", "`$null -ne `$1"
$content = $content -replace "(\$currentPhase) -ne \$null", "`$null -ne `$1"
$content = $content -replace "(\$currentPhase) -ne \$null -and", "`$null -ne `$1 -and"

# 5. Corriger la variable non utilisÃ©e 'allSubtasksCompleted'
$content = $content -replace "\s+\$allSubtasksCompleted = \$true\r?\n", "`n"

# 6. Corriger le paramÃ¨tre switch avec valeur par dÃ©faut
$content = $content -replace "(\[switch\])\$MarkCompleted = \$true", "`$1`$MarkCompleted"
$content = $content -replace "param \(\r?\n\s+\[string\]\$Path,\r?\n\s+\[hashtable\]\$Item,\r?\n\s+\[switch\]\$MarkCompleted\r?\n\s+\)", "param (`n    [string]`$Path,`n    [hashtable]`$Item,`n    [switch]`$MarkCompleted`n)`n`n# DÃ©finir la valeur par dÃ©faut pour MarkCompleted`nif (-not `$PSBoundParameters.ContainsKey('MarkCompleted')) {`n    `$MarkCompleted = `$true`n}"

# 7. Corriger la variable non utilisÃ©e 'backupPath'
$content = $content -replace "\$backupPath = Backup-Roadmap", "`$null = Backup-Roadmap"

# 8, 9. Corriger les autres comparaisons avec $null
$content = $content -replace "(\$roadmap) -eq \$null", "`$null -eq `$1"
$content = $content -replace "(\$nextItem) -eq \$null", "`$null -eq `$1"

# Enregistrer les modifications
Set-Content -Path $FilePath -Value $content -Encoding UTF8

Write-Host "Les corrections ont Ã©tÃ© appliquÃ©es avec succÃ¨s au fichier: $FilePath" -ForegroundColor Green

# VÃ©rifier si PSScriptAnalyzer est installÃ©
if (Get-Module -ListAvailable -Name PSScriptAnalyzer) {
    # Analyser le fichier pour vÃ©rifier s'il reste des problÃ¨mes
    Write-Host "Analyse du fichier avec PSScriptAnalyzer..." -ForegroundColor Cyan
    $issues = Invoke-ScriptAnalyzer -Path $FilePath
    
    if ($issues.Count -eq 0) {
        Write-Host "Aucun problÃ¨me dÃ©tectÃ©. Toutes les erreurs ont Ã©tÃ© corrigÃ©es!" -ForegroundColor Green
    }
    else {
        Write-Host "$($issues.Count) problÃ¨mes restants:" -ForegroundColor Yellow
        $issues | ForEach-Object {
            Write-Host "  - $($_.RuleName): $($_.Message) (ligne $($_.Line))" -ForegroundColor Yellow
        }
    }
}
else {
    Write-Host "PSScriptAnalyzer n'est pas installÃ©. Impossible de vÃ©rifier s'il reste des problÃ¨mes." -ForegroundColor Yellow
    Write-Host "Pour installer PSScriptAnalyzer, exÃ©cutez: Install-Module -Name PSScriptAnalyzer -Force" -ForegroundColor Yellow
}


}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
