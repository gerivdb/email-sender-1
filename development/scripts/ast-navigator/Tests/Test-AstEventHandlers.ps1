#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour la fonction Get-AstEventHandlers.

.DESCRIPTION
    Ce script teste la fonction Get-AstEventHandlers avec différents types de gestionnaires d'événements.

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de création: 2023-05-01
#>

# Importer le module AstNavigator
$modulePath = Split-Path -Parent $PSScriptRoot
if (-not (Get-Module -Name "AstNavigator" -ErrorAction SilentlyContinue)) {
    Import-Module "$modulePath\AstNavigator.psd1" -Force -ErrorAction Stop
}

# Créer un script de test avec différents types de gestionnaires d'événements
$sampleCode = @'
# Exemple 1: Register-Event avec FileSystemWatcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = "C:\Temp"
$watcher.Filter = "*.txt"
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

# Gestionnaire d'événements pour les fichiers créés
$action = {
    $path = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $changeType : $path"
}

# Enregistrer les gestionnaires d'événements
$handlers = @()
$handlers += Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action
$handlers += Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action
$handlers += Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action {
    $oldPath = $Event.SourceEventArgs.OldFullPath
    $newPath = $Event.SourceEventArgs.FullPath
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] Renamed : $oldPath -> $newPath"
}

# Exemple 2: Add-Type avec événements
Add-Type -TypeDefinition @"
using System;

public class EventExample
{
    // Définir un délégué pour l'événement
    public delegate void StatusChangedEventHandler(object sender, EventArgs e);
    
    // Définir l'événement
    public event StatusChangedEventHandler StatusChanged;
    
    // Méthode pour déclencher l'événement
    protected virtual void OnStatusChanged(EventArgs e)
    {
        StatusChanged?.Invoke(this, e);
    }
    
    // Méthode publique pour changer le statut
    public void ChangeStatus()
    {
        Console.WriteLine("Status changing...");
        OnStatusChanged(EventArgs.Empty);
    }
}
"@ -Language CSharp

# Créer une instance de la classe
$eventObj = New-Object EventExample

# Ajouter un gestionnaire d'événements
Register-ObjectEvent -InputObject $eventObj -EventName StatusChanged -Action {
    Write-Host "Status changed event triggered!"
}

# Exemple 3: Gestionnaires WMI
# Utilisation de Register-WmiEvent
Register-WmiEvent -Query "SELECT * FROM __InstanceModificationEvent WITHIN 5 WHERE TargetInstance ISA 'Win32_Process'" -Action {
    $process = $Event.SourceEventArgs.NewEvent.TargetInstance
    Write-Host "Process modifié: $($process.Name)"
}

# Utilisation de Get-WmiObject avec événements
$query = "SELECT * FROM __InstanceCreationEvent WITHIN 5 WHERE TargetInstance ISA 'Win32_Process'"
$wmiProcess = Get-WmiObject -Query $query -EnableAllPrivileges

# Enregistrer un événement pour le résultat WMI
Register-ObjectEvent -InputObject $wmiProcess -EventName "EventArrived" -Action {
    $process = $Event.SourceEventArgs.NewEvent.TargetInstance
    Write-Host "Nouveau processus: $($process.Name)"
}

# Exemple 4: Utilisation de Get-CimInstance avec Register-CimIndicationEvent
$query = "SELECT * FROM __InstanceDeletionEvent WITHIN 5 WHERE TargetInstance ISA 'Win32_Process'"
Register-CimIndicationEvent -Query $query -Action {
    $process = $Event.SourceEventArgs.NewEvent.TargetInstance
    Write-Host "Processus terminé: $($process.Name)"
}
'@

# Analyser le code avec l'AST
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

if ($errors -and $errors.Count -gt 0) {
    Write-Warning "Erreurs d'analyse dans le script de test:"
    foreach ($error in $errors) {
        Write-Warning "  $($error.ErrorId): $($error.Message) à la ligne $($error.Extent.StartLineNumber)"
    }
}

# Test 1: Extraire tous les gestionnaires d'événements
Write-Host "Test 1: Extraire tous les gestionnaires d'événements" -ForegroundColor Cyan
$allHandlers = Get-AstEventHandlers -Ast $ast
Write-Host "  Nombre de gestionnaires trouvés: $($allHandlers.Count)" -ForegroundColor Yellow
foreach ($handler in $allHandlers) {
    Write-Host "    Type: $($handler.Type), Commande: $($handler.Command) (Lignes $($handler.StartLine)-$($handler.EndLine))" -ForegroundColor Green
}

# Test 2: Extraire uniquement les gestionnaires Register-Event
Write-Host "`nTest 2: Extraire uniquement les gestionnaires Register-Event" -ForegroundColor Cyan
$registerHandlers = Get-AstEventHandlers -Ast $ast -Type RegisterEvent
Write-Host "  Nombre de gestionnaires trouvés: $($registerHandlers.Count)" -ForegroundColor Yellow
foreach ($handler in $registerHandlers) {
    Write-Host "    Commande: $($handler.Command) (Lignes $($handler.StartLine)-$($handler.EndLine))" -ForegroundColor Green
}

# Test 3: Extraire uniquement les gestionnaires Add-Type
Write-Host "`nTest 3: Extraire uniquement les gestionnaires Add-Type" -ForegroundColor Cyan
$addTypeHandlers = Get-AstEventHandlers -Ast $ast -Type AddType
Write-Host "  Nombre de gestionnaires trouvés: $($addTypeHandlers.Count)" -ForegroundColor Yellow
foreach ($handler in $addTypeHandlers) {
    Write-Host "    Commande: $($handler.Command) (Lignes $($handler.StartLine)-$($handler.EndLine))" -ForegroundColor Green
    if ($handler.EventTypes) {
        Write-Host "      Types d'événements: $($handler.EventTypes -join ', ')" -ForegroundColor DarkGray
    }
}

# Test 4: Extraire uniquement les gestionnaires WMI
Write-Host "`nTest 4: Extraire uniquement les gestionnaires WMI" -ForegroundColor Cyan
$wmiHandlers = Get-AstEventHandlers -Ast $ast -Type WMI
Write-Host "  Nombre de gestionnaires trouvés: $($wmiHandlers.Count)" -ForegroundColor Yellow
foreach ($handler in $wmiHandlers) {
    Write-Host "    Commande: $($handler.Command) (Lignes $($handler.StartLine)-$($handler.EndLine))" -ForegroundColor Green
}

# Test 5: Extraire les gestionnaires avec contenu et blocs de script
Write-Host "`nTest 5: Extraire les gestionnaires avec contenu et blocs de script" -ForegroundColor Cyan
$detailedHandlers = Get-AstEventHandlers -Ast $ast -IncludeContent -IncludeScriptBlocks
Write-Host "  Nombre de gestionnaires trouvés: $($detailedHandlers.Count)" -ForegroundColor Yellow
foreach ($handler in $detailedHandlers) {
    Write-Host "    Type: $($handler.Type), Commande: $($handler.Command) (Lignes $($handler.StartLine)-$($handler.EndLine))" -ForegroundColor Green
    
    if ($handler.ScriptBlock) {
        Write-Host "      Bloc de script: Lignes $($handler.ScriptBlock.StartLine)-$($handler.ScriptBlock.EndLine)" -ForegroundColor DarkGray
        Write-Host "      Variables utilisées: $($handler.ScriptBlock.Variables -join ', ')" -ForegroundColor DarkGray
        Write-Host "      Commandes utilisées: $($handler.ScriptBlock.Commands -join ', ')" -ForegroundColor DarkGray
    }
}

# Résumé des tests
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "  Total des gestionnaires trouvés: $($allHandlers.Count)" -ForegroundColor Yellow
Write-Host "  Gestionnaires Register-Event: $($registerHandlers.Count)" -ForegroundColor Yellow
Write-Host "  Gestionnaires Add-Type: $($addTypeHandlers.Count)" -ForegroundColor Yellow
Write-Host "  Gestionnaires WMI: $($wmiHandlers.Count)" -ForegroundColor Yellow

# Vérification des résultats attendus
$expectedCounts = @{
    All = 8  # Nombre total attendu
    RegisterEvent = 4  # Register-ObjectEvent x 3 + Register-CimIndicationEvent
    AddType = 1  # Add-Type avec événement
    WMI = 3  # Register-WmiEvent + Get-WmiObject + Register-CimIndicationEvent
}

$success = $true
if ($allHandlers.Count -ne $expectedCounts.All) {
    Write-Host "  ÉCHEC: Nombre total de gestionnaires incorrect. Attendu: $($expectedCounts.All), Trouvé: $($allHandlers.Count)" -ForegroundColor Red
    $success = $false
}
if ($registerHandlers.Count -ne $expectedCounts.RegisterEvent) {
    Write-Host "  ÉCHEC: Nombre de gestionnaires Register-Event incorrect. Attendu: $($expectedCounts.RegisterEvent), Trouvé: $($registerHandlers.Count)" -ForegroundColor Red
    $success = $false
}
if ($addTypeHandlers.Count -ne $expectedCounts.AddType) {
    Write-Host "  ÉCHEC: Nombre de gestionnaires Add-Type incorrect. Attendu: $($expectedCounts.AddType), Trouvé: $($addTypeHandlers.Count)" -ForegroundColor Red
    $success = $false
}
if ($wmiHandlers.Count -ne $expectedCounts.WMI) {
    Write-Host "  ÉCHEC: Nombre de gestionnaires WMI incorrect. Attendu: $($expectedCounts.WMI), Trouvé: $($wmiHandlers.Count)" -ForegroundColor Red
    $success = $false
}

if ($success) {
    Write-Host "`nTous les tests ont réussi!" -ForegroundColor Green
} else {
    Write-Host "`nCertains tests ont échoué. Vérifiez les résultats ci-dessus." -ForegroundColor Red
}
