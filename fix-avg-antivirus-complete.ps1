# Script de configuration AVG pour le développement Go - VERSION COMPLETE
# Exécuter en tant qu'administrateur

Write-Host "🛡️ Configuration AVG pour le développement Go - VERSION COMPLETE" -ForegroundColor Green

# Processus AVG détectés
$avgProcesses = Get-Process | Where-Object { $_.ProcessName -match "avg|antiv" }
Write-Host "🔍 Processus AVG détectés :" -ForegroundColor Yellow
foreach ($proc in $avgProcesses) {
   Write-Host "  - $($proc.ProcessName) (ID: $($proc.Id))" -ForegroundColor Cyan
}

# Dossiers à exclure d'AVG
$foldersToExclude = @(
   "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1",
   "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\cmd",
   "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\pkg",
   "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\tools",
   "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development",
   "C:\Users\$env:USERNAME\go",
   "C:\Go",
   "$env:GOPATH",
   "$env:GOROOT",
   "$env:TEMP\go-build*",
   "$env:LOCALAPPDATA\go-build",
   "C:\Users\$env:USERNAME\AppData\Local\go-build"
)

# Extensions à exclure
$extensionsToExclude = @(
   ".exe",
   ".go",
   ".mod",
   ".sum",
   ".dll",
   ".a",
   ".obj"
)

# Processus à exclure du scanning en temps réel
$processesToExclude = @(
   "go.exe",
   "gofmt.exe",
   "golangci-lint.exe",
   "dlv.exe"
)

Write-Host "`n📁 Dossiers à exclure d'AVG :" -ForegroundColor Yellow
foreach ($folder in $foldersToExclude) {
   Write-Host "  - $folder" -ForegroundColor Cyan
}

Write-Host "`n📝 Extensions à exclure :" -ForegroundColor Yellow
foreach ($ext in $extensionsToExclude) {
   Write-Host "  - *$ext" -ForegroundColor Cyan
}

Write-Host "`n⚙️  Processus à exclure :" -ForegroundColor Yellow
foreach ($proc in $processesToExclude) {
   Write-Host "  - $proc" -ForegroundColor Cyan
}

Write-Host "`n⚠️  INSTRUCTIONS MANUELLES DÉTAILLÉES :" -ForegroundColor Red
Write-Host "1. Ouvrir AVG Antivirus (interface principale)" -ForegroundColor White
Write-Host "2. Cliquer sur 'Menu' (3 lignes) → 'Paramètres'" -ForegroundColor White
Write-Host "3. Dans 'Paramètres' → 'Général' → 'Exceptions'" -ForegroundColor White
Write-Host "4. Cliquer 'Ajouter une exception'" -ForegroundColor White
Write-Host "5. Pour CHAQUE dossier ci-dessus :" -ForegroundColor White
Write-Host "   - Sélectionner 'Dossier' → Parcourir → Sélectionner le dossier" -ForegroundColor Gray
Write-Host "   - Cocher 'Tous les scans'" -ForegroundColor Gray
Write-Host "6. Pour les extensions :" -ForegroundColor White
Write-Host "   - Sélectionner 'Fichier/Type de fichier'" -ForegroundColor Gray
Write-Host "   - Entrer l'extension (ex: *.exe, *.go)" -ForegroundColor Gray
Write-Host "7. IMPORTANT: Redémarrer le système après configuration" -ForegroundColor Red

Write-Host "`n🚀 SOLUTION TEMPORAIRE RAPIDE :" -ForegroundColor Green
Write-Host "Si vous voulez tester rapidement sans redémarrage :" -ForegroundColor White
Write-Host "1. Désactiver temporairement 'Protection en temps réel' dans AVG" -ForegroundColor Yellow
Write-Host "2. Compiler votre projet Go" -ForegroundColor Yellow
Write-Host "3. Réactiver la protection ensuite" -ForegroundColor Yellow

# Tentative d'ouverture d'AVG
try {
   Start-Process "C:\Program Files\AVG\Antivirus\AVGUI.exe"
   Write-Host "`n✅ AVG ouvert - Suivez les instructions ci-dessus" -ForegroundColor Green
}
catch {
   Write-Host "`n❌ Impossible d'ouvrir AVG automatiquement" -ForegroundColor Red
   Write-Host "   Ouvrez manuellement AVG depuis le menu Démarrer" -ForegroundColor Yellow
}

Write-Host "`n💡 Conseils supplémentaires :" -ForegroundColor Magenta
Write-Host "- Désactiver temporairement la protection en temps réel pendant le développement" -ForegroundColor White
Write-Host "- Considérer l'ajout du répertoire de travail entier en exception" -ForegroundColor White
Write-Host "- Redémarrer Windows après les modifications pour une prise en compte complète" -ForegroundColor White

# Créer un fichier batch pour la compilation sécurisée
$batchContent = @"
@echo off
echo Compilation Go avec protection AVG temporairement desactivee
echo.
echo ATTENTION: Ce script desactive temporairement AVG
echo Appuyez sur une touche pour continuer ou Ctrl+C pour annuler
pause

echo Arret temporaire de la protection AVG...
sc stop AVGSvc 2>nul
timeout /t 3 /nobreak

echo Compilation du projet...
cd /d "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
go build ./...

echo Redemarrage de la protection AVG...
sc start AVGSvc 2>nul

echo.
echo Compilation terminee. Protection AVG reactivee.
pause
"@

$batchPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\compile-with-avg-bypass.bat"
Set-Content -Path $batchPath -Value $batchContent -Encoding ASCII
Write-Host "`n📄 Script de compilation créé : compile-with-avg-bypass.bat" -ForegroundColor Cyan
Write-Host "   (Exécuter en tant qu'administrateur)" -ForegroundColor Gray
