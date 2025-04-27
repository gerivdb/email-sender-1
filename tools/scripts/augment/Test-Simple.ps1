# Importer le module AugmentMemoriesManager
. "$PSScriptRoot\AugmentMemoriesManager.ps1"

# Tests pour Move-NextTask
Write-Host "Test 1: Passe Ã  la tÃ¢che suivante si la tÃ¢che actuelle est terminÃ©e"
$state = @{ CurrentTask = "T1"; Status = "Completed"; Roadmap = @("T1", "T2", "T3") }
$newState = Move-NextTask -State $state
if ($newState.CurrentTask -eq "T2") {
    Write-Host "Test 1: RÃ©ussi" -ForegroundColor Green
} else {
    Write-Host "Test 1: Ã‰chouÃ© - CurrentTask = $($newState.CurrentTask)" -ForegroundColor Red
}

Write-Host "Test 2: Reste sur la tÃ¢che si non terminÃ©e"
$state = @{ CurrentTask = "T1"; Status = "InProgress"; Roadmap = @("T1", "T2") }
$newState = Move-NextTask -State $state
if ($newState.CurrentTask -eq "T1") {
    Write-Host "Test 2: RÃ©ussi" -ForegroundColor Green
} else {
    Write-Host "Test 2: Ã‰chouÃ© - CurrentTask = $($newState.CurrentTask)" -ForegroundColor Red
}

Write-Host "Test 3: Ne change pas si c'est la derniÃ¨re tÃ¢che"
$state = @{ CurrentTask = "T3"; Status = "Completed"; Roadmap = @("T1", "T2", "T3") }
$newState = Move-NextTask -State $state
if ($newState.CurrentTask -eq "T3" -and $newState.Status -eq "Completed") {
    Write-Host "Test 3: RÃ©ussi" -ForegroundColor Green
} else {
    Write-Host "Test 3: Ã‰chouÃ© - CurrentTask = $($newState.CurrentTask), Status = $($newState.Status)" -ForegroundColor Red
}

# Tests pour Split-LargeInput
Write-Host "Test 4: Divise un input > 3 Ko en segments < 2 Ko"
$textData = "a" * 3500
$segments = Split-LargeInput -Input $textData -MaxSize 2000
if ($segments.Count -gt 1 -and ($segments | ForEach-Object { [System.Text.Encoding]::UTF8.GetByteCount($_) -le 2000 })) {
    Write-Host "Test 4: RÃ©ussi - $($segments.Count) segments gÃ©nÃ©rÃ©s" -ForegroundColor Green
} else {
    Write-Host "Test 4: Ã‰chouÃ© - $($segments.Count) segments gÃ©nÃ©rÃ©s" -ForegroundColor Red
}

Write-Host "Test 5: Ne divise pas un input < 3 Ko"
$textData = "a" * 2000
$segments = Split-LargeInput -Input $textData -MaxSize 2000
if ($segments.Count -eq 1) {
    Write-Host "Test 5: RÃ©ussi" -ForegroundColor Green
} else {
    Write-Host "Test 5: Ã‰chouÃ© - $($segments.Count) segments gÃ©nÃ©rÃ©s" -ForegroundColor Red
}

Write-Host "Test 6: GÃ¨re correctement un input vide"
$textData = ""
$segments = Split-LargeInput -Input $textData
if ($segments.Count -eq 1 -and $segments[0] -eq "") {
    Write-Host "Test 6: RÃ©ussi" -ForegroundColor Green
} else {
    Write-Host "Test 6: Ã‰chouÃ© - $($segments.Count) segments gÃ©nÃ©rÃ©s" -ForegroundColor Red
}

# Tests pour Update-AugmentMemories
Write-Host "Test 7: GÃ©nÃ¨re un fichier JSON valide"
$tempFile = [System.IO.Path]::GetTempFileName()
Update-AugmentMemories -OutputPath $tempFile
if (Test-Path $tempFile) {
    try {
        $content = Get-Content $tempFile -Raw
        # Tester si le contenu est un JSON valide
        $null = ConvertFrom-Json $content -ErrorAction Stop
        Write-Host "Test 7: RÃ©ussi - JSON valide gÃ©nÃ©rÃ©" -ForegroundColor Green
    } catch {
        Write-Host "Test 7: Ã‰chouÃ© - JSON invalide: $_" -ForegroundColor Red
    }
    Remove-Item $tempFile -Force
} else {
    Write-Host "Test 7: Ã‰chouÃ© - Fichier non gÃ©nÃ©rÃ©" -ForegroundColor Red
}

Write-Host "Test 8: GÃ©nÃ¨re un fichier de taille < 4 Ko"
$tempFile = [System.IO.Path]::GetTempFileName()
Update-AugmentMemories -OutputPath $tempFile
if (Test-Path $tempFile) {
    $content = Get-Content $tempFile -Raw
    $byteCount = [System.Text.Encoding]::UTF8.GetByteCount($content)
    if ($byteCount -lt 4000) {
        Write-Host "Test 8: RÃ©ussi - Taille: $byteCount octets" -ForegroundColor Green
    } else {
        Write-Host "Test 8: Ã‰chouÃ© - Taille: $byteCount octets" -ForegroundColor Red
    }
    Remove-Item $tempFile -Force
} else {
    Write-Host "Test 8: Ã‰chouÃ© - Fichier non gÃ©nÃ©rÃ©" -ForegroundColor Red
}

Write-Host "Tous les tests terminÃ©s." -ForegroundColor Cyan
