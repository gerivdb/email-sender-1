# Script PowerShell pour lancer l'installation complète du système de journal de bord

# Vérifier si le script est exécuté en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "AVERTISSEMENT: Ce script n'est pas exécuté en tant qu'administrateur." -ForegroundColor Yellow
    Write-Host "Certaines fonctionnalités nécessitant des privilèges d'administrateur seront ignorées." -ForegroundColor Yellow
    Write-Host ""
    
    $continue = Read-Host "Voulez-vous continuer avec une installation partielle? (O/N)"
    if ($continue -ne "O" -and $continue -ne "o") {
        Write-Host "Installation annulée." -ForegroundColor Red
        exit
    }
}

# Exécuter le script d'installation
& ".\scripts\cmd\install-journal-system.ps1"

# Afficher un message de conclusion
Write-Host ""
Write-Host "Installation terminée!" -ForegroundColor Green
Write-Host ""
Write-Host "Pour plus d'informations sur l'utilisation du système, consultez:"
Write-Host "docs/journal_de_bord/README.md"
Write-Host ""
Write-Host "Pour démarrer l'interface web:"
Write-Host ".\scripts\cmd\start-journal-web.ps1"
