# Importer le module AugmentMemoriesManager
. "$PSScriptRoot\AugmentMemoriesManager.ps1"

# Tests pour Move-NextTask
Write-Host "Test 1: Passe à la tâche suivante si la tâche actuelle est terminée"
$state = @{ CurrentTask = "T1"; Status = "Completed"; Roadmap = @("T1", "T2", "T3") }
$newState = Move-NextTask -State $state
if ($newState.CurrentTask -eq "T2") {
    Write-Host "Test 1: Réussi" -ForegroundColor Green
} else {
    Write-Host "Test 1: Échoué - CurrentTask = $($newState.CurrentTask)" -ForegroundColor Red
}

Write-Host "Test 2: Reste sur la tâche si non terminée"
$state = @{ CurrentTask = "T1"; Status = "InProgress"; Roadmap = @("T1", "T2") }
$newState = Move-NextTask -State $state
if ($newState.CurrentTask -eq "T1") {
    Write-Host "Test 2: Réussi" -ForegroundColor Green
} else {
    Write-Host "Test 2: Échoué - CurrentTask = $($newState.CurrentTask)" -ForegroundColor Red
}

Write-Host "Test 3: Ne change pas si c'est la dernière tâche"
$state = @{ CurrentTask = "T3"; Status = "Completed"; Roadmap = @("T1", "T2", "T3") }
$newState = Move-NextTask -State $state
if ($newState.CurrentTask -eq "T3" -and $newState.Status -eq "Completed") {
    Write-Host "Test 3: Réussi" -ForegroundColor Green
} else {
    Write-Host "Test 3: Échoué - CurrentTask = $($newState.CurrentTask), Status = $($newState.Status)" -ForegroundColor Red
}

# Tests pour Split-LargeInput
Write-Host "Test 4: Divise un input > 3 Ko en segments < 2 Ko"
$textData = "a" * 3500
$segments = Split-LargeInput -Input $textData -MaxSize 2000
if ($segments.Count -gt 1 -and ($segments | ForEach-Object { [System.Text.Encoding]::UTF8.GetByteCount($_) -le 2000 })) {
    Write-Host "Test 4: Réussi - $($segments.Count) segments générés" -ForegroundColor Green
} else {
    Write-Host "Test 4: Échoué - $($segments.Count) segments générés" -ForegroundColor Red
}

Write-Host "Test 5: Ne divise pas un input < 3 Ko"
$textData = "a" * 2000
$segments = Split-LargeInput -Input $textData -MaxSize 2000
if ($segments.Count -eq 1) {
    Write-Host "Test 5: Réussi" -ForegroundColor Green
} else {
    Write-Host "Test 5: Échoué - $($segments.Count) segments générés" -ForegroundColor Red
}

Write-Host "Test 6: Gère correctement un input vide"
$textData = ""
$segments = Split-LargeInput -Input $textData
if ($segments.Count -eq 1 -and $segments[0] -eq "") {
    Write-Host "Test 6: Réussi" -ForegroundColor Green
} else {
    Write-Host "Test 6: Échoué - $($segments.Count) segments générés" -ForegroundColor Red
}

# Tests pour Update-AugmentMemories
Write-Host "Test 7: Génère un fichier JSON valide"
$tempFile = [System.IO.Path]::GetTempFileName()
Update-AugmentMemories -OutputPath $tempFile
if (Test-Path $tempFile) {
    try {
        $content = Get-Content $tempFile -Raw
        # Tester si le contenu est un JSON valide
        $null = ConvertFrom-Json $content -ErrorAction Stop
        Write-Host "Test 7: Réussi - JSON valide généré" -ForegroundColor Green
    } catch {
        Write-Host "Test 7: Échoué - JSON invalide: $_" -ForegroundColor Red
    }
    Remove-Item $tempFile -Force
} else {
    Write-Host "Test 7: Échoué - Fichier non généré" -ForegroundColor Red
}

Write-Host "Test 8: Génère un fichier de taille < 4 Ko"
$tempFile = [System.IO.Path]::GetTempFileName()
Update-AugmentMemories -OutputPath $tempFile
if (Test-Path $tempFile) {
    $content = Get-Content $tempFile -Raw
    $byteCount = [System.Text.Encoding]::UTF8.GetByteCount($content)
    if ($byteCount -lt 4000) {
        Write-Host "Test 8: Réussi - Taille: $byteCount octets" -ForegroundColor Green
    } else {
        Write-Host "Test 8: Échoué - Taille: $byteCount octets" -ForegroundColor Red
    }
    Remove-Item $tempFile -Force
} else {
    Write-Host "Test 8: Échoué - Fichier non généré" -ForegroundColor Red
}

Write-Host "Tous les tests terminés." -ForegroundColor Cyan
