<#
.SYNOPSIS
Corrige l'association des fichiers .ps1 avec VS Code
#>

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs
    exit
}

$vscodePath = "C:\Users\user\AppData\Local\Programs\Microsoft VS Code\bin\code.cmd"
$command = "`"$vscodePath`" `"%1`""

try {
    reg add "HKEY_CLASSES_ROOT\Microsoft.PowerShellScript.1\shell\open\command" /ve /d "$command" /f
    Write-Host "Association .ps1 corrigÃ©e avec succÃ¨s" -ForegroundColor Green
    Write-Host "RedÃ©marrez l'explorateur de fichiers pour voir les changements"
} catch {
    Write-Host "Erreur lors de la modification du registre: $_" -ForegroundColor Red
}
