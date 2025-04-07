# Script pour corriger directement le fichier RoadmapAdmin.ps1 original

# Chemin exact du fichier à corriger
$filePath = "D:/DO/WEB/N8N_tests/scripts_ json_a_ tester/EMAIL_SENDER_1/RoadmapAdmin.ps1"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $filePath)) {
    Write-Host "Le fichier n'existe pas: $filePath" -ForegroundColor Red
    
    # Essayer de trouver le fichier
    $foundFiles = Get-ChildItem -Path "D:/DO/WEB/N8N_tests/scripts_ json_a_ tester/EMAIL_SENDER_1" -Recurse -Filter "RoadmapAdmin.ps1"
    
    if ($foundFiles.Count -gt 0) {
        Write-Host "Fichiers trouvés:" -ForegroundColor Yellow
        foreach ($file in $foundFiles) {
            Write-Host "  $($file.FullName)" -ForegroundColor Yellow
        }
    }
    
    exit 1
}

# Créer une sauvegarde du fichier original
$backupPath = "$filePath.backup"
Copy-Item -Path $filePath -Destination $backupPath -Force
Write-Host "Sauvegarde créée: $backupPath" -ForegroundColor Green

# Lire le contenu du fichier
$content = Get-Content -Path $filePath -Raw

# Appliquer les corrections
# 1. Corriger le verbe non approuvé (Parse-Roadmap -> Get-RoadmapContent)
$content = $content -replace "function Parse-Roadmap", "function Get-RoadmapContent"
$content = $content -replace "Parse-Roadmap -Path", "Get-RoadmapContent -Path"

# 2, 3, 4. Corriger les comparaisons avec $null
$content = $content -replace "\`$currentSection -ne \`$null", "`$null -ne `$currentSection"
$content = $content -replace "\`$currentPhase -ne \`$null -and", "`$null -ne `$currentPhase -and"
$content = $content -replace "\`$currentPhase -ne \`$null", "`$null -ne `$currentPhase"

# 5. Corriger la variable non utilisée 'allSubtasksCompleted'
$lines = $content -split "`r`n|\r|\n"
$newLines = @()

for ($i = 0; $i -lt $lines.Count; $i++) {
    # Ignorer la ligne qui contient la déclaration de allSubtasksCompleted
    if ($lines[$i] -match "\`$allSubtasksCompleted = \`$true") {
        continue
    }
    $newLines += $lines[$i]
}

$content = $newLines -join "`r`n"

# 6. Corriger le paramètre switch avec valeur par défaut
$content = $content -replace "\[switch\]\`$MarkCompleted = \`$true", "[switch]`$MarkCompleted"

# Trouver la position après le bloc param
$paramEndPos = $content.IndexOf(')', $content.IndexOf('[switch]$MarkCompleted'))
if ($paramEndPos -gt 0) {
    $insertPos = $paramEndPos + 1
    $newContent = $content.Substring(0, $insertPos) + "`r`n`r`n    # Définir la valeur par défaut pour MarkCompleted`r`n    if (-not `$PSBoundParameters.ContainsKey('MarkCompleted')) {`r`n        `$MarkCompleted = `$true`r`n    }" + $content.Substring($insertPos)
    $content = $newContent
}

# 7. Corriger la variable non utilisée 'backupPath'
$content = $content -replace "\`$backupPath = Backup-Roadmap", "`$null = Backup-Roadmap"

# 8, 9. Corriger les autres comparaisons avec $null
$content = $content -replace "\`$roadmap -eq \`$null", "`$null -eq `$roadmap"
$content = $content -replace "\`$nextItem -eq \`$null", "`$null -eq `$nextItem"

# Enregistrer les modifications
Set-Content -Path $filePath -Value $content -Encoding UTF8

Write-Host "Les corrections ont été appliquées avec succès au fichier: $filePath" -ForegroundColor Green
Write-Host "Vous pouvez vérifier les modifications en comparant avec la sauvegarde: $backupPath" -ForegroundColor Green
