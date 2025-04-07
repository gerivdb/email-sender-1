# Script pour corriger les problèmes spécifiques dans RoadmapAdmin.ps1
# Ce script corrige les 9 erreurs PSScriptAnalyzer identifiées

param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath = "D:\DO\WEB\N8N_tests\scripts_ json_a_ tester\EMAIL_SENDER_1\RoadmapAdmin.ps1"
)

# Vérifier si le fichier existe
if (-not (Test-Path -Path $FilePath)) {
    Write-Host "Le fichier n'existe pas: $FilePath" -ForegroundColor Red
    exit 1
}

# Lire le contenu du fichier
$content = Get-Content -Path $FilePath -Raw

# 1. Corriger le verbe non approuvé (Parse-Roadmap -> Get-RoadmapContent)
$content = $content -replace "function Parse-Roadmap", "function Get-RoadmapContent"
$content = $content -replace "Parse-Roadmap", "Get-RoadmapContent"

# 2, 3, 4. Corriger les comparaisons avec $null
$content = $content -replace "(\$currentSection) -ne \$null", "`$null -ne `$1"
$content = $content -replace "(\$currentPhase) -ne \$null", "`$null -ne `$1"
$content = $content -replace "(\$currentPhase) -ne \$null -and", "`$null -ne `$1 -and"

# 5. Corriger la variable non utilisée 'allSubtasksCompleted'
$content = $content -replace "\s+\$allSubtasksCompleted = \$true\r?\n", "`n"

# 6. Corriger le paramètre switch avec valeur par défaut
$content = $content -replace "(\[switch\])\$MarkCompleted = \$true", "`$1`$MarkCompleted"
$content = $content -replace "param \(\r?\n\s+\[string\]\$Path,\r?\n\s+\[hashtable\]\$Item,\r?\n\s+\[switch\]\$MarkCompleted\r?\n\s+\)", "param (`n    [string]`$Path,`n    [hashtable]`$Item,`n    [switch]`$MarkCompleted`n)`n`n# Définir la valeur par défaut pour MarkCompleted`nif (-not `$PSBoundParameters.ContainsKey('MarkCompleted')) {`n    `$MarkCompleted = `$true`n}"

# 7. Corriger la variable non utilisée 'backupPath'
$content = $content -replace "\$backupPath = Backup-Roadmap", "`$null = Backup-Roadmap"

# 8, 9. Corriger les autres comparaisons avec $null
$content = $content -replace "(\$roadmap) -eq \$null", "`$null -eq `$1"
$content = $content -replace "(\$nextItem) -eq \$null", "`$null -eq `$1"

# Enregistrer les modifications
Set-Content -Path $FilePath -Value $content -Encoding UTF8

Write-Host "Les corrections ont été appliquées avec succès au fichier: $FilePath" -ForegroundColor Green

# Vérifier si PSScriptAnalyzer est installé
if (Get-Module -ListAvailable -Name PSScriptAnalyzer) {
    # Analyser le fichier pour vérifier s'il reste des problèmes
    Write-Host "Analyse du fichier avec PSScriptAnalyzer..." -ForegroundColor Cyan
    $issues = Invoke-ScriptAnalyzer -Path $FilePath
    
    if ($issues.Count -eq 0) {
        Write-Host "Aucun problème détecté. Toutes les erreurs ont été corrigées!" -ForegroundColor Green
    }
    else {
        Write-Host "$($issues.Count) problèmes restants:" -ForegroundColor Yellow
        $issues | ForEach-Object {
            Write-Host "  - $($_.RuleName): $($_.Message) (ligne $($_.Line))" -ForegroundColor Yellow
        }
    }
}
else {
    Write-Host "PSScriptAnalyzer n'est pas installé. Impossible de vérifier s'il reste des problèmes." -ForegroundColor Yellow
    Write-Host "Pour installer PSScriptAnalyzer, exécutez: Install-Module -Name PSScriptAnalyzer -Force" -ForegroundColor Yellow
}
