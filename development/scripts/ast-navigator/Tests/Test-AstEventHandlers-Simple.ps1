# Script de test simple pour la fonction Get-AstEventHandlers

# Importer le module AstNavigator
$modulePath = Split-Path -Parent $PSScriptRoot
Import-Module "$modulePath\AstNavigator.psd1" -Force

# CrÃ©er un script de test simple
$sampleCode = @'
# Exemple de Register-Event
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = "C:\Temp"
$watcher.Filter = "*.txt"
$watcher.EnableRaisingEvents = $true

# Gestionnaire d'Ã©vÃ©nements
$action = { Write-Host "Fichier modifiÃ©: $($Event.SourceEventArgs.FullPath)" }

# Enregistrer le gestionnaire
Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action
'@

# Analyser le code avec l'AST
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

# Tester la fonction
Write-Host "Test de Get-AstEventHandlers:" -ForegroundColor Cyan
$handlers = Get-AstEventHandlers -Ast $ast
Write-Host "Nombre de gestionnaires trouvÃ©s: $($handlers.Count)" -ForegroundColor Yellow

foreach ($handler in $handlers) {
    Write-Host "Type: $($handler.Type), Commande: $($handler.Command) (Lignes $($handler.StartLine)-$($handler.EndLine))" -ForegroundColor Green
}

# Tester avec les options
Write-Host "`nTest avec IncludeContent et IncludeScriptBlocks:" -ForegroundColor Cyan
$detailedHandlers = Get-AstEventHandlers -Ast $ast -IncludeContent -IncludeScriptBlocks
foreach ($handler in $detailedHandlers) {
    Write-Host "Type: $($handler.Type), Commande: $($handler.Command)" -ForegroundColor Green
    if ($handler.ScriptBlock) {
        Write-Host "  Script Block: $($handler.ScriptBlock.Content)" -ForegroundColor DarkGray
    }
}
