# Script pour mettre Ã  jour la tÃ¢che d'optimisation des performances pour les grands arbres syntaxiques

$roadmapPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\roadmaps\roadmap_complete_converted.md"
$taskId = "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.5"

# VÃ©rifier si le fichier de roadmap existe
if (-not (Test-Path -Path $roadmapPath)) {
    Write-Error "Le fichier de roadmap '$roadmapPath' n'existe pas."
    exit 1
}

# Lire le contenu du fichier de roadmap
$content = Get-Content -Path $roadmapPath -Encoding UTF8
if ($null -eq $content -or $content.Count -eq 0) {
    Write-Error "Le fichier de roadmap est vide."
    exit 1
}

Write-Host "Fichier de roadmap : $roadmapPath" -ForegroundColor Cyan
Write-Host "Nombre de lignes : $($content.Count)" -ForegroundColor Cyan
Write-Host "TÃ¢che Ã  mettre Ã  jour : $taskId" -ForegroundColor Cyan

# Parcourir le contenu et mettre Ã  jour la tÃ¢che
$updatedContent = $content.Clone()
$taskFound = $false
$taskLine = 0

for ($i = 0; $i -lt $content.Count; $i++) {
    $line = $content[$i]
    
    # VÃ©rifier si la ligne correspond Ã  la tÃ¢che
    if ($line -match '^\s*-\s+\[([ xX])\]\s+(\*\*)?(\d+(\.\d+)*)\s*(\*\*)?\s+(.+)$') {
        $status = $matches[1]
        $currentTaskId = $matches[3]
        $taskName = $matches[6]
        
        # VÃ©rifier si c'est la tÃ¢che que nous cherchons
        if ($currentTaskId -eq $taskId) {
            Write-Host "TÃ¢che trouvÃ©e Ã  la ligne $($i+1) : [$status] $currentTaskId $taskName" -ForegroundColor Yellow
            $taskFound = $true
            $taskLine = $i
            
            # VÃ©rifier si la tÃ¢che est dÃ©jÃ  cochÃ©e
            if ($status -eq 'x' -or $status -eq 'X') {
                Write-Host "  TÃ¢che dÃ©jÃ  cochÃ©e." -ForegroundColor Green
                exit 0
            }
            
            # Mettre Ã  jour la tÃ¢che
            $updatedLine = $line -replace '\[ \]', '[x]'
            $updatedContent[$i] = $updatedLine
            
            Write-Host "  TÃ¢che mise Ã  jour : $updatedLine" -ForegroundColor Green
            break
        }
    }
}

# VÃ©rifier si la tÃ¢che a Ã©tÃ© trouvÃ©e
if (-not $taskFound) {
    Write-Error "La tÃ¢che avec l'ID '$taskId' n'a pas Ã©tÃ© trouvÃ©e dans le fichier de roadmap."
    exit 1
}

# Sauvegarder le contenu mis Ã  jour
$updatedContent | Set-Content -Path $roadmapPath -Encoding UTF8
Write-Host "`nLe fichier de roadmap a Ã©tÃ© mis Ã  jour avec succÃ¨s." -ForegroundColor Green
Write-Host "TÃ¢che mise Ã  jour Ã  la ligne $($taskLine+1)." -ForegroundColor Green
