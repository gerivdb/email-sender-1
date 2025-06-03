# API Documentation - Gestionnaire de Dépendances Go

## Architecture

Le gestionnaire de dépendances est conçu selon les principes SOLID et utilise une architecture modulaire pour faciliter la maintenance et l'extension.

### Diagramme d'architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     CLI Interface                           │
│                   (dependency_manager.go)                   │
├─────────────────────────────────────────────────────────────┤
│                   PowerShell Wrapper                        │
│                 (dependency-manager.ps1)                    │
├─────────────────────────────────────────────────────────────┤
│                     Core Interfaces                         │
│                     (DepManager)                            │
├─────────────────────────────────────────────────────────────┤
│                  Implementation Layer                       │
│                   (GoModManager)                            │
├─────────────────────────────────────────────────────────────┤
│               External Dependencies                         │
│          (golang.org/x/mod, go toolchain)                  │
└─────────────────────────────────────────────────────────────┘
```

## Interfaces principales

### DepManager Interface

```go
type DepManager interface {
    List() ([]Dependency, error)
    Add(module, version string) error
    Remove(module string) error
    Update(module string) error
    Audit() error
    Cleanup() error
}
```

**Description :** Interface principale définissant les opérations de gestion des dépendances.

#### Méthodes

##### `List() ([]Dependency, error)`

Retourne la liste de toutes les dépendances du projet.

**Retour :**
- `[]Dependency` : Liste des dépendances
- `error` : Erreur éventuelle

**Exemple d'utilisation :**
```go
manager := NewGoModManager("go.mod", config)
deps, err := manager.List()
if err != nil {
    log.Fatal(err)
}
for _, dep := range deps {
    fmt.Printf("%s@%s\n", dep.Name, dep.Version)
}
```

##### `Add(module, version string) error`

Ajoute une nouvelle dépendance au projet.

**Paramètres :**
- `module` (string) : Nom du module à ajouter
- `version` (string) : Version à installer ("latest" par défaut)

**Retour :**
- `error` : Erreur éventuelle

**Exemple d'utilisation :**
```go
err := manager.Add("github.com/pkg/errors", "v0.9.1")
if err != nil {
    log.Printf("Erreur lors de l'ajout: %v", err)
}
```

##### `Remove(module string) error`

Supprime une dépendance du projet.

**Paramètres :**
- `module` (string) : Nom du module à supprimer

**Retour :**
- `error` : Erreur éventuelle

**Exemple d'utilisation :**
```go
err := manager.Remove("github.com/pkg/errors")
if err != nil {
    log.Printf("Erreur lors de la suppression: %v", err)
}
```

##### `Update(module string) error`

Met à jour une dépendance vers sa dernière version.

**Paramètres :**
- `module` (string) : Nom du module à mettre à jour

**Retour :**
- `error` : Erreur éventuelle

**Exemple d'utilisation :**
```go
err := manager.Update("github.com/gorilla/mux")
if err != nil {
    log.Printf("Erreur lors de la mise à jour: %v", err)
}
```

##### `Audit() error`

Effectue un audit de sécurité des dépendances.

**Retour :**
- `error` : Erreur éventuelle

**Exemple d'utilisation :**
```go
err := manager.Audit()
if err != nil {
    log.Printf("Erreur lors de l'audit: %v", err)
}
```

##### `Cleanup() error`

Nettoie les dépendances inutilisées.

**Retour :**
- `error` : Erreur éventuelle

**Exemple d'utilisation :**
```go
err := manager.Cleanup()
if err != nil {
    log.Printf("Erreur lors du nettoyage: %v", err)
}
```

## Structures de données

### Dependency

```go
type Dependency struct {
    Name     string `json:"name"`
    Version  string `json:"version"`
    Indirect bool   `json:"indirect,omitempty"`
}
```

**Description :** Représente une dépendance Go avec ses métadonnées.

**Champs :**
- `Name` : Nom complet du module (ex: "github.com/pkg/errors")
- `Version` : Version sémantique (ex: "v0.9.1")
- `Indirect` : Indique si la dépendance est indirecte

### Config

```go
type Config struct {
    Name     string `json:"name"`
    Version  string `json:"version"`
    Settings struct {
        LogPath            string `json:"logPath"`
        LogLevel           string `json:"logLevel"`
        GoModPath          string `json:"goModPath"`
        AutoTidy           bool   `json:"autoTidy"`
        VulnerabilityCheck bool   `json:"vulnerabilityCheck"`
        BackupOnChange     bool   `json:"backupOnChange"`
    } `json:"settings"`
}
```

**Description :** Configuration du gestionnaire de dépendances.

**Champs :**
- `Name` : Nom du gestionnaire
- `Version` : Version du gestionnaire
- `Settings` : Paramètres de configuration
  - `LogPath` : Répertoire des logs
  - `LogLevel` : Niveau de journalisation
  - `GoModPath` : Chemin vers go.mod
  - `AutoTidy` : Nettoyage automatique
  - `VulnerabilityCheck` : Vérification des vulnérabilités
  - `BackupOnChange` : Sauvegarde automatique

## Implémentation GoModManager

### GoModManager

```go
type GoModManager struct {
    modFilePath string
    config      *Config
}
```

**Description :** Implémentation concrète de DepManager pour les projets Go.

### Constructeur

```go
func NewGoModManager(modFilePath string, config *Config) *GoModManager
```

**Paramètres :**
- `modFilePath` : Chemin vers le fichier go.mod
- `config` : Configuration du gestionnaire

**Retour :**
- `*GoModManager` : Instance du gestionnaire

### Méthodes internes

#### `Log(level, message string)`

Enregistre un message dans les logs.

**Paramètres :**
- `level` : Niveau de log (INFO, WARNING, ERROR, etc.)
- `message` : Message à enregistrer

#### `backupGoMod() error`

Crée une sauvegarde du fichier go.mod.

**Retour :**
- `error` : Erreur éventuelle

#### `runGoModTidy() error`

Exécute `go mod tidy` pour nettoyer les dépendances.

**Retour :**
- `error` : Erreur éventuelle

## Fonctions utilitaires

### `loadConfig(configPath string) (*Config, error)`

Charge la configuration depuis un fichier JSON.

**Paramètres :**
- `configPath` : Chemin vers le fichier de configuration

**Retour :**
- `*Config` : Configuration chargée
- `error` : Erreur éventuelle

### `findGoMod(startDir string) string`

Recherche le fichier go.mod dans l'arborescence.

**Paramètres :**
- `startDir` : Répertoire de départ

**Retour :**
- `string` : Chemin vers go.mod ou chaîne vide

## Interface CLI

### Commandes disponibles

| Commande | Arguments | Description |
|----------|-----------|-------------|
| `list` | `[--json]` | Liste les dépendances |
| `add` | `--module <nom> [--version <ver>]` | Ajoute une dépendance |
| `remove` | `--module <nom>` | Supprime une dépendance |
| `update` | `--module <nom>` | Met à jour une dépendance |
| `audit` | - | Audit de sécurité |
| `cleanup` | - | Nettoyage |
| `help` | - | Affiche l'aide |

### Codes de retour

| Code | Description |
|------|-------------|
| 0 | Succès |
| 1 | Erreur générale |
| 2 | Arguments invalides |
| 3 | Fichier go.mod introuvable |
| 4 | Erreur de réseau |
| 5 | Erreur de permission |

## Interface PowerShell

### Paramètres du script

```powershell
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("list", "add", "remove", "update", "audit", "cleanup", "build", "install", "help")]
    [string]$Action,
    
    [Parameter(Mandatory = $false)]
    [string]$Module = "",
    
    [Parameter(Mandatory = $false)]
    [string]$Version = "latest",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$JSON,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR")]
    [string]$LogLevel = "INFO"
)
```

### Fonctions internes

#### `Write-Log`

```powershell
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
}
```

#### `Test-Prerequisites`

```powershell
function Test-Prerequisites {
    # Vérifie les prérequis (Go, go.mod)
    # Retourne $true si OK, $false sinon
}
```

#### `Build-DependencyManager`

```powershell
function Build-DependencyManager {
    # Compile le gestionnaire
    # Retourne $true si succès, $false sinon
}
```

#### `Invoke-DependencyCommand`

```powershell
function Invoke-DependencyCommand {
    param (
        [string]$Command,
        [string[]]$Arguments = @()
    )
    # Exécute une commande du gestionnaire
    # Retourne $true si succès, $false sinon
}
```

## Gestion des erreurs

### Types d'erreurs

1. **Erreurs de configuration**
   - Fichier de configuration invalide
   - Paramètres manquants

2. **Erreurs de système de fichiers**
   - go.mod introuvable
   - Permissions insuffisantes
   - Espace disque insuffisant

3. **Erreurs réseau**
   - Module introuvable
   - Timeout de téléchargement
   - Proxy non accessible

4. **Erreurs de parsing**
   - go.mod corrompu
   - Version invalide
   - Syntaxe incorrecte

### Mécanismes de récupération

1. **Sauvegardes automatiques**
   - Sauvegarde avant modification
   - Restauration en cas d'échec

2. **Retry logic**
   - Tentatives multiples pour les opérations réseau
   - Backoff exponentiel

3. **Validation**
   - Vérification de l'intégrité avant/après
   - Rollback automatique

## Extension et personnalisation

### Implémentation d'un nouveau gestionnaire

```go
type CustomDepManager struct {
    // Vos champs personnalisés
}

func (c *CustomDepManager) List() ([]Dependency, error) {
    // Votre implémentation
}

// Implémentez toutes les méthodes de l'interface DepManager
```

### Ajout de nouvelles commandes CLI

```go
// Dans runCLI()
case "votre-commande":
    // Traitement de votre commande personnalisée
```

### Hooks et callbacks

```go
type Hooks struct {
    BeforeAdd    func(module, version string) error
    AfterAdd     func(module, version string) error
    BeforeRemove func(module string) error
    AfterRemove  func(module string) error
}
```

## Tests et validation

### Tests unitaires

```go
func TestGoModManager_List(t *testing.T) {
    // Test de la méthode List
}

func TestGoModManager_Add(t *testing.T) {
    // Test de la méthode Add
}
```

### Tests d'intégration

```go
func TestFullWorkflow(t *testing.T) {
    // Test du workflow complet
    // add -> list -> update -> remove -> cleanup
}
```

### Benchmarks

```go
func BenchmarkListDependencies(b *testing.B) {
    // Benchmark de performance
}
```

## Monitoring et observabilité

### Métriques disponibles

1. **Performance**
   - Temps d'exécution des commandes
   - Utilisation mémoire
   - Taille des fichiers de log

2. **Utilisation**
   - Nombre d'opérations par type
   - Modules les plus utilisés
   - Fréquence des mises à jour

3. **Erreurs**
   - Taux d'erreur par opération
   - Types d'erreurs fréquents
   - Temps de récupération

### Logs structurés

```json
{
  "timestamp": "2025-06-03T20:00:00Z",
  "level": "INFO",
  "component": "dependency-manager",
  "operation": "add",
  "module": "github.com/pkg/errors",
  "version": "v0.9.1",
  "duration_ms": 1234,
  "success": true
}
```

## Sécurité

### Bonnes pratiques

1. **Validation des entrées**
   - Vérification des noms de modules
   - Validation des versions
   - Échappement des paramètres

2. **Gestion des permissions**
   - Lecture seule par défaut
   - Confirmation pour les modifications
   - Audit des changements

3. **Protection des données**
   - Chiffrement des logs sensibles
   - Rotation des fichiers de log
   - Nettoyage des données temporaires

### Vulnérabilités communes

1. **Injection de code**
   - Validation stricte des paramètres
   - Utilisation d'APIs sécurisées

2. **Path traversal**
   - Vérification des chemins
   - Restriction aux répertoires autorisés

3. **DoS**
   - Limitation des ressources
   - Timeout appropriés

## Performances

### Optimisations

1. **Cache**
   - Cache des métadonnées de modules
   - Cache des résultats d'audit

2. **Parallélisation**
   - Téléchargements parallèles
   - Traitement concurrent

3. **Lazy loading**
   - Chargement à la demande
   - Pagination des résultats

### Profiling

```go
import _ "net/http/pprof"

// Ajoutez un serveur pprof pour le profiling
go func() {
    log.Println(http.ListenAndServe("localhost:6060", nil))
}()
```

## Migration et compatibilité

### Versions supportées

- Go 1.23+
- PowerShell 5.1+
- Windows 10+

### Migration depuis d'autres outils

1. **Depuis go mod**
   - Import automatique
   - Préservation de la configuration

2. **Depuis dep**
   - Conversion Gopkg.toml → go.mod
   - Migration des contraintes

3. **Depuis vendor**
   - Analyse du vendor/
   - Reconstruction des dépendances
