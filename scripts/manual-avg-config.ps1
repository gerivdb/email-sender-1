# Instructions pour configuration manuelle AVG
# AUTOMATIQUEMENT GÉNÉRÉ - 06/18/2025 09:48:50

Write-Host "🛡️ Configuration manuelle AVG requise" -ForegroundColor Yellow
Write-Host ""
Write-Host "📁 Dossiers à exclure :" -ForegroundColor Green
Write-Host '  - D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1' -ForegroundColor Cyan Write-Host '  - D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\cmd' -ForegroundColor Cyan Write-Host '  - D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\pkg' -ForegroundColor Cyan Write-Host '  - D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\tools' -ForegroundColor Cyan Write-Host '  - D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development' -ForegroundColor Cyan Write-Host '  - D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\logs' -ForegroundColor Cyan Write-Host '  - C:\Users\user\AppData\Local\Temp\go-build*' -ForegroundColor Cyan Write-Host '  - C:\Users\user\AppData\Local\go-build' -ForegroundColor Cyan Write-Host '  - C:\Users\user\AppData\Local\go-build' -ForegroundColor Cyan

Write-Host ""
Write-Host "📝 Extensions à exclure :" -ForegroundColor Green  
Write-Host '  - *.exe' -ForegroundColor Cyan Write-Host '  - *.go' -ForegroundColor Cyan Write-Host '  - *.mod' -ForegroundColor Cyan Write-Host '  - *.sum' -ForegroundColor Cyan Write-Host '  - *.dll' -ForegroundColor Cyan Write-Host '  - *.a' -ForegroundColor Cyan Write-Host '  - *.obj' -ForegroundColor Cyan Write-Host '  - *.bin' -ForegroundColor Cyan Write-Host '  - *.out' -ForegroundColor Cyan Write-Host '  - *.ps1' -ForegroundColor Cyan Write-Host '  - *.bat' -ForegroundColor Cyan Write-Host '  - *.cmd' -ForegroundColor Cyan Write-Host '  - *.py' -ForegroundColor Cyan Write-Host '  - *.pyc' -ForegroundColor Cyan Write-Host '  - *.pyo' -ForegroundColor Cyan Write-Host '  - *.pyd' -ForegroundColor Cyan Write-Host '  - *.js' -ForegroundColor Cyan Write-Host '  - *.ts' -ForegroundColor Cyan Write-Host '  - *.json' -ForegroundColor Cyan Write-Host '  - *.yaml' -ForegroundColor Cyan Write-Host '  - *.yml' -ForegroundColor Cyan Write-Host '  - *.toml' -ForegroundColor Cyan Write-Host '  - *.ini' -ForegroundColor Cyan

Write-Host ""
Write-Host "⚙️ Processus à exclure :" -ForegroundColor Green
Write-Host '  - go.exe' -ForegroundColor Cyan Write-Host '  - gofmt.exe' -ForegroundColor Cyan Write-Host '  - golangci-lint.exe' -ForegroundColor Cyan Write-Host '  - dlv.exe' -ForegroundColor Cyan Write-Host '  - python.exe' -ForegroundColor Cyan Write-Host '  - pythonw.exe' -ForegroundColor Cyan Write-Host '  - node.exe' -ForegroundColor Cyan Write-Host '  - npm.exe' -ForegroundColor Cyan Write-Host '  - code.exe' -ForegroundColor Cyan Write-Host '  - Code.exe' -ForegroundColor Cyan Write-Host '  - powershell.exe' -ForegroundColor Cyan Write-Host '  - pwsh.exe' -ForegroundColor Cyan

Write-Host ""
Write-Host "📋 ÉTAPES :" -ForegroundColor Yellow
Write-Host "1. Ouvrir AVG Antivirus"
Write-Host "2. Menu → Paramètres → Général → Exceptions"
Write-Host "3. Ajouter chaque élément ci-dessus"
Write-Host "4. Redémarrer le système"

# Ouvrir AVG si possible
try {
    Start-Process "C:\Program Files\AVG\Antivirus\AVGUI.exe"
}
catch {
    Write-Host "❌ Ouvrir manuellement AVG depuis le menu Démarrer"
}
