// Package resolver implémente le système de résolution automatique d'erreurs
package resolver

import (
	"context"
	"fmt"
	"go/ast"
	"go/format"
	"go/parser"
	"go/token"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"time"

	"error-resolution-pipeline/pkg/detector"
)

// AutoResolver représente le moteur de résolution automatique
type AutoResolver struct {
	config    *Config
	fileSet   *token.FileSet
	fixers    map[string]ErrorFixer
	knowledge *KnowledgeBase
}

// Config contient la configuration du résolveur
type Config struct {
	SafeFixesOnly       bool `json:"safe_fixes_only"`
	BackupBeforeFix     bool `json:"backup_before_fix"`
	MaxMutationsPerFile int  `json:"max_mutations_per_file"`
	DryRun              bool `json:"dry_run"`
}

// ErrorFixer interface pour les fixers spécifiques
type ErrorFixer interface {
	CanFix(error detector.DetectedError) bool
	Fix(ctx context.Context, error detector.DetectedError, source []byte) (*FixResult, error)
	Safety() SafetyLevel
}

// SafetyLevel définit le niveau de sécurité d'un fix
type SafetyLevel int

const (
	SafetyUnsafe SafetyLevel = iota
	SafetyCautious
	SafetySafe
	SafetyGuaranteed
)

// FixResult contient le résultat d'une correction
type FixResult struct {
	Applied     bool              `json:"applied"`
	ModifiedAST *ast.File         `json:"-"`
	Changes     []ChangeDetail    `json:"changes"`
	Confidence  float64           `json:"confidence"`
	Backup      string            `json:"backup_path,omitempty"`
	Warnings    []string          `json:"warnings"`
	Applied_At  time.Time         `json:"applied_at"`
}

// ChangeDetail décrit une modification apportée
type ChangeDetail struct {
	Type        string `json:"type"`
	Line        int    `json:"line"`
	Column      int    `json:"column"`
	OldContent  string `json:"old_content"`
	NewContent  string `json:"new_content"`
	Description string `json:"description"`
}

// KnowledgeBase contient les patterns de résolution
type KnowledgeBase struct {
	Patterns   map[string]FixPattern `json:"patterns"`
	UpdatedAt  time.Time             `json:"updated_at"`
	Version    string                `json:"version"`
}

// FixPattern définit un pattern de résolution
type FixPattern struct {
	Name         string            `json:"name"`
	ErrorTypes   []string          `json:"error_types"`
	Template     string            `json:"template"`
	Safety       SafetyLevel       `json:"safety"`
	Preconditions []string         `json:"preconditions"`
	Examples     []FixExample      `json:"examples"`
}

// FixExample contient un exemple de fix
type FixExample struct {
	Before      string `json:"before"`
	After       string `json:"after"`
	Description string `json:"description"`
}

// NewAutoResolver crée une nouvelle instance du résolveur
func NewAutoResolver(config *Config) *AutoResolver {
	resolver := &AutoResolver{
		config:  config,
		fileSet: token.NewFileSet(),
		fixers:  make(map[string]ErrorFixer),
		knowledge: &KnowledgeBase{
			Patterns:  make(map[string]FixPattern),
			UpdatedAt: time.Now(),
			Version:   "1.0.0",
		},
	}

	// Enregistrer les fixers par défaut
	resolver.RegisterFixer("unused_variable", &UnusedVariableFixer{})
	resolver.RegisterFixer("type_mismatch", &TypeMismatchFixer{})
	resolver.RegisterFixer("high_complexity", &ComplexityFixer{})

	// Charger la base de connaissances
	resolver.loadKnowledgeBase()

	return resolver
}

// RegisterFixer enregistre un nouveau fixer
func (ar *AutoResolver) RegisterFixer(errorType string, fixer ErrorFixer) {
	ar.fixers[errorType] = fixer
}

// ResolveErrors résout automatiquement une liste d'erreurs
func (ar *AutoResolver) ResolveErrors(ctx context.Context, errors []detector.DetectedError) ([]FixResult, error) {
	var results []FixResult
	fileGroups := ar.groupErrorsByFile(errors)

	for filePath, fileErrors := range fileGroups {
		fileResults, err := ar.resolveFileErrors(ctx, filePath, fileErrors)
		if err != nil {
			return nil, fmt.Errorf("failed to resolve errors in file %s: %w", filePath, err)
		}
		results = append(results, fileResults...)
	}

	return results, nil
}

// resolveFileErrors résout les erreurs dans un fichier spécifique
func (ar *AutoResolver) resolveFileErrors(ctx context.Context, filePath string, errors []detector.DetectedError) ([]FixResult, error) {
	var results []FixResult

	// Lire le fichier source
	source, err := ioutil.ReadFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read file %s: %w", filePath, err)
	}

	// Créer un backup si nécessaire
	var backupPath string
	if ar.config.BackupBeforeFix {
		backupPath, err = ar.createBackup(filePath, source)
		if err != nil {
			return nil, fmt.Errorf("failed to create backup: %w", err)
		}
	}

	currentSource := source
	mutationCount := 0

	// Traiter chaque erreur
	for _, error := range errors {
		if mutationCount >= ar.config.MaxMutationsPerFile {
			break
		}

		select {
		case <-ctx.Done():
			return results, ctx.Err()
		default:
		}

		fixer, exists := ar.fixers[error.Type]
		if !exists {
			continue
		}

		// Vérifier la sécurité du fix
		if ar.config.SafeFixesOnly && fixer.Safety() < SafetySafe {
			continue
		}

		if !fixer.CanFix(error) {
			continue
		}

		fixResult, err := fixer.Fix(ctx, error, currentSource)
		if err != nil {
			fixResult = &FixResult{
				Applied:    false,
				Confidence: 0.0,
				Warnings:   []string{err.Error()},
				Applied_At: time.Now(),
			}
		}

		if fixResult.Applied {
			// Appliquer les changements
			if !ar.config.DryRun {
				newSource, err := ar.applyFix(currentSource, fixResult)
				if err != nil {
					fixResult.Warnings = append(fixResult.Warnings, "Failed to apply fix: "+err.Error())
				} else {
					currentSource = newSource
					mutationCount++
				}
			}
			fixResult.Backup = backupPath
		}

		results = append(results, *fixResult)
	}

	// Écrire le fichier modifié
	if !ar.config.DryRun && mutationCount > 0 {
		err = ioutil.WriteFile(filePath, currentSource, 0644)
		if err != nil {
			return results, fmt.Errorf("failed to write modified file: %w", err)
		}
	}

	return results, nil
}

// createBackup crée une sauvegarde du fichier
func (ar *AutoResolver) createBackup(filePath string, content []byte) (string, error) {
	backupDir := filepath.Join(filepath.Dir(filePath), ".backup")
	err := os.MkdirAll(backupDir, 0755)
	if err != nil {
		return "", err
	}

	timestamp := time.Now().Format("20060102_150405")
	backupName := fmt.Sprintf("%s_%s.backup", filepath.Base(filePath), timestamp)
	backupPath := filepath.Join(backupDir, backupName)

	err = ioutil.WriteFile(backupPath, content, 0644)
	if err != nil {
		return "", err
	}

	return backupPath, nil
}

// applyFix applique un fix au code source
func (ar *AutoResolver) applyFix(source []byte, fixResult *FixResult) ([]byte, error) {
	if fixResult.ModifiedAST == nil {
		return source, fmt.Errorf("no modified AST provided")
	}

	var buf strings.Builder
	err := format.Node(&buf, ar.fileSet, fixResult.ModifiedAST)
	if err != nil {
		return nil, fmt.Errorf("failed to format modified AST: %w", err)
	}

	return []byte(buf.String()), nil
}

// groupErrorsByFile groupe les erreurs par fichier
func (ar *AutoResolver) groupErrorsByFile(errors []detector.DetectedError) map[string][]detector.DetectedError {
	groups := make(map[string][]detector.DetectedError)
	
	for _, error := range errors {
		groups[error.File] = append(groups[error.File], error)
	}
	
	return groups
}

// loadKnowledgeBase charge la base de connaissances
func (ar *AutoResolver) loadKnowledgeBase() {
	// Patterns de base pour les fixes courants
	ar.knowledge.Patterns["unused_variable_remove"] = FixPattern{
		Name:       "Remove Unused Variable",
		ErrorTypes: []string{"unused_variable"},
		Template:   "// Variable {{.name}} removed - was unused",
		Safety:     SafetySafe,
		Preconditions: []string{
			"Variable has no references",
			"Not a package-level variable",
		},
		Examples: []FixExample{
			{
				Before:      "var unusedVar int",
				After:       "// Variable unusedVar removed - was unused",
				Description: "Remove completely unused variable declaration",
			},
		},
	}

	ar.knowledge.Patterns["complexity_extract_method"] = FixPattern{
		Name:       "Extract Method for Complexity",
		ErrorTypes: []string{"high_complexity"},
		Template:   "func {{.extractedMethodName}}() {\n\t{{.extractedCode}}\n}",
		Safety:     SafetyCautious,
		Preconditions: []string{
			"Function complexity > 10",
			"Identifiable code block for extraction",
		},
	}
}

// String retourne la représentation string du niveau de sécurité
func (sl SafetyLevel) String() string {
	switch sl {
	case SafetyUnsafe:
		return "unsafe"
	case SafetyCautious:
		return "cautious"
	case SafetySafe:
		return "safe"
	case SafetyGuaranteed:
		return "guaranteed"
	default:
		return "unknown"
	}
}
