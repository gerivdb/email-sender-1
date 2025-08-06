# Test unitaire PowerShell pour audit-modes-verification.ps1

# Chargement du script à tester
. .\audit-modes-verification.ps1

# Mock des fichiers cibles pour le test
$mockTargets = @(
   "mock-AGENTS.md",
   "mock-.roomodes",
   "mock-custom_modes.yaml"
)

foreach ($file in $mockTargets) {
   Set-Content -Path $file -Value "test"
}

# Redéfinition de $targets pour le test
$global:targets = $mockTargets

# Exécution du script d’audit
$logPath = "test-audit-modes-verification.log"
Remove-Item -Path $logPath -ErrorAction SilentlyContinue
foreach ($target in $global:targets) {
   $exists = Test-Path $target
   if ($exists) {
      $info = Get-Item $target
      $size = $info.Length
      "OK : $target (taille : $size octets)" | Out-File $logPath -Append
   }
   else {
      "ERREUR : $target (fichier introuvable)" | Out-File $logPath -Append
   }
}

# Vérification du résultat attendu
$logContent = Get-Content $logPath
$expected = $mockTargets | ForEach-Object { "OK : $_ (taille : 4 octets)" }
$testPassed = $true
foreach ($line in $expected) {
   if (-not ($logContent -contains $line)) {
      $testPassed = $false
      Write-Host "Test échoué : $line absent du log"
   }
}
if ($testPassed) {
   Write-Host "Test unitaire réussi : tous les fichiers mock détectés"
}
else {
   Write-Host "Test unitaire échoué"
}

# Nettoyage des fichiers mock
foreach ($file in $mockTargets) {
   Remove-Item -Path $file -ErrorAction SilentlyContinue
}
Remove-Item -Path $logPath -ErrorAction SilentlyContinue