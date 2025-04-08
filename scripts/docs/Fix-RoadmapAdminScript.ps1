# Script pour corriger les problèmes dans RoadmapAdmin.ps1

$filePath = "D"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $filePath)) {
    Write-Host "Le fichier n'existe pas: $filePath" -ForegroundColor Red
    exit 1
}

# Lire le contenu du fichier
$content = Get-Content -Path $filePath -Raw

# 1. Corriger le verbe non approuvé (Parse-Roadmap -> Get-RoadmapContent)
$content = $content.Replace("function Parse-Roadmap", "function Get-RoadmapContent")
$content = $content.Replace("Parse-Roadmap -Path", "Get-RoadmapContent -Path")

# 2, 3, 4. Corriger les comparaisons avec $null
$content = $content.Replace('$currentSection -ne $null', '$null -ne $currentSection')
$content = $content.Replace('$currentPhase -ne $null', '$null -ne $currentPhase')
$content = $content.Replace('$currentPhase -ne $null -and', '$null -ne $currentPhase -and')

# 5. Corriger la variable non utilisée 'allSubtasksCompleted'
$content = $content.Replace('                        # Vérifier si toutes les sous-tâches sont terminées
                        $allSubtasksCompleted = $true', '                        # Vérifier si au moins une sous-tâche n''est pas terminée')

# 6. Corriger le paramètre switch avec valeur par défaut
$content = $content.Replace('[switch]$MarkCompleted = $true', '[switch]$MarkCompleted')

# Ajouter le code pour définir la valeur par défaut
$paramBlock = "    param (
        [string]`$Path,
        [hashtable]`$Item,
        [switch]`$MarkCompleted
    )"

$replacementBlock = "    param (
        [string]`$Path,
        [hashtable]`$Item,
        [switch]`$MarkCompleted
    )
    
    # Définir la valeur par défaut pour MarkCompleted
    if (-not `$PSBoundParameters.ContainsKey('MarkCompleted')) {
        `$MarkCompleted = `$true
    }"

$content = $content.Replace($paramBlock, $replacementBlock)

# 7. Corriger la variable non utilisée 'backupPath'
$content = $content.Replace('    # Créer une sauvegarde
    $backupPath = Backup-Roadmap -Path $RoadmapPath', '    # Créer une sauvegarde
    $null = Backup-Roadmap -Path $RoadmapPath')

# 8, 9. Corriger les autres comparaisons avec $null
$content = $content.Replace('    if ($roadmap -eq $null) {', '    if ($null -eq $roadmap) {')
$content = $content.Replace('    if ($nextItem -eq $null) {', '    if ($null -eq $nextItem) {')

# Enregistrer les modifications
Set-Content -Path $filePath -Value $content -Encoding UTF8

Write-Host "Les corrections ont été appliquées avec succès au fichier: $filePath" -ForegroundColor Green

