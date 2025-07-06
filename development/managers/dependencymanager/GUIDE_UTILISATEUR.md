# Guide d'utilisation du Gestionnaire de Dépendances Go

## Vue d'ensemble

Le gestionnaire de dépendances Go pour EMAIL_SENDER_1 est un outil complet qui permet de gérer facilement les dépendances Go de votre projet. Il offre des fonctionnalités avancées comme la journalisation, la sauvegarde automatique, et l'audit de sécurité.

## Installation

### Installation automatique (Recommandée)

```powershell
# Depuis la racine du projet

.\development\managers\dependency-manager\scripts\install-dependency-manager.ps1
```plaintext
### Installation manuelle

1. Naviguez vers le dossier du gestionnaire :
```powershell
cd .\development\managers\dependency-manager
```plaintext
2. Compilez le gestionnaire :
```powershell
go build -o dependency-manager.exe modules\dependency_manager.go
```plaintext
## Utilisation

### Via l'exécutable direct

```powershell
# Lister toutes les dépendances

.\development\managers\dependency-manager\dependency-manager.exe list

# Lister avec format JSON

.\development\managers\dependency-manager\dependency-manager.exe list --json

# Ajouter une dépendance

.\development\managers\dependency-manager\dependency-manager.exe add --module "github.com/pkg/errors" --version "v0.9.1"

# Supprimer une dépendance

.\development\managers\dependency-manager\dependency-manager.exe remove --module "github.com/pkg/errors"

# Mettre à jour une dépendance

.\development\managers\dependency-manager\dependency-manager.exe update --module "github.com/gorilla/mux"

# Audit de sécurité

.\development\managers\dependency-manager\dependency-manager.exe audit

# Nettoyage des dépendances inutilisées

.\development\managers\dependency-manager\dependency-manager.exe cleanup
```plaintext
### Via le script PowerShell

```powershell
# Lister toutes les dépendances

.\development\managers\dependency-manager\scripts\dependency-manager.ps1 -Action list

# Ajouter une dépendance avec confirmation

.\development\managers\dependency-manager\scripts\dependency-manager.ps1 -Action add -Module "github.com/pkg/errors" -Version "v0.9.1"

# Supprimer une dépendance sans confirmation

.\development\managers\dependency-manager\scripts\dependency-manager.ps1 -Action remove -Module "github.com/pkg/errors" -Force

# Mettre à jour vers la dernière version

.\development\managers\dependency-manager\scripts\dependency-manager.ps1 -Action update -Module "github.com/gorilla/mux"

# Audit complet

.\development\managers\dependency-manager\scripts\dependency-manager.ps1 -Action audit

# Nettoyage automatique

.\development\managers\dependency-manager\scripts\dependency-manager.ps1 -Action cleanup -Force
```plaintext
## Commandes disponibles

### `list`

Liste toutes les dépendances du projet.

**Options :**
- `--json` : Affiche la sortie au format JSON

**Exemple :**
```powershell
.\dependency-manager.exe list --json
```plaintext
### `add`

Ajoute une nouvelle dépendance au projet.

**Paramètres obligatoires :**
- `--module` : Le nom du module Go (ex: github.com/pkg/errors)

**Paramètres optionnels :**
- `--version` : La version à installer (défaut: "latest")

**Exemple :**
```powershell
.\dependency-manager.exe add --module "github.com/fatih/color" --version "v1.18.0"
```plaintext
### `remove`

Supprime une dépendance du projet.

**Paramètres obligatoires :**
- `--module` : Le nom du module à supprimer

**Exemple :**
```powershell
.\dependency-manager.exe remove --module "github.com/pkg/errors"
```plaintext
### `update`

Met à jour une dépendance vers sa dernière version.

**Paramètres obligatoires :**
- `--module` : Le nom du module à mettre à jour

**Exemple :**
```powershell
.\dependency-manager.exe update --module "github.com/gorilla/mux"
```plaintext
### `audit`

Effectue un audit de sécurité des dépendances.

**Exemple :**
```powershell
.\dependency-manager.exe audit
```plaintext
### `cleanup`

Nettoie les dépendances inutilisées du projet.

**Exemple :**
```powershell
.\dependency-manager.exe cleanup
```plaintext
## Configuration

Le gestionnaire utilise un fichier de configuration JSON situé dans :
`projet\config\managers\dependency-manager\dependency-manager.config.json`

### Exemple de configuration

```json
{
  "name": "dependency-manager",
  "version": "1.0.0",
  "settings": {
    "logPath": "logs",
    "logLevel": "INFO",
    "goModPath": "go.mod",
    "autoTidy": true,
    "vulnerabilityCheck": false,
    "backupOnChange": true
  }
}
```plaintext
### Paramètres de configuration

- **logPath** : Répertoire pour les fichiers de journalisation
- **logLevel** : Niveau de journalisation (DEBUG, INFO, WARNING, ERROR)
- **goModPath** : Chemin vers le fichier go.mod
- **autoTidy** : Active le nettoyage automatique après chaque opération
- **vulnerabilityCheck** : Active la vérification des vulnérabilités
- **backupOnChange** : Active la sauvegarde automatique avant modifications

## Journalisation

Le gestionnaire génère des logs détaillés dans le répertoire spécifié par la configuration.

### Types de logs

- **INFO** : Informations générales sur les opérations
- **SUCCESS** : Opérations réussies
- **WARNING** : Avertissements non critiques
- **ERROR** : Erreurs critiques
- **DEBUG** : Informations de débogage détaillées

### Localisation des logs

Les logs sont stockés dans :
- Fichier : `logs\dependency-manager.log`
- Console : Sortie colorée selon le niveau de log

## Sauvegardes automatiques

Le gestionnaire crée automatiquement des sauvegardes du fichier `go.mod` avant chaque modification.

### Format des sauvegardes

```plaintext
go.mod.backup.YYYYMMDD_HHMMSS
```plaintext
### Localisation

Les sauvegardes sont créées dans le même répertoire que le fichier `go.mod`.

## Gestion des erreurs

### Erreurs communes

1. **"go.mod introuvable"**
   - Assurez-vous d'être dans un projet Go valide
   - Vérifiez la présence du fichier go.mod

2. **"Module non trouvé"**
   - Vérifiez l'orthographe du nom du module
   - Assurez-vous que le module existe sur le registry Go

3. **"Impossible de charger la configuration"**
   - Le fichier de configuration sera créé automatiquement
   - Vérifiez les permissions de fichier

### Récupération automatique

Le gestionnaire inclut des mécanismes de récupération automatique :
- Restauration des sauvegardes en cas d'échec
- Tentatives de réparation automatique du go.mod
- Journalisation détaillée pour le débogage

## Intégration avec d'autres outils

### Avec l'integrated-manager

Le gestionnaire de dépendances peut être intégré avec l'integrated-manager pour une gestion centralisée.

### Avec CI/CD

Utilisez le gestionnaire dans vos pipelines :

```yaml
# Exemple GitHub Actions

- name: Audit dependencies
  run: .\development\managers\dependency-manager\dependency-manager.exe audit

- name: Clean dependencies
  run: .\development\managers\dependency-manager\dependency-manager.exe cleanup
```plaintext
## Performance

### Benchmarks

Tests de performance sur un système de référence :

- **List Dependencies** : 0.94 ns/op (100 dépendances)
- **Add Dependency** : 72.46 ns/op
- **Memory Usage** : Optimisé pour une faible consommation

### Optimisations

- Cache des métadonnées de modules
- Parsing incrémental du go.mod
- Journalisation asynchrone

## Sécurité

### Bonnes pratiques

1. **Audit régulier** : Exécutez `audit` régulièrement
2. **Versions spécifiques** : Évitez les versions "latest" en production
3. **Sauvegardes** : Conservez les sauvegardes pour la récupération
4. **Logs sécurisés** : Protégez les fichiers de log

### Vérifications automatiques

- Validation des noms de modules
- Vérification de l'intégrité du go.mod
- Détection des dépendances non utilisées

## Dépannage

### Mode debug

Activez le mode debug pour plus d'informations :

```powershell
.\dependency-manager.ps1 -Action list -LogLevel DEBUG
```plaintext
### Vérification de l'intégrité

```powershell
# Vérifier la validité du go.mod

go mod verify

# Reconstruire les dépendances

go mod download
```plaintext
### Support

Pour obtenir de l'aide :

```powershell
.\dependency-manager.exe help
```plaintext
## Exemples d'utilisation avancée

### Script de mise à jour de toutes les dépendances

```powershell
# Obtenir la liste des dépendances en JSON

$deps = .\dependency-manager.exe list --json | ConvertFrom-Json

# Mettre à jour chaque dépendance

foreach ($dep in $deps) {
    if (-not $dep.indirect) {
        Write-Host "Mise à jour de $($dep.name)..."
        .\dependency-manager.exe update --module $dep.name
    }
}
```plaintext
### Audit automatisé avec rapport

```powershell
# Exécuter l'audit et sauvegarder le rapport

$auditResult = .\dependency-manager.exe audit
$auditResult | Out-File -FilePath "audit-report-$(Get-Date -Format 'yyyyMMdd').txt"
```plaintext
### Nettoyage programmé

```powershell
# Ajouter à une tâche planifiée Windows

$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\path\to\dependency-manager.ps1 -Action cleanup -Force"
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 2AM
Register-ScheduledTask -TaskName "Go Dependencies Cleanup" -Action $action -Trigger $trigger
```plaintext