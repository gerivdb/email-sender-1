# Guide des Verbes Approuvés PowerShell

*Version 1.0 - 2025-05-15*

Ce document fournit une référence complète des verbes approuvés PowerShell et des bonnes pratiques pour leur utilisation dans le projet EMAIL_SENDER_1.

## 📚 Table des matières

- [Introduction](#introduction)

- [Importance des verbes approuvés](#importance-des-verbes-approuvés)

- [Liste complète des verbes approuvés](#liste-complète-des-verbes-approuvés)

- [Verbes par catégorie](#verbes-par-catégorie)

- [Correspondances communes](#correspondances-communes)

- [Bonnes pratiques](#bonnes-pratiques)

- [Exemples pratiques](#exemples-pratiques)

- [Outils de validation](#outils-de-validation)

## 🎯 Introduction

PowerShell utilise un système de verbes approuvés pour maintenir la cohérence et la prévisibilité des noms de cmdlets. Cette convention suit le format `Verbe-Nom` où le verbe décrit l'action et le nom identifie la ressource ou l'objet sur lequel l'action est effectuée.

## ⚠️ Importance des verbes approuvés

### Pourquoi utiliser des verbes approuvés ?

1. **Cohérence** : Facilite la prédiction du nom des cmdlets
2. **Lisibilité** : Améliore la compréhension du code
3. **Maintenabilité** : Simplifie la maintenance et l'évolution du code
4. **Standards** : Respecte les conventions PowerShell officielles
5. **Interopérabilité** : Facilite l'intégration avec d'autres modules

### Conséquences de l'utilisation de verbes non approuvés

- **Avertissements PSScriptAnalyzer** : La règle `PSUseApprovedVerbs` génère des avertissements
- **Non-conformité** : Le code ne respecte pas les standards PowerShell
- **Confusion** : Les utilisateurs peuvent avoir du mal à deviner les noms de cmdlets
- **Problèmes d'importation** : Certains environnements peuvent rejeter les modules avec des verbes non approuvés

## 📋 Liste complète des verbes approuvés

### Verbes Common (Courants)

Les verbes les plus fréquemment utilisés dans PowerShell :

| Verbe | Description | Exemple d'usage |
|-------|-------------|-----------------|
| `Add` | Ajouter une ressource à un conteneur | `Add-EmailAttachment` |
| `Clear` | Supprimer tout le contenu d'un conteneur | `Clear-EmailQueue` |
| `Close` | Fermer une ressource | `Close-EmailConnection` |
| `Copy` | Copier une ressource | `Copy-EmailTemplate` |
| `Enter` | Entrer dans un environnement | `Enter-EmailSession` |
| `Exit` | Quitter un environnement | `Exit-EmailSession` |
| `Find` | Rechercher une ressource | `Find-EmailTemplate` |
| `Format` | Formater une ressource | `Format-EmailBody` |
| `Get` | Récupérer une ressource | `Get-EmailConfig` |
| `Hide` | Masquer une ressource | `Hide-EmailPassword` |
| `Join` | Combiner des ressources | `Join-EmailParts` |
| `Lock` | Verrouiller une ressource | `Lock-EmailAccount` |
| `Move` | Déplacer une ressource | `Move-EmailToArchive` |
| `New` | Créer une nouvelle ressource | `New-EmailTemplate` |
| `Open` | Ouvrir une ressource | `Open-EmailConnection` |
| `Optimize` | Optimiser une ressource | `Optimize-EmailDelivery` |
| `Pop` | Retirer un élément d'une pile | `Pop-EmailFromQueue` |
| `Push` | Ajouter un élément à une pile | `Push-EmailToQueue` |
| `Redo` | Refaire une action annulée | `Redo-EmailSend` |
| `Remove` | Supprimer une ressource | `Remove-EmailAttachment` |
| `Rename` | Renommer une ressource | `Rename-EmailTemplate` |
| `Reset` | Remettre à l'état initial | `Reset-EmailConfig` |
| `Resize` | Changer la taille d'une ressource | `Resize-EmailImage` |
| `Search` | Chercher dans une ressource | `Search-EmailLogs` |
| `Select` | Sélectionner des éléments | `Select-EmailRecipients` |
| `Set` | Définir ou modifier une propriété | `Set-EmailConfig` |
| `Show` | Afficher une ressource | `Show-EmailStatus` |
| `Skip` | Ignorer une ressource | `Skip-EmailValidation` |
| `Split` | Diviser une ressource | `Split-EmailList` |
| `Step` | Exécuter une étape | `Step-EmailWorkflow` |
| `Switch` | Changer d'état | `Switch-EmailProvider` |
| `Undo` | Annuler une action | `Undo-EmailSend` |
| `Unlock` | Déverrouiller une ressource | `Unlock-EmailAccount` |
| `Watch` | Surveiller une ressource | `Watch-EmailQueue` |

### Verbes Communications

Pour les opérations de communication :

| Verbe | Description | Exemple d'usage |
|-------|-------------|-----------------|
| `Connect` | Établir une connexion | `Connect-EmailServer` |
| `Disconnect` | Fermer une connexion | `Disconnect-EmailServer` |
| `Read` | Lire des données | `Read-EmailMessage` |
| `Receive` | Recevoir des données | `Receive-Email` |
| `Send` | Envoyer des données | `Send-Email` |
| `Write` | Écrire des données | `Write-EmailLog` |

### Verbes Data (Données)

Pour la manipulation des données :

| Verbe | Description | Exemple d'usage |
|-------|-------------|-----------------|
| `Backup` | Sauvegarder des données | `Backup-EmailDatabase` |
| `Checkpoint` | Créer un point de contrôle | `Checkpoint-EmailTransaction` |
| `Compare` | Comparer des objets | `Compare-EmailTemplates` |
| `Compress` | Compresser des données | `Compress-EmailArchive` |
| `Convert` | Convertir entre formats | `Convert-EmailToHtml` |
| `ConvertFrom` | Convertir depuis un format | `ConvertFrom-EmailJson` |
| `ConvertTo` | Convertir vers un format | `ConvertTo-EmailXml` |
| `Dismount` | Démonter un volume | `Dismount-EmailStorage` |
| `Edit` | Modifier des données | `Edit-EmailTemplate` |
| `Expand` | Décompresser ou étendre | `Expand-EmailArchive` |
| `Export` | Exporter des données | `Export-EmailContacts` |
| `Group` | Grouper des objets | `Group-EmailsByDate` |
| `Import` | Importer des données | `Import-EmailContacts` |
| `Initialize` | Initialiser une ressource | `Initialize-EmailDatabase` |
| `Limit` | Limiter une ressource | `Limit-EmailSendRate` |
| `Merge` | Fusionner des objets | `Merge-EmailLists` |
| `Mount` | Monter un volume | `Mount-EmailStorage` |
| `Out` | Envoyer des données vers une sortie | `Out-EmailReport` |
| `Publish` | Publier des données | `Publish-EmailTemplate` |
| `Restore` | Restaurer des données | `Restore-EmailBackup` |
| `Save` | Sauvegarder dans un fichier | `Save-EmailDraft` |
| `Sync` | Synchroniser des données | `Sync-EmailAccounts` |
| `Unpublish` | Dépublier des données | `Unpublish-EmailTemplate` |
| `Update` | Mettre à jour des données | `Update-EmailTemplate` |

### Verbes Diagnostic

Pour le diagnostic et le débogage :

| Verbe | Description | Exemple d'usage |
|-------|-------------|-----------------|
| `Debug` | Déboguer une ressource | `Debug-EmailDelivery` |
| `Measure` | Mesurer une ressource | `Measure-EmailPerformance` |
| `Ping` | Tester la connectivité | `Ping-EmailServer` |
| `Repair` | Réparer une ressource | `Repair-EmailQueue` |
| `Resolve` | Résoudre une ressource | `Resolve-EmailAddress` |
| `Test` | Tester une ressource | `Test-EmailConnection` |
| `Trace` | Tracer l'exécution | `Trace-EmailDelivery` |

### Verbes Lifecycle (Cycle de vie)

Pour la gestion du cycle de vie :

| Verbe | Description | Exemple d'usage |
|-------|-------------|-----------------|
| `Approve` | Approuver une ressource | `Approve-EmailTemplate` |
| `Assert` | Affirmer une condition | `Assert-EmailValid` |
| `Complete` | Marquer comme terminé | `Complete-EmailSend` |
| `Confirm` | Confirmer une action | `Confirm-EmailDelivery` |
| `Deny` | Refuser une ressource | `Deny-EmailAccess` |
| `Disable` | Désactiver une ressource | `Disable-EmailNotifications` |
| `Enable` | Activer une ressource | `Enable-EmailNotifications` |
| `Install` | Installer une ressource | `Install-EmailModule` |
| `Invoke` | Exécuter une action | `Invoke-EmailWorkflow` |
| `Register` | Enregistrer une ressource | `Register-EmailProvider` |
| `Request` | Demander une ressource | `Request-EmailApproval` |
| `Restart` | Redémarrer une ressource | `Restart-EmailService` |
| `Resume` | Reprendre une ressource | `Resume-EmailQueue` |
| `Start` | Démarrer une ressource | `Start-EmailMonitoring` |
| `Stop` | Arrêter une ressource | `Stop-EmailMonitoring` |
| `Submit` | Soumettre une ressource | `Submit-EmailForReview` |
| `Suspend` | Suspendre une ressource | `Suspend-EmailQueue` |
| `Uninstall` | Désinstaller une ressource | `Uninstall-EmailModule` |
| `Unregister` | Désenregistrer une ressource | `Unregister-EmailProvider` |
| `Wait` | Attendre une condition | `Wait-EmailDelivery` |

### Verbes Security (Sécurité)

Pour les opérations de sécurité :

| Verbe | Description | Exemple d'usage |
|-------|-------------|-----------------|
| `Block` | Bloquer une ressource | `Block-EmailAddress` |
| `Grant` | Accorder des permissions | `Grant-EmailAccess` |
| `Protect` | Protéger une ressource | `Protect-EmailData` |
| `Revoke` | Révoquer des permissions | `Revoke-EmailAccess` |
| `Unblock` | Débloquer une ressource | `Unblock-EmailAddress` |
| `Unprotect` | Déprotéger une ressource | `Unprotect-EmailData` |

### Verbes Other (Autres)

Verbes spéciaux :

| Verbe | Description | Exemple d'usage |
|-------|-------------|-----------------|
| `Use` | Utiliser une ressource | `Use-EmailTemplate` |

## 🔄 Correspondances communes

Voici les correspondances entre verbes non approuvés couramment utilisés et leurs équivalents approuvés :

| ❌ Verbe non approuvé | ✅ Verbe approuvé | Contexte |
|----------------------|-------------------|----------|
| `Analyze` | `Test` ou `Measure` | Analyse/diagnostic |
| `Build` | `New` | Création d'objets |
| `Calculate` | `Measure` | Calculs |
| `Check` | `Test` | Vérifications |
| `Create` | `New` | Création |
| `Delete` | `Remove` | Suppression |
| `Deploy` | `Install` ou `Publish` | Déploiement |
| `Destroy` | `Remove` | Destruction |
| `Execute` | `Invoke` | Exécution |
| `Extract` | `Export` ou `Get` | Extraction |
| `Fix` | `Repair` | Réparation |
| `Generate` | `New` | Génération |
| `Kill` | `Stop` | Arrêt forcé |
| `Launch` | `Start` | Lancement |
| `Load` | `Import` | Chargement |
| `Make` | `New` | Création |
| `Modify` | `Set` ou `Edit` | Modification |
| `Retrieve` | `Get` | Récupération |
| `Run` | `Start` ou `Invoke` | Exécution |
| `Validate` | `Test` | Validation |
| `Verify` | `Test` | Vérification |

## ✅ Bonnes pratiques

### 1. Choix du verbe approprié

```powershell
# ✅ Bon

function Get-EmailTemplate { ... }
function Send-NotificationEmail { ... }
function Test-EmailAddress { ... }

# ❌ Mauvais

function Retrieve-EmailTemplate { ... }
function Transmit-NotificationEmail { ... }
function Validate-EmailAddress { ... }
```plaintext
### 2. Cohérence dans le module

```powershell
# ✅ Bon - Cohérence dans les opérations CRUD

function Get-EmailTemplate { ... }
function New-EmailTemplate { ... }
function Set-EmailTemplate { ... }
function Remove-EmailTemplate { ... }

# ❌ Mauvais - Incohérence

function Get-EmailTemplate { ... }
function Create-EmailTemplate { ... }
function Modify-EmailTemplate { ... }
function Delete-EmailTemplate { ... }
```plaintext
### 3. Utilisation des groupes de verbes

Regroupez les fonctions logiquement selon leur groupe de verbes :

```powershell
# Groupe Communications

Connect-EmailServer
Send-Email
Receive-Email
Disconnect-EmailServer

# Groupe Data

Import-EmailContacts
Export-EmailReport
Convert-EmailToHtml
Backup-EmailDatabase

# Groupe Diagnostic

Test-EmailConnection
Debug-EmailDelivery
Measure-EmailPerformance
Trace-EmailFlow
```plaintext
### 4. Conventions de nommage

```powershell
# ✅ Format correct : Verbe-Nom (PascalCase)

function Send-BulkEmail { ... }
function Get-EmailStatistics { ... }
function New-EmailTemplate { ... }

# ❌ Format incorrect

function sendBulkEmail { ... }          # camelCase

function Get_EmailStatistics { ... }    # underscore

function new-emailtemplate { ... }      # lowercase

```plaintext
## 🛠️ Exemples pratiques

### Exemple complet d'un module Email avec verbes approuvés

```powershell
#Requires -Version 5.1

<#

.SYNOPSIS
    Module de gestion des emails avec verbes approuvés PowerShell.

.DESCRIPTION
    Ce module démontre l'utilisation correcte des verbes approuvés PowerShell
    pour toutes les opérations liées aux emails.
#>

# Verbes Common

function Get-EmailTemplate {
    [CmdletBinding()]
    param([string]$Name)
    # Récupérer un modèle d'email

}

function New-EmailTemplate {
    [CmdletBinding()]
    param([string]$Name, [string]$Content)
    # Créer un nouveau modèle d'email

}

function Set-EmailTemplate {
    [CmdletBinding()]
    param([string]$Name, [string]$Content)
    # Modifier un modèle d'email existant

}

function Remove-EmailTemplate {
    [CmdletBinding()]
    param([string]$Name)
    # Supprimer un modèle d'email

}

function Copy-EmailTemplate {
    [CmdletBinding()]
    param([string]$Source, [string]$Destination)
    # Copier un modèle d'email

}

function Find-EmailTemplate {
    [CmdletBinding()]
    param([string]$Pattern)
    # Rechercher des modèles d'email

}

# Verbes Communications

function Connect-EmailServer {
    [CmdletBinding()]
    param([string]$Server, [int]$Port = 587)
    # Se connecter au serveur email

}

function Send-Email {
    [CmdletBinding()]
    param(
        [string]$To,
        [string]$Subject,
        [string]$Body,
        [string[]]$Attachments
    )
    # Envoyer un email

}

function Receive-Email {
    [CmdletBinding()]
    param([string]$Folder = "INBOX")
    # Recevoir des emails

}

function Disconnect-EmailServer {
    [CmdletBinding()]
    param()
    # Se déconnecter du serveur email

}

# Verbes Data

function Import-EmailContacts {
    [CmdletBinding()]
    param([string]$Path)
    # Importer des contacts depuis un fichier

}

function Export-EmailReport {
    [CmdletBinding()]
    param([string]$Path, [datetime]$StartDate, [datetime]$EndDate)
    # Exporter un rapport d'emails

}

function Convert-EmailToHtml {
    [CmdletBinding()]
    param([string]$TextEmail)
    # Convertir un email texte en HTML

}

function Backup-EmailDatabase {
    [CmdletBinding()]
    param([string]$BackupPath)
    # Sauvegarder la base de données des emails

}

function Restore-EmailDatabase {
    [CmdletBinding()]
    param([string]$BackupPath)
    # Restaurer la base de données des emails

}

# Verbes Diagnostic

function Test-EmailConnection {
    [CmdletBinding()]
    param([string]$Server, [int]$Port = 587)
    # Tester la connexion au serveur email

}

function Test-EmailAddress {
    [CmdletBinding()]
    param([string]$Email)
    # Valider une adresse email

}

function Measure-EmailPerformance {
    [CmdletBinding()]
    param([datetime]$StartDate, [datetime]$EndDate)
    # Mesurer les performances d'envoi d'emails

}

function Debug-EmailDelivery {
    [CmdletBinding()]
    param([string]$MessageId)
    # Déboguer la livraison d'un email

}

function Repair-EmailQueue {
    [CmdletBinding()]
    param()
    # Réparer la file d'attente des emails

}

# Verbes Lifecycle

function Start-EmailMonitoring {
    [CmdletBinding()]
    param([int]$IntervalSeconds = 60)
    # Démarrer la surveillance des emails

}

function Stop-EmailMonitoring {
    [CmdletBinding()]
    param()
    # Arrêter la surveillance des emails

}

function Enable-EmailNotifications {
    [CmdletBinding()]
    param([string[]]$Types)
    # Activer les notifications email

}

function Disable-EmailNotifications {
    [CmdletBinding()]
    param([string[]]$Types)
    # Désactiver les notifications email

}

function Invoke-EmailWorkflow {
    [CmdletBinding()]
    param([string]$WorkflowName, [hashtable]$Parameters)
    # Exécuter un workflow d'email

}

function Register-EmailProvider {
    [CmdletBinding()]
    param([string]$ProviderName, [hashtable]$Configuration)
    # Enregistrer un fournisseur d'email

}

# Verbes Security

function Block-EmailAddress {
    [CmdletBinding()]
    param([string[]]$Addresses)
    # Bloquer des adresses email

}

function Unblock-EmailAddress {
    [CmdletBinding()]
    param([string[]]$Addresses)
    # Débloquer des adresses email

}

function Grant-EmailAccess {
    [CmdletBinding()]
    param([string]$User, [string[]]$Permissions)
    # Accorder l'accès aux emails

}

function Revoke-EmailAccess {
    [CmdletBinding()]
    param([string]$User, [string[]]$Permissions)
    # Révoquer l'accès aux emails

}

function Protect-EmailData {
    [CmdletBinding()]
    param([string]$EncryptionKey)
    # Protéger les données d'email

}
```plaintext
## 🔧 Outils de validation

### 1. PSScriptAnalyzer

Utilisez PSScriptAnalyzer pour détecter l'utilisation de verbes non approuvés :

```powershell
# Installer PSScriptAnalyzer

Install-Module -Name PSScriptAnalyzer -Scope CurrentUser

# Analyser un script

Invoke-ScriptAnalyzer -Path "MonScript.ps1" -IncludeRule PSUseApprovedVerbs

# Analyser tout un dossier

Get-ChildItem -Path ".\MonModule" -Filter "*.ps1" -Recurse | 
    Invoke-ScriptAnalyzer -IncludeRule PSUseApprovedVerbs
```plaintext
### 2. Vérification automatique

Script pour vérifier les verbes non approuvés :

```powershell
function Test-ApprovedVerbs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    $approvedVerbs = (Get-Verb).Verb
    $issues = @()
    
    Get-ChildItem -Path $Path -Filter "*.ps1" -Recurse | ForEach-Object {
        $content = Get-Content -Path $_.FullName -Raw
        $functions = [regex]::Matches($content, 'function\s+([A-Z][a-z]+-\w+)')
        
        foreach ($function in $functions) {
            $functionName = $function.Groups[1].Value
            $verb = $functionName -split '-' | Select-Object -First 1
            
            if ($verb -notin $approvedVerbs) {
                $issues += [PSCustomObject]@{
                    File = $_.FullName
                    Function = $functionName
                    Verb = $verb
                    SuggestedVerb = Get-VerbSuggestion -Verb $verb
                }
            }
        }
    }
    
    return $issues
}

function Get-VerbSuggestion {
    param([string]$Verb)
    
    $suggestions = @{
        'Analyze' = 'Test'
        'Build' = 'New'
        'Check' = 'Test'
        'Create' = 'New'
        'Delete' = 'Remove'
        'Execute' = 'Invoke'
        'Fix' = 'Repair'
        'Generate' = 'New'
        'Validate' = 'Test'
        'Verify' = 'Test'
    }
    
    return $suggestions[$Verb] ?? "Consultez Get-Verb"
}
```plaintext
### 3. Intégration CI/CD

Exemple de validation dans un pipeline CI/CD :

```yaml
# .github/workflows/powershell-validation.yml

name: PowerShell Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: windows-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Install PSScriptAnalyzer
      shell: pwsh
      run: Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
    
    - name: Run PSScriptAnalyzer
      shell: pwsh
      run: |
        $results = Invoke-ScriptAnalyzer -Path . -Recurse -IncludeRule PSUseApprovedVerbs
        if ($results) {
          $results | Format-Table
          exit 1
        }
```plaintext
## 📚 Ressources supplémentaires

### Documentation officielle

- [PowerShell Approved Verbs](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands)
- [PowerShell Cmdlet Development Guidelines](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-development-guidelines)

### Commandes utiles

```powershell
# Obtenir tous les verbes approuvés

Get-Verb

# Obtenir les verbes par groupe

Get-Verb | Group-Object Group

# Rechercher un verbe spécifique

Get-Verb | Where-Object Verb -like "*Send*"

# Obtenir les verbes d'un groupe spécifique

Get-Verb | Where-Object Group -eq "Communications"
```plaintext
### Vérification rapide

```powershell
# Vérifier si un verbe est approuvé

function Test-VerbApproved {
    param([string]$Verb)
    $Verb -in (Get-Verb).Verb
}

# Exemples

Test-VerbApproved "Get"      # True

Test-VerbApproved "Create"   # False

Test-VerbApproved "New"      # True

```plaintext
---

*Ce document est maintenu dans le cadre du projet EMAIL_SENDER_1. Pour toute question ou suggestion d'amélioration, veuillez consulter l'équipe de développement.*
