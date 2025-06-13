# Documentation Complète de l'Écosystème Tools - Manager Toolkit v2.0.0

> **IMPORTANT: CE DOCUMENT EST ARCHIVÉ**  
> Une nouvelle version de cette documentation est disponible pour la version v3.0.0.  
> Veuillez consulter [TOOLS_ECOSYSTEM_DOCUMENTATION_V3.md](./TOOLS_ECOSYSTEM_DOCUMENTATION_V3.md) pour la documentation la plus récente.

## Description Générique pour un Écosystème d'Outils de Développement Modulaire

Ce document présente une analyse modulaire, robuste et réutilisable de l'écosystème `development\managers\tools`, respectant strictement les principes DRY (Don't Repeat Yourself), KISS (Keep It Simple, Stupid), et SOLID. L'écosystème est composé d'outils spécialisés pour l'analyse, la migration, et la maintenance du code, coordonnés par un Manager Toolkit unifié pour la centralisation et la gestion des erreurs.

### Instructions Générales

- **Structure modulaire** : Organisation en modules indépendants (analyse, migration, utilitaires, tests) pour faciliter la réutilisation et l'extensibilité
- **Principes directeurs** :
  - **DRY** : Centralisation de la gestion des erreurs, des configurations, et des métriques
  - **KISS** : Interfaces simples, descriptions claires, et exemples accessibles
  - **SOLID** : Responsabilité unique par outil, interfaces ségrégées, et injection de dépendances

---

## Module 1 : Introduction

### Objectif

Présentation de l'écosystème d'outils de développement pour l'automatisation de la maintenance, l'analyse d'interfaces, et la migration de code dans le contexte du projet Email Sender Manager.

### Contexte Projet

- **Projet** : Email Sender Manager - Tools Ecosystem
- **Objectif** : Automatisation de la maintenance de code, analyse d'interfaces, migration professionnelle
- **Langages** : Go 1.21
- **Environnements** : Dev, Staging, Prod
- **Dépendances** : golang.org/x/tools, golang.org/x/mod
- **Intégrations** : AST parsing, File system operations, Git backup systems

### Technologies Utilisées

```go
// Core dependencies
golang.org/x/tools v0.21.0  // AST analysis and code manipulation
golang.org/x/mod v0.14.0    // Module analysis and management
Standard Library:
- go/ast, go/parser, go/token  // Code parsing and analysis
- path/filepath, os, io/fs     // File system operations
- encoding/json, time, context // Configuration and execution
```plaintext
---

## Module 2 : Architecture

### Hiérarchie

L'écosystème est structuré en trois niveaux :

#### Core Tools

- **Manager Toolkit** : Point d'entrée unifié pour tous les outils
- **Toolkit Core** : Gestionnaire central des opérations et configurations

#### Analysis Tools  

- **Interface Analyzer Pro** : Analyse avancée des interfaces avec métriques de qualité
- **Advanced Utilities** : Utilitaires pour la correction d'imports et suppression de doublons

#### Migration Tools

- **Interface Migrator Pro** : Migration professionnelle avec sauvegarde et validation

### Tableau Comparatif des Outils

| Outil | Rôle | Interfaces Publiques | État (%) | Intégration ErrorManager |
|-------|------|---------------------|----------|-------------------------|
| **Manager Toolkit** | Point d'entrée unifié | `ExecuteOperation`, `showHelp` | 100% | ✅ Core Service |
| **Toolkit Core** | Gestion centrale | `NewManagerToolkit`, `LoadOrCreateConfig` | 100% | ✅ Implémenté |
| **Interface Analyzer Pro** | Analyse avancée interfaces | `AnalyzeInterfaces`, `GenerateReport` | 95% | ✅ Interface prête |
| **Interface Migrator Pro** | Migration professionnelle | `ExecuteMigration`, `CreateMigrationPlan` | 90% | ✅ Interface prête |
| **Advanced Utilities** | Utilitaires de correction | `FixAllImports`, `RemoveAllDuplicates` | 85% | ✅ Interface prête |

### Flux de Données

```plaintext
[Manager Toolkit] --> [Toolkit Core] --> [Logger]
       |                    |                |
       +--> [Interface Analyzer Pro] -------+
       |                    |                |
       +--> [Interface Migrator Pro] -------+
       |                    |                |
       +--> [Advanced Utilities] -----------+
                           |
                    [ErrorManager & Stats]
```plaintext
---

## Module 3 : Interfaces des Outils

### Interface Générique

```go
// ToolkitOperation represents the common interface for all toolkit operations
type ToolkitOperation interface {
    Execute(ctx context.Context, options *OperationOptions) error
    Validate(ctx context.Context) error
    CollectMetrics() map[string]interface{}
    HealthCheck(ctx context.Context) error
}

// Common structures
type OperationOptions struct {
    Target string  // Specific file or directory target
    Output string  // Output file for reports
    Force  bool    // Force operations without confirmation
}
```plaintext
### Outils Clés

#### 1. Manager Toolkit (Point d'entrée principal)

```go
type ManagerToolkit struct {
    Config    *ToolkitConfig
    Logger    *Logger
    FileSet   *token.FileSet
    BaseDir   string
    StartTime time.Time
    Stats     *ToolkitStats
}

// Interfaces publiques principales
func (mt *ManagerToolkit) ExecuteOperation(ctx context.Context, op Operation, options *OperationOptions) error
func (mt *ManagerToolkit) PrintFinalStats()
func (mt *ManagerToolkit) Close() error
```plaintext
**Rôle principal** : Coordonner l'exécution de toutes les opérations et centraliser la gestion des statistiques.

**Exemple de test unitaire** :
```go
func TestManagerToolkit_ExecuteOperation(t *testing.T) {
    tmpDir := t.TempDir()
    toolkit, err := NewManagerToolkit(tmpDir, "", false)
    require.NoError(t, err)
    defer toolkit.Close()
    
    ctx := context.Background()
    err = toolkit.ExecuteOperation(ctx, OpAnalyze, &OperationOptions{
        Target: tmpDir,
        Output: "analysis.json",
    })
    assert.NoError(t, err)
    assert.Greater(t, toolkit.Stats.FilesAnalyzed, 0)
}
```plaintext
#### 2. Interface Analyzer Pro

```go
type InterfaceAnalyzer struct {
    BaseDir string
    FileSet *token.FileSet
    Logger  *Logger
    Stats   *ToolkitStats
    DryRun  bool
}

// Interfaces publiques
func (ia *InterfaceAnalyzer) AnalyzeInterfaces() (*AnalysisReport, error)
func (ia *InterfaceAnalyzer) GenerateReport(report *AnalysisReport, outputPath string) error
func (ia *InterfaceAnalyzer) ValidateInterfaceQuality(iface Interface) *QualityScore
```plaintext
**Rôle principal** : Analyser la qualité des interfaces avec métriques de complexité et recommandations d'amélioration.

**Exemple de test unitaire** :
```go
func TestInterfaceAnalyzer_AnalyzeInterfaces(t *testing.T) {
    analyzer := &InterfaceAnalyzer{
        BaseDir: "testdata",
        FileSet: token.NewFileSet(),
        Logger:  &MockLogger{},
        Stats:   &ToolkitStats{},
    }
    
    report, err := analyzer.AnalyzeInterfaces()
    assert.NoError(t, err)
    assert.NotNil(t, report)
    assert.Greater(t, len(report.Interfaces), 0)
}
```plaintext
#### 3. Interface Migrator Pro

```go
type InterfaceMigrator struct {
    BaseDir       string
    InterfacesDir string
    FileSet       *token.FileSet
    Logger        *Logger
    Stats         *ToolkitStats
    DryRun        bool
    BackupDir     string
}

// Structure de résultats de migration
type MigrationResults struct {
    TotalFiles           int           `json:"total_files"`           // Nombre total de fichiers analysés
    InterfacesMigrated   int           `json:"interfaces_migrated"`   // Nombre d'interfaces migrées
    SuccessfulMigrations []string      `json:"successful_migrations"` // Chemins des fichiers migrés avec succès
    FailedMigrations     []string      `json:"failed_migrations"`     // Chemins des fichiers dont la migration a échoué
    BackupFiles          []string      `json:"backup_files"`          // Chemins des fichiers de sauvegarde créés
    Duration             time.Duration `json:"duration"`              // Durée totale de l'opération
}

// Constructeur sécurisé avec validation complète des paramètres
func NewInterfaceMigratorPro(baseDir string, logger *Logger, verbose bool) (*InterfaceMigrator, error)

// Interfaces publiques principales
func (im *InterfaceMigrator) ExecuteMigration() error
func (im *InterfaceMigrator) CreateMigrationPlan() (*MigrationPlan, error)
func (im *InterfaceMigrator) ValidateMigration() error
func (im *InterfaceMigrator) MigrateInterfaces(ctx context.Context, sourceDir, targetDir, newPackage string) (*MigrationResults, error)
func (im *InterfaceMigrator) GenerateMigrationReport(results *MigrationResults, format string) (string, error)

// Méthodes de support
func (im *InterfaceMigrator) createBackup(filePath string) (string, error)
func (im *InterfaceMigrator) restoreFromBackup(filePath, backupPath string) error
func (im *InterfaceMigrator) validateMigration(filePath string) bool
```plaintext
**Rôle principal** : Migrer les interfaces vers des modules dédiés avec sauvegarde automatique, validation syntaxique et génération de rapports complets.

**Spécifications techniques** :
- **Identification des interfaces** : Utilisation d'expressions régulières robustes `regexp.MustCompile(\`package\\s+(\\w+)\`)` pour extraire les noms de packages
- **Sécurité des migrations** : Création automatique de sauvegardes datées dans `.backups/migration-{timestamp}`
- **Validation syntaxique** : Vérification post-migration via `parser.ParseFile()` pour garantir la validité du code
- **Formats de rapport** : Support JSON, YAML et texte formaté avec métriques complètes

**Interactions entre composants** :
- **Dépendance avec Logger** : Injection du logger dans le constructeur pour une centralisation des logs
- **Utilisation des Stats** : Mise à jour des métriques globales dans la structure `ToolkitStats` partagée
- **Intégration AST** : Utilisation du `FileSet` partagé pour garantir la cohérence des positions de code

**Gestion des erreurs** :
- **Validation précoce** : Vérification de l'existence des répertoires et de la validité des paramètres
- **Rollback automatique** : Possibilité de restaurer depuis les sauvegardes en cas d'échec
- **Traçabilité** : Enregistrement détaillé des succès et échecs dans la structure `MigrationResults`

**Exemple de test unitaire** :
```go
func TestInterfaceMigrator_MigrateInterfaces(t *testing.T) {
    tempDir, err := ioutil.TempDir("", "migrate_test")
    if err != nil {
        t.Fatalf("Failed to create temp dir: %v", err)
    }
    defer os.RemoveAll(tempDir)

    // Créer des répertoires source et cible
    sourceDir := filepath.Join(tempDir, "source")
    targetDir := filepath.Join(tempDir, "target")
    os.MkdirAll(sourceDir, 0755)
    os.MkdirAll(targetDir, 0755)

    // Créer un fichier d'interface de test
    interfaceContent := `package oldpackage

type UserManager interface {
    CreateUser(name string) (*User, error)
    GetUser(id int) (*User, error)
    DeleteUser(id int) error
}

type User struct {
    ID   int
    Name string
}`

    // Écrire le fichier de test
    sourceFile := filepath.Join(sourceDir, "user_manager.go")
    err = ioutil.WriteFile(sourceFile, []byte(interfaceContent), 0644)
    if err != nil {
        t.Fatalf("Failed to create source file: %v", err)
    }

    // Initialiser le migrateur
    migrator, err := NewInterfaceMigratorPro(tempDir, nil, false)
    if err != nil {
        t.Fatalf("Failed to create migrator: %v", err)
    }
    
    // Exécuter la migration
    ctx := context.Background()
    results, err := migrator.MigrateInterfaces(ctx, sourceDir, targetDir, "newpackage")
    if err != nil {
        t.Fatalf("Migration failed: %v", err)
    }
    
    // Vérifier les résultats
    assert.Equal(t, 1, results.TotalFiles)
    assert.Equal(t, 1, results.InterfacesMigrated)
    assert.Contains(t, results.SuccessfulMigrations, sourceFile)
    
    // Vérifier le contenu du fichier migré
    targetFile := filepath.Join(targetDir, "user_manager.go")
    content, _ := ioutil.ReadFile(targetFile)
    assert.Contains(t, string(content), "package newpackage")
}
```plaintext
### Mécanismes de Migration de Package Détaillés

L'implémentation récente du `InterfaceMigrator` introduit plusieurs améliorations clés dans le processus de migration :

1. **Détection Robuste des Packages**
   ```go
   // Détection précise du package d'origine
   if matches := regexp.MustCompile(`package\s+(\w+)`).FindStringSubmatch(content); len(matches) > 1 {
       originalPackage = matches[1]
   }
   
   // Remplacement ciblé de la déclaration de package
   if originalPackage != "" {
       content = strings.ReplaceAll(content, "package "+originalPackage, "package "+newPackage)
   }
   ```
   Cette approche garantit que seules les déclarations de package exactes sont modifiées, évitant les remplacements accidentels dans les commentaires ou chaînes de caractères.

2. **Traitement Récursif des Sous-répertoires**
   La méthode `MigrateInterfaces` utilise `filepath.WalkDir` pour traverser récursivement tous les sous-répertoires, préservant la structure hiérarchique dans le répertoire cible :
   ```go
   // Pour chaque fichier trouvé
   relPath, _ := filepath.Rel(sourceDir, path)
   targetPath := filepath.Join(targetDir, relPath)
   
   // Création des sous-répertoires nécessaires
   if err := os.MkdirAll(filepath.Dir(targetPath), 0755); err != nil {
       // Gestion des erreurs...
   }
   ```

3. **Validation Syntaxique Post-Migration**
   Chaque fichier migré est validé en utilisant le parser Go pour garantir sa validité syntaxique :
   ```go
   func (im *InterfaceMigrator) validateMigration(filePath string) bool {
       data, err := os.ReadFile(filePath)
       if err != nil {
           return false
       }
       
       // Analyse syntaxique via l'AST Go
       _, err = parser.ParseFile(im.FileSet, filePath, data, parser.ParseComments)
       return err == nil
   }
   ```

4. **Génération de Rapports Multi-formats**
   Les rapports de migration sont disponibles en trois formats via une seule interface :
   ```go
   func (im *InterfaceMigrator) GenerateMigrationReport(results *MigrationResults, format string) (string, error) {
       switch format {
       case "json":
           return im.generateJSONReport(results)
       case "yaml":
           return im.generateYAMLReport(results)
       case "text":
           return im.generateTextReport(results)
       default:
           return "", fmt.Errorf("unsupported format: %s", format)
       }
   }
   ```

### Stratégies de Migration Avancées

L'`InterfaceMigrator` utilise plusieurs stratégies avancées pour garantir des migrations sans erreurs :

1. **Mécanisme de Transaction avec Sauvegarde/Restauration**

   Le système implémente un mécanisme pseudo-transactionnel pour les migrations :
   ```go
   // Création d'une sauvegarde avant toute modification
   backupPath, err := im.createBackup(filePath)
   if err != nil {
       return err
   }

   // Validation post-migration avec restauration automatique en cas d'erreur
   if !im.validateMigration(filePath) {
       im.restoreFromBackup(filePath, backupPath)
       return fmt.Errorf("migration validation failed for %s", filePath)
   }
   ```

2. **Détection d'Interfaces Intelligente**

   L'implémentation utilise une combinaison de vérifications simples et d'analyses AST pour détecter les interfaces :
   ```go
   // Vérification rapide de la présence probable d'interfaces
   if strings.Contains(content, "interface {") {
       results.InterfacesMigrated++
       
       // Logique de migration détaillée...
   }
   ```

3. **Manipulation Intelligente des Packages**

   La migration gère plusieurs variantes de déclarations de packages :
   ```go
   // Extraction du nom de package par regexp
   originalPackage := ""
   if matches := regexp.MustCompile(`package\s+(\w+)`).FindStringSubmatch(content); len(matches) > 1 {
       originalPackage = matches[1]
   }

   // Mise à jour du nom de package avec fallback intelligent
   if originalPackage != "" {
       content = strings.ReplaceAll(content, "package "+originalPackage, "package "+newPackage)
   } else {
       // Fallback si la déclaration du package n'est pas trouvée
       content = strings.ReplaceAll(content, "package "+filepath.Base(sourceDir), "package "+newPackage)
   }
   ```

4. **Résilience et Gestion des Erreurs**

   Le système est conçu pour être résilient aux erreurs partielles :
   ```go
   // La migration continue même si certains fichiers échouent
   if err := os.WriteFile(targetPath, []byte(content), 0644); err != nil {
       results.FailedMigrations = append(results.FailedMigrations, path)
       // Pas de return: continue avec le fichier suivant
   } else {
       results.SuccessfulMigrations = append(results.SuccessfulMigrations, path)
   }
   ```

### Flux de Traitement Complet

Le processus complet de migration suit ces étapes :

1. **Initialisation et Validation des Paramètres**
   - Vérification de l'existence des répertoires source
   - Création des répertoires cible si nécessaires
   - Initialisation des compteurs et métriques

2. **Parcours et Analyse des Fichiers**
   - Traversée récursive avec `filepath.WalkDir`
   - Filtrage des fichiers Go uniquement
   - Détection des interfaces par analyse de contenu

3. **Application des Transformations**
   - Extraction du package d'origine par regexp
   - Mise à jour du nom de package
   - Préservation de la structure des sous-répertoires

4. **Validation et Sauvegarde**
   - Création de sauvegardes des fichiers originaux
   - Validation syntaxique des fichiers transformés
   - Restauration automatique en cas d'échec

5. **Rapport et Métriques**
   - Collection des métriques détaillées
   - Génération de rapports dans le format demandé
   - Production des statistiques de performance

### Tableau Détaillé des Interactions des Options

| Option | Méthodes Affectées | Comportement |
|--------|-------------------|-------------|
| `verbose` | `NewInterfaceMigratorPro` | Configure le niveau de détail du logger |
| `DryRun` | `MigrateInterfaces` | Simule les opérations sans écrire les fichiers |
| `ctx` (contexte) | `MigrateInterfaces` | Permet l'annulation de l'opération |
| Format de rapport | `GenerateMigrationReport` | Détermine le format de sortie (json, yaml, text) |

### Cas d'Usages Avancés et Exemples de Code

1. **Migration Conditionnelle**
   
   Migration uniquement des fichiers contenant certains types d'interfaces :
   ```go
   ctx := context.Background()
   
   // Préparer un contexte avec timeout
   ctx, cancel := context.WithTimeout(ctx, 5*time.Minute)
   defer cancel()
   
   // Exécuter la migration avec analyse préalable
   analyzer := &InterfaceAnalyzer{BaseDir: baseDir}
   report, _ := analyzer.AnalyzeInterfaces()
   
   // Filtrer uniquement les interfaces de qualité élevée
   highQualityInterfaces := []string{}
   for _, iface := range report.Interfaces {
       score := analyzer.ValidateInterfaceQuality(iface)
       if score.Overall > 0.8 {
           highQualityInterfaces = append(highQualityInterfaces, iface.File)
       }
   }
   
   // Migrer uniquement les fichiers sélectionnés
   for _, filePath := range highQualityInterfaces {
       sourceDir := filepath.Dir(filePath)
       fileName := filepath.Base(filePath)
       migrator, _ := NewInterfaceMigratorPro(baseDir, logger, false)
       migrator.MigrateInterfaces(ctx, sourceDir, targetDir, "interfaces")
   }
   ```

2. **Migration avec Génération de Rapports Personnalisés**

   Utilisation avancée de `GenerateMigrationReport` pour créer des rapports personnalisés :
   ```go
   // Exécuter la migration standard
   migrator, _ := NewInterfaceMigratorPro(baseDir, logger, false)
   results, _ := migrator.MigrateInterfaces(ctx, "./old", "./new", "newpackage")
   
   // Générer des rapports dans différents formats
   jsonReport, _ := migrator.GenerateMigrationReport(results, "json")
   yamlReport, _ := migrator.GenerateMigrationReport(results, "yaml")
   textReport, _ := migrator.GenerateMigrationReport(results, "text")
   
   // Écrire les rapports dans des fichiers
   os.WriteFile("migration_report.json", []byte(jsonReport), 0644)
   os.WriteFile("migration_report.yaml", []byte(yamlReport), 0644)
   os.WriteFile("migration_report.txt", []byte(textReport), 0644)
   ```

3. **Intégration avec Système de Contrôle de Version**

   Intégration avec Git pour les sauvegardes et le suivi :
   ```go
   // Avant la migration
   exec.Command("git", "stash", "save", "pre-migration-backup").Run()
   
   // Exécuter la migration
   migrator, _ := NewInterfaceMigratorPro(baseDir, logger, false)
   results, err := migrator.MigrateInterfaces(ctx, sourceDir, targetDir, "newpackage")
   
   if err != nil {
       // Restauration en cas d'échec
       exec.Command("git", "stash", "pop").Run()
       log.Fatalf("Migration failed: %v", err)
   } else {
       // Commit des changements
       exec.Command("git", "add", ".").Run()
       exec.Command("git", "commit", "-m", "Migrated interfaces to dedicated package").Run()
   }
   ```

### Implémentations de Référence

#### Exemple 1: Migration de Package Complet

Cet exemple montre comment migrer toutes les interfaces d'un package vers un nouveau package dédié :

```go
package main

import (
	"context"
	"fmt"
	"log"
	"time"
)

func MigrateCompletePackage(sourcePackagePath, targetPackagePath, newPackageName string) error {
	// Créer un logger avec timestamp
	logger := &Logger{
		Prefix:  "MIGRATION",
		Verbose: true,
	}
	
	// Initialiser le migrateur avec validation des paramètres
	migrator, err := NewInterfaceMigratorPro(sourcePackagePath, logger, true)
	if err != nil {
		return fmt.Errorf("failed to initialize migrator: %w", err)
	}
	
	// Créer un contexte avec timeout de 10 minutes
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()
	
	// Exécuter la migration avec suivi complet
	startTime := time.Now()
	logger.Info("Starting complete package migration from %s to %s", sourcePackagePath, targetPackagePath)
	
	results, err := migrator.MigrateInterfaces(ctx, sourcePackagePath, targetPackagePath, newPackageName)
	if err != nil {
		return fmt.Errorf("migration failed: %w", err)
	}
	
	// Générer un rapport JSON
	report, _ := migrator.GenerateMigrationReport(results, "json")
	logger.Info("Migration completed in %s", time.Since(startTime))
	logger.Info("Migration report:\n%s", report)
	
	// Validation syntaxique des fichiers migrés
	logger.Info("Validating migrated files...")
	failedValidation := 0
	
	for _, path := range results.SuccessfulMigrations {
		if !migrator.validateMigration(path) {
			logger.Error("Validation failed for %s", path)
			failedValidation++
		}
	}
	
	if failedValidation > 0 {
		return fmt.Errorf("%d files failed validation", failedValidation)
	}
	
	logger.Info("All migrated files validated successfully")
	return nil
}
```plaintext
#### Exemple 2: Migration Sélective avec Critères

Cette implémentation montre comment filtrer les interfaces à migrer en fonction de critères spécifiques :

```go
package main

import (
	"context"
	"fmt"
	"regexp"
	"strings"
}

// Configuration pour migration sélective
type MigrationSelector struct {
	IncludePatterns []string // Expressions régulières pour inclure des interfaces
	ExcludePatterns []string // Expressions régulières pour exclure des interfaces
	MinMethods     int      // Nombre minimum de méthodes pour migrer une interface
}

func MigrateSelectiveInterfaces(sourceDir, targetDir, newPackage string, selector MigrationSelector) (*MigrationResults, error) {
	logger := &Logger{Verbose: true}
	migrator, err := NewInterfaceMigratorPro(".", logger, true)
	if err != nil {
		return nil, err
	}
	
	// Résultats combinés
	combinedResults := &MigrationResults{
		SuccessfulMigrations: []string{},
		FailedMigrations:     []string{},
		BackupFiles:          []string{},
	}
	
	// Compiler les expressions régulières pour les filtres
	includeRegexps := make([]*regexp.Regexp, 0, len(selector.IncludePatterns))
	for _, pattern := range selector.IncludePatterns {
		re, err := regexp.Compile(pattern)
		if err != nil {
			return nil, fmt.Errorf("invalid include pattern %q: %w", pattern, err)
		}
		includeRegexps = append(includeRegexps, re)
	}
	
	excludeRegexps := make([]*regexp.Regexp, 0, len(selector.ExcludePatterns))
	for _, pattern := range selector.ExcludePatterns {
		re, err := regexp.Compile(pattern)
		if err != nil {
			return nil, fmt.Errorf("invalid exclude pattern %q: %w", pattern, err)
		}
		excludeRegexps = append(excludeRegexps, re)
	}
	
	// Analyser les interfaces existantes
	analyzer := &InterfaceAnalyzer{
		BaseDir: sourceDir,
		Logger:  logger,
	}
	
	report, err := analyzer.AnalyzeInterfaces()
	if err != nil {
		return nil, err
	}
	
	// Filtrer les interfaces selon les critères
	selectedFiles := make(map[string]bool)
	for _, iface := range report.Interfaces {
		// Vérifier les critères d'inclusion
		include := len(includeRegexps) == 0 // Include by default if no patterns
		for _, re := range includeRegexps {
			if re.MatchString(iface.Name) {
				include = true
				break
			}
		}
		
		// Vérifier les critères d'exclusion
		for _, re := range excludeRegexps {
			if re.MatchString(iface.Name) {
				include = false
				break
			}
		}
		
		// Vérifier le nombre de méthodes
		if include && len(iface.Methods) >= selector.MinMethods {
			selectedFiles[iface.File] = true
		}
	}
	
	// Migrer uniquement les fichiers sélectionnés
	ctx := context.Background()
	for filePath := range selectedFiles {
		fileDir := strings.TrimSuffix(filePath, "/"+filepath.Base(filePath))
		results, err := migrator.MigrateInterfaces(ctx, fileDir, targetDir, newPackage)
		if err != nil {
			logger.Error("Failed to migrate %s: %v", filePath, err)
			continue
		}
		
		// Combiner les résultats
		combinedResults.TotalFiles += results.TotalFiles
		combinedResults.InterfacesMigrated += results.InterfacesMigrated
		combinedResults.SuccessfulMigrations = append(combinedResults.SuccessfulMigrations, results.SuccessfulMigrations...)
		combinedResults.FailedMigrations = append(combinedResults.FailedMigrations, results.FailedMigrations...)
		combinedResults.BackupFiles = append(combinedResults.BackupFiles, results.BackupFiles...)
	}
	
	return combinedResults, nil
}
```plaintext
#### Exemple 3: Pipeline Complet avec Tests de Validation

Cette implémentation avancée montre un pipeline complet incluant la migration, la validation de compilation et les tests unitaires :

```go
package main

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"time"
}

// MigrationPipeline encapsule le processus complet de migration
func RunMigrationPipeline(sourceDir, targetDir, newPackage string) error {
	logger := &Logger{Verbose: true}
	logger.Info("Starting complete migration pipeline")
	
	// Étape 1: Vérifier les prérequis
	logger.Info("Step 1: Checking prerequisites...")
	if _, err := exec.LookPath("go"); err != nil {
		return fmt.Errorf("go command not found: %w", err)
	}
	
	// Étape 2: Vérifier que le code source compile
	logger.Info("Step 2: Validating source compilation...")
	cmd := exec.Command("go", "build", "./...")
	cmd.Dir = sourceDir
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("source code doesn't compile: %w", err)
	}
	
	// Étape 3: Créer une branche Git temporaire
	logger.Info("Step 3: Creating temporary Git branch...")
	branchName := fmt.Sprintf("interface-migration-%s", time.Now().Format("20060102-150405"))
	createBranchCmd := exec.Command("git", "checkout", "-b", branchName)
	createBranchCmd.Dir = sourceDir
	if err := createBranchCmd.Run(); err != nil {
		logger.Warn("Failed to create Git branch: %v", err)
		// Continue without Git branch
	}
	
	// Étape 4: Exécuter la migration
	logger.Info("Step 4: Running interface migration...")
	migrator, err := NewInterfaceMigratorPro(sourceDir, logger, true)
	if err != nil {
		return err
	}
	
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Minute)
	defer cancel()
	
	results, err := migrator.MigrateInterfaces(ctx, sourceDir, targetDir, newPackage)
	if err != nil {
		return fmt.Errorf("migration failed: %w", err)
	}
	
	// Étape 5: Valider la compilation post-migration
	logger.Info("Step 5: Validating post-migration compilation...")
	cmd = exec.Command("go", "build", "./...")
	cmd.Dir = targetDir
	if err := cmd.Run(); err != nil {
		// Revenir à l'état précédent
		logger.Error("Post-migration compilation failed: %v", err)
		logger.Info("Restoring from backup...")
		
		for i, filePath := range results.SuccessfulMigrations {
			if i < len(results.BackupFiles) {
				migrator.restoreFromBackup(filePath, results.BackupFiles[i])
			}
		}
		
		return fmt.Errorf("post-migration compilation failed: %w", err)
	}
	
	// Étape 6: Exécuter des tests unitaires
	logger.Info("Step 6: Running unit tests...")
	testCmd := exec.Command("go", "test", "./...")
	testCmd.Dir = targetDir
	testOutput, err := testCmd.CombinedOutput()
	if err != nil {
		logger.Error("Unit tests failed:\n%s", string(testOutput))
		return fmt.Errorf("unit tests failed: %w", err)
	}
	
	// Étape 7: Générer rapport final
	logger.Info("Step 7: Generating final report...")
	jsonReport, _ := migrator.GenerateMigrationReport(results, "json")
	reportPath := filepath.Join(targetDir, "migration_report.json")
	if err := os.WriteFile(reportPath, []byte(jsonReport), 0644); err != nil {
		logger.Warn("Failed to write report: %v", err)
	}
	
	logger.Info("Migration pipeline completed successfully!")
	logger.Info("Migration report saved to: %s", reportPath)
	logger.Info("Summary: %d interfaces migrated, %d failures", 
		results.InterfacesMigrated, len(results.FailedMigrations))
	
	return nil
}
```plaintext