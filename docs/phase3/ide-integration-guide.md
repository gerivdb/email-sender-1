# Phase 3 : Intégration IDE et Expérience Développeur - Documentation Complète

## Vue d'ensemble

La Phase 3 du projet Smart Email Sender se concentre sur l'amélioration de l'expérience développeur en intégrant l'infrastructure directement dans l'environnement VS Code et en fournissant des outils de gestion manuel complets.

## Composants Implémentés

### 1. Extension VS Code

#### 1.1 Fonctionnalités principales

- **Auto-détection du workspace** : L'extension détecte automatiquement si le workspace EMAIL_SENDER_1 est ouvert
- **Démarrage automatique** : Lance l'infrastructure au démarrage du workspace (configurable)
- **Status bar intégrée** : Affiche le statut en temps réel dans la barre de statut VS Code
- **Commandes VS Code** : Interface complète pour gérer l'infrastructure
- **Monitoring en temps réel** : Actualisation automatique du statut toutes les 30 secondes

#### 1.2 Commandes disponibles

| Commande | Description | Raccourci |
|----------|-------------|-----------|
| `smartEmailSender.startStack` | Démarre la stack complète | Ctrl+Shift+P > Start Infrastructure Stack |
| `smartEmailSender.stopStack` | Arrête la stack complète | Ctrl+Shift+P > Stop Infrastructure Stack |
| `smartEmailSender.restartStack` | Redémarre la stack | Ctrl+Shift+P > Restart Infrastructure Stack |
| `smartEmailSender.showStatus` | Affiche le statut détaillé | Ctrl+Shift+P > Show Infrastructure Status |
| `smartEmailSender.enableAutoHealing` | Active/Désactive l'auto-healing | Ctrl+Shift+P > Enable Auto-Healing |
| `smartEmailSender.showLogs` | Affiche les logs de l'extension | Ctrl+Shift+P > Show Infrastructure Logs |

#### 1.3 Configuration

L'extension peut être configurée via les paramètres VS Code :

```json
{
    "smartEmailSender.autoStart": true,           // Démarrage automatique
    "smartEmailSender.autoHealing": false,       // Auto-healing par défaut
    "smartEmailSender.apiPort": 8080,            // Port de l'API
    "smartEmailSender.showNotifications": true   // Notifications
}
```

#### 1.4 Indicateurs visuels

- **🏠** : Workspace détecté
- **✅** : Infrastructure fonctionnelle
- **💚** : Auto-healing activé
- **⚠️** : Monitoring inactif
- **❌** : Erreur ou service arrêté
- **⏳** : Opération en cours

### 2. Scripts PowerShell Complémentaires

#### 2.1 Start-FullStack.ps1 (existant)

Script de démarrage complet avec options avancées.

#### 2.2 Stop-FullStack.ps1 (nouveau)

**Fonctionnalités :**

- Arrêt gracieux ou forcé des services
- Gestion des processus Go et conteneurs Docker
- Vérification et libération des ports réseau
- Nettoyage optionnel des fichiers temporaires
- Option de conservation des données

**Utilisation :**

```powershell
# Arrêt gracieux
.\scripts\Stop-FullStack.ps1

# Arrêt forcé
.\scripts\Stop-FullStack.ps1 -Force

# Conserver les données
.\scripts\Stop-FullStack.ps1 -KeepData

# Mode verbeux
.\scripts\Stop-FullStack.ps1 -Verbose
```

#### 2.3 Status-FullStack.ps1 (nouveau)

**Fonctionnalités :**

- Statut détaillé de tous les composants
- Monitoring des ressources système
- Vérification des ports réseau
- Statut des services Docker et processus Go
- Output JSON pour intégration
- Mode continu avec actualisation

**Utilisation :**

```powershell
# Statut simple
.\scripts\Status-FullStack.ps1

# Statut détaillé
.\scripts\Status-FullStack.ps1 -Detailed

# Output JSON
.\scripts\Status-FullStack.ps1 -Json

# Mode continu (actualisation toutes les 5 secondes)
.\scripts\Status-FullStack.ps1 -Continuous -RefreshInterval 5
```

## Architecture Technique

### 1. Extension VS Code

```
.vscode/extension/
├── package.json          # Configuration et métadonnées
├── tsconfig.json         # Configuration TypeScript
└── src/
    └── extension.ts      # Logique principale
```

**Classes principales :**

- `SmartEmailSenderExtension` : Classe principale gérant l'extension
- Interface avec l'API REST sur le port 8080
- Gestion des commandes VS Code et de la status bar

### 2. Intégration API

L'extension communique avec l'infrastructure via l'API REST :

```typescript
// Endpoints utilisés
GET  /api/v1/infrastructure/status  // Statut des services
GET  /api/v1/monitoring/status      // Statut du monitoring
POST /api/v1/auto-healing/enable    // Activer auto-healing
POST /api/v1/auto-healing/disable   // Désactiver auto-healing
```

### 3. Scripts PowerShell

Les scripts utilisent une architecture modulaire :

```powershell
# Fonctions communes
function Write-StatusMessage { }    # Logging coloré
function Get-DockerServicesStatus { }   # Status Docker
function Get-GoProcessesStatus { }      # Status processus Go
function Get-NetworkPortsStatus { }     # Status ports réseau
function Get-SystemResources { }        # Ressources système
```

## Installation et Configuration

### 1. Installation Extension VS Code

```bash
# Depuis le répertoire de l'extension
cd .vscode/extension
npm install
npm run compile

# Installation dans VS Code
code --install-extension .
```

### 2. Configuration Workspace

L'extension s'active automatiquement quand :

- Le workspace contient "EMAIL_SENDER_1" dans le chemin
- Le fichier `cmd/infrastructure-api-server/main.go` existe

### 3. Permissions PowerShell

```powershell
# Autoriser l'exécution des scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Utilisation Quotidienne

### Flux de travail typique

1. **Ouverture du workspace** : L'extension détecte automatiquement le projet
2. **Démarrage automatique** : L'infrastructure se lance si activé
3. **Monitoring continu** : Status bar mise à jour toutes les 30 secondes
4. **Contrôle manuel** : Commandes VS Code ou scripts PowerShell
5. **Arrêt propre** : Stop via VS Code ou script PowerShell

### Scénarios d'usage

#### Développement normal

```
1. Ouvrir VS Code → Extension détecte le workspace
2. Infrastructure démarre automatiquement
3. Status bar indique "✅ Running + Auto-Healing (X services)"
4. Développer normalement
5. Fermer VS Code → Infrastructure continue de tourner
```

#### Debug d'infrastructure

```
1. Ctrl+Shift+P → "Show Infrastructure Status"
2. Analyser les services en erreur
3. Utiliser les logs via "Show Infrastructure Logs"
4. Redémarrer via "Restart Infrastructure Stack"
```

#### Contrôle manuel avancé

```powershell
# Status détaillé avec actualisation continue
.\scripts\Status-FullStack.ps1 -Continuous -Detailed

# Arrêt pour maintenance
.\scripts\Stop-FullStack.ps1 -KeepData

# Redémarrage après maintenance
.\scripts\Start-FullStack.ps1 -EnableAutoHealing
```

## Troubleshooting

### Problèmes courants

#### Extension ne s'active pas

- Vérifier que le workspace contient "EMAIL_SENDER_1"
- Vérifier la présence de `cmd/infrastructure-api-server/main.go`
- Redémarrer VS Code

#### Status bar n'affiche rien

- Vérifier que l'API server fonctionne sur le port 8080
- Vérifier les logs de l'extension (Output > Smart Email Sender)
- Tester manuellement : `curl http://localhost:8080/api/v1/infrastructure/status`

#### Scripts PowerShell échouent

- Vérifier ExecutionPolicy : `Get-ExecutionPolicy`
- Vérifier les permissions sur les fichiers
- Exécuter avec `-Verbose` pour plus de détails

### Logs et Debugging

#### Extension VS Code

```
- Output panel : "Smart Email Sender"
- F12 Developer Tools dans VS Code
- Logs de l'API server : voir cmd/infrastructure-api-server/
```

#### Scripts PowerShell

```powershell
# Mode verbeux
.\scripts\Status-FullStack.ps1 -Verbose

# Debugging avec Write-Debug
$DebugPreference = "Continue"
.\scripts\Stop-FullStack.ps1
```

## Extensions et Personnalisations

### Personnaliser l'extension

1. **Modifier les configurations** dans `package.json`
2. **Ajouter des commandes** dans la section `contributes.commands`
3. **Personnaliser l'interface** dans `src/extension.ts`

### Ajouter des scripts PowerShell

1. **Créer le script** dans `scripts/`
2. **Utiliser les fonctions communes** pour la cohérence
3. **Ajouter la documentation** dans ce fichier

### Intégration CI/CD

Les scripts peuvent être utilisés dans les pipelines :

```yaml
# GitHub Actions exemple
- name: Start Infrastructure
  run: .\scripts\Start-FullStack.ps1
  shell: pwsh

- name: Run Tests
  run: go test ./...

- name: Stop Infrastructure  
  run: .\scripts\Stop-FullStack.ps1 -Force
  shell: pwsh
```

## Métriques et Monitoring

### Métriques collectées

- **Services actifs** : Nombre de services fonctionnels
- **Santé globale** : Pourcentage de santé de l'infrastructure
- **Ports critiques** : État des ports 8080, 6333, 5432
- **Ressources système** : CPU, mémoire, disque

### Alertes configurées

- **Service down** : Alerte immédiate si service critique arrêté
- **High resource usage** : Alerte si CPU > 80% ou mémoire > 90%
- **Network issues** : Alerte si ports critiques inaccessibles

## Roadmap et Évolutions

### Améliorations prévues

1. **Extension VS Code**
   - Interface graphique avancée (Webview)
   - Graphiques de monitoring en temps réel
   - Intégration avec Git pour auto-deploy

2. **Scripts PowerShell**
   - Support multi-environnement (dev/staging/prod)
   - Sauvegarde automatique avant arrêt
   - Integration avec Kubernetes

3. **Automation**
   - Déploiement automatique sur changement de branche
   - Tests d'intégration automatiques
   - Rollback automatique en cas d'erreur

---

*Documentation mise à jour : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*
*Version : Phase 3 Complete*
*Auteur : Smart Infrastructure Team*
