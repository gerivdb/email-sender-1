# Phase 2.3 - Plan de Refactorisation pour la Configuration
*Date: 2025-01-27 - Progression: 0% → 80%*

## ⚡ OBJECTIF
Intégrer le système ConfigManager (100% testé et opérationnel) dans le DependencyManager pour centraliser la gestion de configuration selon les patterns validés et harmoniser avec l'écosystème des managers.

## ÉTAT ACTUEL DEPENDENCYMANAGER ✅ ANALYSÉ

### Configuration Actuelle (✅ Fonctionnelle mais Isolée)
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

// ✅ loadConfig function implemented (Phase 1.X fix)
func loadConfig(configPath string) (*Config, error) {
    // JSON parsing with fallback to defaults
    // Validation system
    // Error handling
}
```

### Configuration File Actuelle
**Fichier** : `projet/config/managers/dependency-manager/dependency-manager.config.json`
```json
{
    "name": "dependency-manager",
    "version": "1.0.0",
    "settings": {
        "logPath": "logs/dependency-manager.log",
        "logLevel": "Info",
        "goModPath": "go.mod",
        "autoTidy": true,
        "vulnerabilityCheck": true,
        "backupOnChange": true
    }
}
```

## RÉFÉRENCE MODÈLE CONFIGMANAGER ✅ 100% TESTÉ

### Interface ConfigManager Complète
```go
type ConfigManager interface {
    // Core methods
    GetString(key string) (string, error)
    GetInt(key string) (int, error)
    GetBool(key string) (bool, error)
    UnmarshalKey(key string, targetStruct interface{}) error
    IsSet(key string) bool
    
    // Configuration management
    RegisterDefaults(defaults map[string]interface{})
    LoadConfigFile(filePath string, fileType string) error
    LoadFromEnv(prefix string)
    Validate() error
    SetRequiredKeys(keys []string)
    
    // Advanced functionality
    Get(key string) interface{}
    Set(key string, value interface{})
    SetDefault(key string, value interface{})
    GetAll() map[string]interface{}
    SaveToFile(filePath string, fileType string, config map[string]interface{}) error
    Cleanup() error
    
    // Manager integration
    GetErrorManager() ErrorManager
    GetLogger() *zap.Logger
}
```

### ConfigManager Implementation Structure
```go
type configManagerImpl struct {
    settings     map[string]interface{}
    defaults     map[string]interface{}
    requiredKeys []string
    logger       *zap.Logger
    errorManager *ErrorManagerImpl
}
```

## PLAN D'INTÉGRATION CONFIGMANAGER → DEPENDENCYMANAGER

### Étape 2.3.1 : Adapter Interface ConfigManager ✅ PLANIFIÉ

#### Micro-étape 2.3.1.1 : Intégrer ConfigManager Interface
- [x] **Source** : `config-manager/config_manager.go` interface complète
- [ ] **Action** : Remplacer la lecture directe de configuration par ConfigManager
- [ ] **Benefit** : Harmonisation avec l'écosystème des 17 managers

#### Micro-étape 2.3.1.2 : Migration Configuration Loading
- [x] **Actuel** : `loadConfig(configPath string) (*Config, error)`
- [ ] **Nouveau** : Utilisation `ConfigManager.LoadConfigFile()` et `UnmarshalKey()`
- [ ] **Pattern** :
```go
// NOUVEAU - Basé sur ConfigManager
configManager := configmanager.NewConfigManager(logger, errorManager)
configManager.LoadConfigFile("dependency-manager.config.json", "json")
var config Config
configManager.UnmarshalKey("", &config)
```

#### Micro-étape 2.3.1.3 : Configuration Validation
- [x] **Actuel** : `validateConfig(config *Config) error`
- [ ] **Nouveau** : Utilisation `ConfigManager.Validate()` et `SetRequiredKeys()`
- [ ] **Required Keys DependencyManager** :
```go
requiredKeys := []string{
    "name", "version", 
    "settings.logPath", "settings.logLevel", 
    "settings.goModPath", "settings.autoTidy",
    "settings.vulnerabilityCheck", "settings.backupOnChange"
}
configManager.SetRequiredKeys(requiredKeys)
```

### Étape 2.3.2 : Migration Schema Configuration ✅ DÉFINI

#### Configuration Schema Adaptation
**AVANT** (Structure DependencyManager spécifique):
```json
{
    "name": "dependency-manager",
    "version": "1.0.0", 
    "settings": { ... }
}
```

**APRÈS** (Compatible ConfigManager):
```json
{
    "dependency-manager": {
        "name": "dependency-manager",
        "version": "1.0.0",
        "settings": {
            "logPath": "logs/dependency-manager.log",
            "logLevel": "Info",
            "goModPath": "go.mod", 
            "autoTidy": true,
            "vulnerabilityCheck": true,
            "backupOnChange": true
        }
    }
}
```

#### Micro-étape 2.3.2.1 : Schema Migration
- [ ] **Config Path** : `dependency-manager.config.json` → section dans config centralisée
- [ ] **Key Structure** : Namespace "dependency-manager" pour isolation
- [ ] **Backward Compatibility** : Support ancien format pendant transition

#### Micro-étape 2.3.2.2 : Default Values Integration
- [x] **Actuel** : `getDefaultConfig()` function
- [ ] **Nouveau** : `ConfigManager.RegisterDefaults()` et `SetDefault()`
```go
defaults := map[string]interface{}{
    "dependency-manager.name": "dependency-manager",
    "dependency-manager.version": "1.0.0",
    "dependency-manager.settings.logPath": "logs/dependency-manager.log",
    "dependency-manager.settings.logLevel": "Info",
    "dependency-manager.settings.goModPath": "go.mod",
    "dependency-manager.settings.autoTidy": true,
    "dependency-manager.settings.vulnerabilityCheck": true,
    "dependency-manager.settings.backupOnChange": true,
}
configManager.RegisterDefaults(defaults)
```

### Étape 2.3.3 : Code Integration ✅ READY

#### GoModManager Struct Update
**AVANT**:
```go
type GoModManager struct {
    modFilePath  string
    config       *Config
    logger       *zap.Logger
    errorManager *ErrorManagerImpl
}
```

**APRÈS**:
```go
type GoModManager struct {
    modFilePath   string
    configManager ConfigManager  // ← Nouveau
    logger        *zap.Logger
    errorManager  *ErrorManagerImpl
}
```

#### Configuration Access Pattern
**AVANT** (Direct struct access):
```go
if m.config.Settings.BackupOnChange {
    // backup logic
}
logLevel := m.config.Settings.LogLevel
```

**APRÈS** (ConfigManager interface):
```go
if m.configManager.GetBool("dependency-manager.settings.backupOnChange") {
    // backup logic
}
logLevel, _ := m.configManager.GetString("dependency-manager.settings.logLevel")
```

### Étape 2.3.4 : Environment Integration ✅ PLANIFIÉ

#### Environment Variables Support
- [ ] **ConfigManager Feature** : `LoadFromEnv(prefix string)`
- [ ] **DependencyManager Prefix** : `"DEPMAN_"` ou `"EMAIL_SENDER_DEPENDENCY_"`
- [ ] **Environment Mapping** :
```bash
DEPMAN_LOG_LEVEL=Debug
DEPMAN_AUTO_TIDY=false
DEPMAN_VULNERABILITY_CHECK=true
DEPMAN_BACKUP_ON_CHANGE=false
```

#### Priority Order (ConfigManager Standard)
1. **Environment Variables** (highest priority)
2. **Config File** (medium priority)  
3. **Defaults** (lowest priority)

## MIGRATION STRATEGY

### Phase A : Parallel Implementation
- [ ] **Maintain Current** : Keep existing `loadConfig` for backward compatibility
- [ ] **Add ConfigManager** : Implement ConfigManager alongside existing system
- [ ] **Feature Flag** : Environment variable to switch between systems

### Phase B : Gradual Migration
- [ ] **Update Constructor** : `NewGoModManager` accepts ConfigManager
- [ ] **Migrate Methods** : Replace direct config access with ConfigManager calls
- [ ] **Test Compatibility** : Ensure feature parity between old and new systems

### Phase C : Complete Switch
- [ ] **Remove Legacy** : Delete `loadConfig`, `validateConfig`, `getDefaultConfig`
- [ ] **Update Callers** : All instantiation uses ConfigManager
- [ ] **Documentation** : Update integration guides

## BÉNÉFICES DE L'INTÉGRATION

### Centralisation Configuration ✅
- **Single Source of Truth** : Configuration centralisée via ConfigManager
- **Cross-Manager Compatibility** : Harmonisation avec SecurityManager, MonitoringManager, etc.
- **Environment Integration** : Support automatique des variables d'environnement

### Advanced Features ✅
- **Dynamic Configuration** : Modification runtime via `Set()` methods
- **Configuration Persistence** : `SaveToFile()` pour sauvegarder les changements
- **Validation Robuste** : Système de validation centralisé et testé

### Monitoring et Debugging ✅
- **Structured Logging** : Configuration changes loggées via ErrorManager intégré
- **Error Handling** : Gestion d'erreur unifiée pour problèmes de configuration
- **Observability** : Configuration state visible via `GetAll()`

## TESTS ET VALIDATION

### Compatibility Tests ✅
- [ ] **Backward Compatibility** : Ancien format config fonctionne toujours
- [ ] **Feature Parity** : Toutes les fonctionnalités conservées
- [ ] **Performance** : Pas de dégradation des performances

### Integration Tests ✅
- [ ] **ConfigManager Integration** : Interface complètement fonctionnelle
- [ ] **Environment Variables** : Variables d'environnement correctement chargées
- [ ] **Default Values** : Fallback defaults fonctionnent correctement

### Error Scenarios ✅
- [ ] **Invalid Config** : Gestion erreurs de configuration invalide
- [ ] **Missing Files** : Comportement avec fichiers manquants
- [ ] **Permission Issues** : Gestion erreurs de permissions fichier

## LIVRABLES

### Code Modifications
- [ ] **GoModManager Update** : Integration ConfigManager interface
- [ ] **Configuration Schema** : Migration vers format ConfigManager compatible
- [ ] **Environment Support** : Variables d'environnement avec prefixe
- [ ] **Error Integration** : Configuration errors via ErrorManager standardisé

### Documentation
- [ ] **Migration Guide** : Instructions pour transition vers ConfigManager
- [ ] **Configuration Reference** : Toutes les options de configuration disponibles
- [ ] **Environment Variables** : Liste complète des variables supportées

### Tests
- [ ] **Unit Tests** : Configuration loading et validation
- [ ] **Integration Tests** : ConfigManager interface compliance
- [ ] **Compatibility Tests** : Backward compatibility et migration

## RÉFÉRENCES

### ConfigManager (✅ 100% Testé et Opérationnel)
- **Fichier** : `development/managers/config-manager/config_manager.go`
- **Interface** : Lignes 59-77 (interface complète)
- **Implementation** : Lignes 79-753 (implémentation testée)
- **Status** : Production ready, ErrorManager intégré

### DependencyManager Configuration Actuelle
- **Config File** : `projet/config/managers/dependency-manager/dependency-manager.config.json`
- **loadConfig** : `dependency_manager.go` lignes 501-526 (récemment implémenté)
- **validateConfig** : `dependency_manager.go` lignes 541-553 (fonctionnel)
- **getDefaultConfig** : `dependency_manager.go` lignes 527-540 (complet)

**STATUT** : ✅ Ready to implement - ConfigManager model provides complete integration path with 100% tested reference implementation.

**NEXT STEP** : Begin Phase 2.3.1 - ConfigManager Interface Integration
