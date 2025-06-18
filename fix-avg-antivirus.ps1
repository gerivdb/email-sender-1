# Script de configuration AVG pour le développement Go
# Exécuter en tant qu'administrateur

Write-Host "🛡️ Configuration AVG pour le développement Go" -ForegroundColor Green

# Dossiers à exclure d'AVG
$foldersToExclude = @(
   "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1",
   "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\cmd",
   "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\tools",
   "C:\Users\$env:USERNAME\go",
   "C:\Go",
   "$env:GOPATH",
   "$env:GOROOT",
   "$env:TEMP\go-build*",
   "$env:LOCALAPPDATA\go-build"
)

# Extensions à exclure
$extensionsToExclude = @(
   ".exe",
   ".go",
   ".mod",
   ".sum"
)

Write-Host "📁 Dossiers à exclure d'AVG :" -ForegroundColor Yellow
foreach ($folder in $foldersToExclude) {
   Write-Host "  - $folder" -ForegroundColor Cyan
}

Write-Host "📝 Extensions à excluer :" -ForegroundColor Yellow
foreach ($ext in $extensionsToExclude) {
   Write-Host "  - *$ext" -ForegroundColor Cyan
}

Write-Host "`n⚠️  INSTRUCTIONS MANUELLES REQUISES :" -ForegroundColor Red
Write-Host "1. Ouvrir AVG Antivirus" -ForegroundColor White
Write-Host "2. Aller dans Paramètres → Exceptions" -ForegroundColor White
Write-Host "3. Ajouter chaque dossier ci-dessus comme exception" -ForegroundColor White
Write-Host "4. Ajouter les extensions comme exceptions globales" -ForegroundColor White

# Tentative d'ouverture d'AVG (si possible)
try {
   Start-Process "C:\Program Files\AVG\Antivirus\AVGUI.exe" -ArgumentList "/settings"
   Write-Host "✅ AVG ouvert - Naviguez vers Paramètres → Exceptions" -ForegroundColor Green
}
catch {
   Write-Host "❌ Impossible d'ouvrir AVG automatiquement" -ForegroundColor Red
}

# Vérification des variables d'environnement Go
Write-Host "`n🔍 Variables d'environnement Go :" -ForegroundColor Yellow
Write-Host "GOROOT: $env:GOROOT"
Write-Host "GOPATH: $env:GOPATH"
Write-Host "GOCACHE: $(go env GOCACHE)"

# Création d'un fichier .avgignore local
$avgIgnoreContent = @"
# AVG Exclusions pour projet Go
*.exe
*.go
go.mod
go.sum
/cmd/
/tools/
/pkg/
"@

$avgIgnoreContent | Out-File -FilePath "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\.avgignore" -Encoding UTF8
Write-Host "✅ Fichier .avgignore créé" -ForegroundColor Green
