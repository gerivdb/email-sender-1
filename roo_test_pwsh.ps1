# Roo Test PowerShell Script
# Vérifie l’environnement, exécute une commande simple, journalise et retourne un code

$logPath = "roo_test_pwsh.log"
"Début du test PowerShell Roo" | Out-File -FilePath $logPath
"Date : $(Get-Date)" | Out-File -FilePath $logPath -Append

# Test d’une commande simple
try {
    $result = Get-Process | Select-Object -First 1
    "Process test OK : $($result.ProcessName)" | Out-File -FilePath $logPath -Append
    exit 0
} catch {
    "Erreur : $($_.Exception.Message)" | Out-File -FilePath $logPath -Append
    exit 1
}