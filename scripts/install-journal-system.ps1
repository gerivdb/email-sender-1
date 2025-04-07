# Script PowerShell pour lancer l'installation complÃ¨te du systÃ¨me de journal de bord

# VÃ©rifier si le script est exÃ©cutÃ© en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "AVERTISSEMENT: Ce script n'est pas exÃ©cutÃ© en tant qu'administrateur." -ForegroundColor Yellow
    Write-Host "Certaines fonctionnalitÃ©s nÃ©cessitant des privilÃ¨ges d'administrateur seront ignorÃ©es." -ForegroundColor Yellow
    Write-Host ""
    
    $continue = Read-Host "Voulez-vous continuer avec une installation partielle? (O/N)"
    if ($continue -ne "O" -and $continue -ne "o") {
        Write-Host "Installation annulÃ©e." -ForegroundColor Red
        exit
    }
}

# ExÃ©cuter le script d'installation
& ".\scripts\cmd\install-journal-system.ps1"

# Afficher un message de conclusion
Write-Host ""
Write-Host "Installation terminÃ©e!" -ForegroundColor Green
Write-Host ""
Write-Host "Pour plus d'informations sur l'utilisation du systÃ¨me, consultez:"
Write-Host "docs/journal_de_bord/README.md"
Write-Host ""
Write-Host "Pour dÃ©marrer l'interface web:"
Write-Host ".\scripts\cmd\start-journal-web.ps1"
