# Phase 2.2 - Plan de Refactorisation pour la Gestion des Erreurs
*Date: 2025-01-27 - Progression: 0% → 80%*

## ⚡ OBJECTIF
Adapter le modèle ConfigManager ErrorManager (100% testé et opérationnel) au DependencyManager pour standardiser la gestion des erreurs selon les patterns validés.

## RÉFÉRENCE MODÈLE CONFIGMANAGER ✅

### Interface ErrorManager Standard (✅ Validée et Testée)
```go
type ErrorManager interface {
    ProcessError(ctx context.Context, err error, component, operation string, hooks *ErrorHooks) error
    CatalogError(entry ErrorEntry) error
    ValidateErrorEntry(entry ErrorEntry) error
}
```

### Structure ErrorEntry Complète (✅ Validée)
```go
type ErrorEntry struct {
    ID             string    `json:"id"`
    Timestamp      time.Time `json:"timestamp"`
    Message        string    `json:"message"`
    StackTrace     string    `json:"stack_trace"`
    Module         string    `json:"module"`
    ErrorCode      string    `json:"error_code"`
    ManagerContext string    `json:"manager_context"`
    Severity       string    `json:"severity"`
}
```

## ÉTAT ACTUEL DEPENDENCYMANAGER ❌

### Limitations Identifiées
1. **Interface ErrorManager Incomplète** : Manque `CatalogError` et `ValidateErrorEntry`
2. **Signature ProcessError Non-Standard** : `ProcessError(ctx, err, hooks)` vs `ProcessError(ctx, err, component, operation, hooks)`
3. **Gestion Severity Fixe** : Hardcodé à "medium" au lieu d'un système dynamique
4. **Codes d'Erreur Génériques** : "DEP_ERROR_001" au lieu de codes contextuels
5. **Validation ErrorEntry Manquante** : Pas de validation des entrées d'erreur

### Structure Actuelle (À Refactoriser)
```go
// ACTUEL - À AMÉLIORER
func (em *ErrorManager) ProcessError(ctx context.Context, err error, hooks *ErrorHooks) error {
    entry := ErrorEntry{
        ErrorCode:      "DEP_ERROR_001",  // ❌ Générique
        Severity:       "medium",         // ❌ Fixe
        // ... autres champs
    }
    // ❌ Pas de validation
    // ❌ Pas de catalogage séparé
}
```

## PLAN D'INTÉGRATION CONFIGMANAGER → DEPENDENCYMANAGER

### Étape 2.1 : Adaptation Interface ErrorManager ✅ PRÊT

#### Micro-étape 2.1.1 : Copier l'Interface ErrorManager
- [x] **Source** : `config-manager/config_manager.go` lignes 25-29
- [ ] **Action** : Remplacer l'interface ErrorManager actuelle dans DependencyManager
- [ ] **Impact** : Ajout des méthodes `CatalogError` et `ValidateErrorEntry`

#### Micro-étape 2.1.2 : Adapter Signature ProcessError
- [x] **Signature Cible** : `ProcessError(ctx context.Context, err error, component, operation string, hooks *ErrorHooks) error`
- [ ] **Action** : Modifier toutes les appelations `ProcessError` pour inclure `component` et `operation`
- [ ] **Contextes DependencyManager** : 
  - `component="dependency-resolution"` + `operation="list|add|remove|update"`
  - `component="go-mod-operation"` + `operation="read|parse|write"`
  - `component="vulnerability-scan"` + `operation="audit"`

#### Micro-étape 2.1.3 : Implémenter CatalogError et ValidateErrorEntry
- [x] **Source** : ConfigManager lignes 147-177 (CatalogError) et 179-199 (ValidateErrorEntry)
- [ ] **Action** : Copier et adapter ces méthodes au contexte DependencyManager
- [ ] **Adaptation** : Changer `module="config-manager"` → `module="dependency-manager"`

### Étape 2.2 : Standardisation Codes d'Erreur ✅ DÉFINI

#### Codes d'Erreur DependencyManager Spécialisés
```go
// Dependency Resolution Errors
DEP_RESOLUTION_001  = "dependency-list-failed"
DEP_RESOLUTION_002  = "dependency-add-failed" 
DEP_RESOLUTION_003  = "dependency-remove-failed"
DEP_RESOLUTION_004  = "dependency-update-failed"

// Go Mod Operation Errors
DEP_GOMOD_001      = "go-mod-read-failed"
DEP_GOMOD_002      = "go-mod-parse-failed"
DEP_GOMOD_003      = "go-mod-write-failed"
DEP_GOMOD_004      = "go-mod-backup-failed"

// Vulnerability Scan Errors
DEP_VULN_001       = "vulnerability-scan-failed"
DEP_VULN_002       = "vulnerability-found"
DEP_VULN_003       = "govulncheck-unavailable"

// Configuration Errors
DEP_CONFIG_001     = "config-load-failed"
DEP_CONFIG_002     = "config-validation-failed"
```

#### Micro-étape 2.2.1 : Implémenter generateErrorCode
- [x] **Source** : ConfigManager fonction `generateErrorCode(component, operation)`
- [ ] **Action** : Créer la mapping des codes d'erreur contextuels
- [ ] **Exemple** : `component="go-mod-operation"` + `operation="read"` → `"DEP_GOMOD_001"`

#### Micro-étape 2.2.2 : Implémenter determineSeverity
- [x] **Source** : ConfigManager fonction `determineSeverity(err)` lignes 201-218
- [ ] **Action** : Adapter les patterns de détection de sévérité au contexte DependencyManager
- [ ] **Patterns DependencyManager** :
  - `critical`: Corruption go.mod, erreurs de parsing fatales
  - `high`: Vulnérabilités critiques, échecs d'opérations destructives
  - `medium`: Échecs de résolution, problèmes de network
  - `low`: Avertissements, configurations par défaut

### Étape 2.3 : Migration PowerShell Integration ⚠️ PLANIFIÉ

#### PowerShell Error Handling Improvements
- [ ] **Objectif** : Améliorer l'intégration PowerShell avec ErrorManager standardisé
- [ ] **Action** : Modifier les scripts PowerShell pour envoyer des erreurs structurées
- [ ] **Format** : JSON structuré compatible avec ErrorEntry

## IMPLÉMENTATION IMMÉDIATE

### Priorité 1 : Interface ErrorManager (🚀 DÉMARRAGE)
```go
// NOUVEAU - Basé sur ConfigManager ✅ Testé
type ErrorManager interface {
    ProcessError(ctx context.Context, err error, component, operation string, hooks *ErrorHooks) error
    CatalogError(entry ErrorEntry) error
    ValidateErrorEntry(entry ErrorEntry) error
}
```

### Priorité 2 : Codes d'Erreur Contextuels (🔄 EN COURS)
```go
// NOUVEAU - Codes spécialisés DependencyManager
func generateErrorCode(component, operation string) string {
    switch component {
    case "dependency-resolution":
        switch operation {
        case "list": return "DEP_RESOLUTION_001"
        case "add": return "DEP_RESOLUTION_002"
        // ...
        }
    // ...
    }
}
```

### Priorité 3 : Validation et Catalogage (⏳ SUIVANT)
```go
// NOUVEAU - Basé sur ConfigManager patterns validés
func (em *ErrorManagerImpl) ValidateErrorEntry(entry ErrorEntry) error {
    // Copie directe ConfigManager avec adaptations contextuelles
}

func (em *ErrorManagerImpl) CatalogError(entry ErrorEntry) error {
    // Copie directe ConfigManager avec module="dependency-manager"
}
```

## VALIDATION ET TESTS

### Tests de Conformité ConfigManager
- [ ] **Test Interface** : Vérifier compatibilité signature ErrorManager
- [ ] **Test Codes Erreur** : Valider génération codes contextuels  
- [ ] **Test Severity** : Vérifier détection dynamique de sévérité
- [ ] **Test Validation** : Confirmer validation ErrorEntry

### Tests d'Intégration
- [ ] **Test Cross-Manager** : DependencyManager ↔ ConfigManager ErrorManager
- [ ] **Test PowerShell** : Scripts → ErrorManager structuré
- [ ] **Test Backwards Compatibility** : Compatibilité avec code existant

## LIVRABLES

### Documentation
- [x] **Plan d'Intégration** : Ce document avec patterns ConfigManager adaptés
- [ ] **Guide Migration** : Instructions détaillées pour migration
- [ ] **Tests Validés** : Suite de tests confirmant conformité ConfigManager

### Code
- [ ] **ErrorManager Interface** : Interface standardisée conforme ConfigManager
- [ ] **Error Codes** : Système de codes contextuels DependencyManager
- [ ] **Validation System** : Validation ErrorEntry robuste
- [ ] **PowerShell Integration** : Scripts adaptés ErrorManager standardisé

## RÉFÉRENCES

### ConfigManager ErrorManager (✅ 100% Testé)
- **Fichier** : `development/managers/config-manager/config_manager.go`
- **Interface** : Lignes 25-29
- **Implémentation** : Lignes 85-218  
- **Tests** : Entièrement validé et opérationnel

### DependencyManager Actuel (❌ À Refactoriser)
- **Fichier** : `development/managers/dependency-manager/modules/dependency_manager.go`
- **ErrorManager** : Lignes 71-126 (structure incomplète)
- **ProcessError** : Lignes 95-126 (signature non-standard)

**STATUT** : Ready to implement - ConfigManager model provides complete roadmap for DependencyManager ErrorManager integration.
