# Script pour corriger les problèmes dans RoadmapAdmin.ps1 individuellement

$filePath = "D:/DO/WEB/N8N_tests/scripts_ json_a_ tester/EMAIL_SENDER_1/Roadmap/RoadmapAdmin.ps1"

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

# Enregistrer les modifications
Set-Content -Path $filePath -Value $content -Encoding UTF8
Write-Host "Correction 1 appliquée: Verbe non approuvé (Parse-Roadmap -> Get-RoadmapContent)" -ForegroundColor Green

# Lire à nouveau le contenu du fichier
$content = Get-Content -Path $filePath -Raw

# 2. Corriger la comparaison avec $null (ligne 127)
$content = $content.Replace('$currentSection -ne $null', '$null -ne $currentSection')

# Enregistrer les modifications
Set-Content -Path $filePath -Value $content -Encoding UTF8
Write-Host "Correction 2 appliquée: Comparaison avec $null (ligne 127)" -ForegroundColor Green

# Lire à nouveau le contenu du fichier
$content = Get-Content -Path $filePath -Raw

# 3. Corriger la comparaison avec $null (ligne 144)
$content = $content.Replace('$currentPhase -ne $null', '$null -ne $currentPhase')

# Enregistrer les modifications
Set-Content -Path $filePath -Value $content -Encoding UTF8
Write-Host "Correction 3 appliquée: Comparaison avec $null (ligne 144)" -ForegroundColor Green

# Lire à nouveau le contenu du fichier
$content = Get-Content -Path $filePath -Raw

# 4. Corriger la comparaison avec $null (ligne 159)
$content = $content.Replace('$currentPhase -ne $null -and', '$null -ne $currentPhase -and')

# Enregistrer les modifications
Set-Content -Path $filePath -Value $content -Encoding UTF8
Write-Host "Correction 4 appliquée: Comparaison avec $null (ligne 159)" -ForegroundColor Green

# Lire le contenu du fichier ligne par ligne
$lines = Get-Content -Path $filePath

# 5. Corriger la variable non utilisée (ligne 273)
$newLines = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($i -eq 272 -and $lines[$i].Contains('$allSubtasksCompleted = $true')) {
        # Ignorer cette ligne
        continue
    }
    $newLines += $lines[$i]
}

# Enregistrer les modifications
Set-Content -Path $filePath -Value $newLines -Encoding UTF8
Write-Host "Correction 5 appliquée: Variable non utilisée (ligne 273)" -ForegroundColor Green

# Lire à nouveau le contenu du fichier
$content = Get-Content -Path $filePath -Raw

# 6. Corriger le paramètre switch avec valeur par défaut (ligne 318)
$content = $content.Replace('[switch]$MarkCompleted = $true', '[switch]$MarkCompleted')

# Trouver la position après le bloc param
$paramEndPos = $content.IndexOf(')', $content.IndexOf('[switch]$MarkCompleted'))
if ($paramEndPos -gt 0) {
    $insertPos = $paramEndPos + 1
    $newContent = $content.Substring(0, $insertPos) + "`n`n    # Définir la valeur par défaut pour MarkCompleted`n    if (-not `$PSBoundParameters.ContainsKey('MarkCompleted')) {`n        `$MarkCompleted = `$true`n    }" + $content.Substring($insertPos)
    $content = $newContent
}

# Enregistrer les modifications
Set-Content -Path $filePath -Value $content -Encoding UTF8
Write-Host "Correction 6 appliquée: Paramètre switch avec valeur par défaut (ligne 318)" -ForegroundColor Green

# Lire à nouveau le contenu du fichier
$content = Get-Content -Path $filePath -Raw

# 7. Corriger la variable non utilisée (ligne 426)
$content = $content.Replace('$backupPath = Backup-Roadmap', '$null = Backup-Roadmap')

# Enregistrer les modifications
Set-Content -Path $filePath -Value $content -Encoding UTF8
Write-Host "Correction 7 appliquée: Variable non utilisée (ligne 426)" -ForegroundColor Green

# Lire à nouveau le contenu du fichier
$content = Get-Content -Path $filePath -Raw

# 8. Corriger la comparaison avec $null (ligne 431)
$content = $content.Replace('$roadmap -eq $null', '$null -eq $roadmap')

# Enregistrer les modifications
Set-Content -Path $filePath -Value $content -Encoding UTF8
Write-Host "Correction 8 appliquée: Comparaison avec $null (ligne 431)" -ForegroundColor Green

# Lire à nouveau le contenu du fichier
$content = Get-Content -Path $filePath -Raw

# 9. Corriger la comparaison avec $null (ligne 451)
$content = $content.Replace('$nextItem -eq $null', '$null -eq $nextItem')

# Enregistrer les modifications
Set-Content -Path $filePath -Value $content -Encoding UTF8
Write-Host "Correction 9 appliquée: Comparaison avec $null (ligne 451)" -ForegroundColor Green

Write-Host "Toutes les corrections ont été appliquées avec succès au fichier: $filePath" -ForegroundColor Green
