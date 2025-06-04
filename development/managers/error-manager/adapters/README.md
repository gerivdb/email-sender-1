# Adaptateurs Infrastructure PowerShell/Python

Ce package contient les adaptateurs pour intégrer le gestionnaire d'erreurs Go avec l'infrastructure PowerShell et Python existante.

## Structure

```
adapters/
├── script_inventory_adapter.go    # Adaptateur principal pour ScriptInventoryManager.psm1
├── duplication_handler.go         # Gestionnaire d'erreurs de duplication
├── enhanced_types.go              # Types enrichis avec contexte de duplication
├── adapters_test.go               # Tests unitaires
├── ScriptInventoryManager.psm1    # Module PowerShell d'exemple
├── example_usage.go               # Exemple d'utilisation
└── README.md                      # Cette documentation
```

## Fonctionnalités

### 1. ScriptInventoryAdapter

Interface avec le module PowerShell `ScriptInventoryManager.psm1` pour :
- Inventaire automatique des scripts (.ps1, .py, .go, .js, .ts)
- Analyse des dépendances
- Extraction des métadonnées
- Intégration des erreurs avec ErrorManager

### 2. DuplicationErrorHandler

Gestionnaire pour les erreurs de duplication :
- Surveillance des rapports de duplication
- Traitement des erreurs Find-CodeDuplication.ps1
- Génération d'alertes selon le score de similarité
- Recommandations d'action automatiques

### 3. Types Enrichis

Extensions du modèle ErrorEntry :
- `DuplicationContext` : Contexte enrichi de duplication
- `EnhancedErrorEntry` : ErrorEntry avec contexte de duplication
- `DuplicationMetrics` : Métriques et corrélations

## Utilisation

### Configuration de base

```go
package main

import (
    "time"
    "path/filepath"
    "development/managers/error-manager/adapters"
)

func main() {
    // Configuration de l'adaptateur de script
    scriptConfig := adapters.ScriptInventoryConfig{
        ScriptInventoryPath: filepath.Join("scripts", "ScriptInventoryManager.psm1"),
        PythonExecutable:    "python",
        WorkingDirectory:    ".",
        TimeoutSeconds:      30,
    }
    
    scriptAdapter := adapters.NewScriptInventoryAdapter(scriptConfig)
    
    // Test de connectivité
    if err := scriptAdapter.ConnectToScriptInventory(); err != nil {
        log.Fatalf("Échec de connexion: %v", err)
    }
    
    // Exécution d'un inventaire
    result, err := scriptAdapter.ExecuteScriptInventory("./src")
    if err != nil {
        log.Fatalf("Échec de l'inventaire: %v", err)
    }
    
    log.Printf("Inventaire terminé: %d scripts trouvés", len(result.Scripts))
}
```

### Gestionnaire de duplication

```go
// Configuration du gestionnaire de duplication
dupHandler := adapters.NewDuplicationErrorHandler(
    "./reports", 
    time.Minute * 5, // Surveillance toutes les 5 minutes
)

// Callback pour traiter les erreurs
dupHandler.SetErrorCallback(func(err adapters.DuplicationError) {
    log.Printf("Duplication détectée: %s -> %s (score: %.2f)", 
        err.SourceFile, err.DuplicateFile, err.SimilarityScore)
    
    // Intégrer avec ErrorManager principal
    // errorManager.CatalogError(...)
})

// Démarrer la surveillance
go dupHandler.WatchDuplicationReports()
```

### Création d'erreurs enrichies

```go
// Erreur de base
baseError := map[string]interface{}{
    "id":          "err123",
    "timestamp":   time.Now(),
    "message":     "Erreur dans script.ps1",
    "module":      "script-manager",
    "error_code":  "SCRIPT_ERROR",
    "severity":    "ERROR",
}

// Contexte de duplication
dupContext := &adapters.DuplicationContext{
    SourceFile:       "script.ps1",
    DuplicateFiles:   []string{"script_copy.ps1"},
    SimilarityScores: map[string]float64{"script_copy.ps1": 0.95},
    DetectionMethod:  "powershell_analysis",
    LastDetection:    time.Now(),
}

// Créer une erreur enrichie
enhanced := adapters.CreateEnhancedErrorEntry(baseError, dupContext)
```

## Tests

Exécuter les tests :

```bash
cd adapters
go test -v
```

Les tests couvrent :
- ✅ Configuration des adaptateurs
- ✅ Validation des chemins
- ✅ Conversion des données PowerShell
- ✅ Traitement des rapports de duplication
- ✅ Création d'erreurs enrichies
- ✅ Calcul des scores de corrélation

## Intégration avec PowerShell

### Prérequis

1. PowerShell 5.1+ ou PowerShell Core 7+
2. Module `ScriptInventoryManager.psm1` installé
3. Permissions d'exécution appropriées

### Installation du module PowerShell

```powershell
# Copier le module dans un répertoire de modules
$modulePath = "$env:PSModulePath".Split(';')[0]
Copy-Item "ScriptInventoryManager.psm1" "$modulePath\ScriptInventoryManager\"

# Importer le module
Import-Module ScriptInventoryManager -Force

# Tester le module
Get-ScriptInventory -Path "C:\Scripts" -Detailed
```

## Surveillance en temps réel

Le système peut être étendu pour surveiller :
- Modifications de fichiers (via fsnotify équivalent)
- Nouvelles duplications détectées
- Erreurs PowerShell en temps réel
- Métriques de performance

## Prochaines étapes

1. **Phase 8.2** : Optimisation surveillance temps réel
2. **Intégration API REST** : Serveur HTTP pour recevoir les erreurs PowerShell
3. **Tableau de bord** : Interface web pour visualiser les duplications
4. **Alerts avancées** : Intégration Slack/Teams pour notifications

## Dépendances

- `github.com/pkg/errors` : Gestion d'erreurs enrichies
- PowerShell : Exécution des scripts d'inventaire
- Go standard library : `os/exec`, `encoding/json`, `time`

## Compatibilité

- ✅ Windows 10/11 avec PowerShell
- ✅ PowerShell Core (multiplateforme)
- ✅ Go 1.19+
- ✅ Python 3.8+ (pour scripts Python)
