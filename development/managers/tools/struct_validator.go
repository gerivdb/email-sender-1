// Manager Toolkit - Struct Validator
// Version: 3.0.0
// Validates Go struct declarations for syntax errors, field types, and JSON tags

package tools

import (
	"context"
	"encoding/json"
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

// StructValidator implémente l'interface ToolkitOperation pour la validation des structures
type StructValidator struct {
	BaseDir string
	FileSet *token.FileSet
	Logger  *Logger
	Stats   *ToolkitStats
	DryRun  bool
}

// ValidationError représente une erreur de validation
type ValidationError struct {
	File        string `json:"file"`
	StructName  string `json:"struct_name"`
	FieldName   string `json:"field_name,omitempty"`
	ErrorType   string `json:"error_type"`
	Description string `json:"description"`
	Line        int    `json:"line"`
}

// ValidationReport représente le rapport de validation
type ValidationReport struct {
	Tool             string            `json:"tool"`
	Timestamp        time.Time         `json:"timestamp"`
	FilesAnalyzed    int               `json:"files_analyzed"`
	StructsAnalyzed  int               `json:"structs_analyzed"`
	ErrorsFound      int               `json:"errors_found"`
	ValidationErrors []ValidationError `json:"validation_errors"`
	Summary          map[string]int    `json:"summary"`
	DurationMs       int64             `json:"duration_ms"`
}

// NewStructValidator crée une nouvelle instance de StructValidator
func NewStructValidator(baseDir string, logger *Logger, dryRun bool) (*StructValidator, error) {
	if baseDir == "" {
		return nil, fmt.Errorf("base directory cannot be empty")
	}

	// Vérifier que le répertoire existe
	if _, err := os.Stat(baseDir); os.IsNotExist(err) {
		return nil, fmt.Errorf("base directory does not exist: %s", baseDir)
	}
	if logger == nil {
		logger = &Logger{verbose: false} // Créer un logger par défaut
	}

	return &StructValidator{
		BaseDir: baseDir,
		FileSet: token.NewFileSet(),
		Logger:  logger,
		Stats:   &ToolkitStats{},
		DryRun:  dryRun,
	}, nil
}

// Execute implémente ToolkitOperation.Execute
func (sv *StructValidator) Execute(ctx context.Context, options *OperationOptions) error {
	sv.Logger.Info("🔍 Starting struct validation on: %s", options.Target)
	startTime := time.Now()

	if sv.FileSet == nil {
		sv.FileSet = token.NewFileSet()
	}

	var errors []ValidationError
	structsAnalyzed := 0
	filesAnalyzed := 0

	err := filepath.Walk(options.Target, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Analyser uniquement les fichiers Go
		if !strings.HasSuffix(path, ".go") || strings.Contains(path, "_test.go") {
			return nil
		}

		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
		}

		sv.Logger.Info("Analyzing file: %s", path)
		filesAnalyzed++

		fileErrors, fileStructs, err := sv.validateFile(path)
		if err != nil {
			sv.Logger.Warn("Failed to analyze file %s: %v", path, err)
			return nil // Continue avec les autres fichiers
		}

		errors = append(errors, fileErrors...)
		structsAnalyzed += fileStructs

		return nil
	})

	if err != nil {
		sv.Logger.Error("Failed to walk directory: %v", err)
		return err
	}

	duration := time.Since(startTime)

	// Mettre à jour les statistiques standardisées
	sv.Stats.FilesAnalyzed += filesAnalyzed
	sv.Stats.ErrorsFixed += len(errors)

	// Générer le rapport si demandé
	if options.Output != "" && !sv.DryRun {
		report := ValidationReport{
			Tool:             "StructValidator",
			Timestamp:        time.Now(),
			FilesAnalyzed:    filesAnalyzed,
			StructsAnalyzed:  structsAnalyzed,
			ErrorsFound:      len(errors),
			ValidationErrors: errors,
			Summary:          sv.createSummary(errors),
			DurationMs:       duration.Milliseconds(),
		}

		if err := sv.generateReport(report, options.Output); err != nil {
			sv.Logger.Error("Failed to generate report: %v", err)
			return err
		}

		sv.Logger.Info("Validation report saved to: %s", options.Output)
	}

	sv.Logger.Info("✅ Struct validation completed: %d files, %d structs, %d errors found in %v",
		filesAnalyzed, structsAnalyzed, len(errors), duration)

	return nil
}

// validateFile valide un fichier Go spécifique
func (sv *StructValidator) validateFile(filePath string) ([]ValidationError, int, error) {
	src, err := os.ReadFile(filePath)
	if err != nil {
		return nil, 0, err
	}

	file, err := parser.ParseFile(sv.FileSet, filePath, src, parser.ParseComments)
	if err != nil {
		return []ValidationError{{
			File:        filePath,
			ErrorType:   "parse_error",
			Description: fmt.Sprintf("Failed to parse file: %v", err),
		}}, 0, nil
	}

	var errors []ValidationError
	structsCount := 0

	// Analyser toutes les déclarations
	for _, decl := range file.Decls {
		if typeDecl, ok := decl.(*ast.GenDecl); ok && typeDecl.Tok == token.TYPE {
			for _, spec := range typeDecl.Specs {
				if typeSpec, ok := spec.(*ast.TypeSpec); ok {
					if structType, ok := typeSpec.Type.(*ast.StructType); ok {
						structsCount++
						structErrors := sv.validateStruct(filePath, typeSpec.Name.Name, structType)
						errors = append(errors, structErrors...)
					}
				}
			}
		}
	}

	return errors, structsCount, nil
}

// validateStruct valide une structure spécifique
func (sv *StructValidator) validateStruct(filePath, structName string, structType *ast.StructType) []ValidationError {
	var errors []ValidationError

	if structType.Fields == nil {
		return errors
	}

	for _, field := range structType.Fields.List {
		// Valider les noms de champs
		if len(field.Names) > 0 {
			for _, name := range field.Names {
				if err := sv.validateFieldName(name.Name); err != nil {
					errors = append(errors, ValidationError{
						File:        filePath,
						StructName:  structName,
						FieldName:   name.Name,
						ErrorType:   "field_name_error",
						Description: err.Error(),
						Line:        sv.FileSet.Position(name.Pos()).Line,
					})
				}
			}
		}

		// Valider les balises JSON
		if field.Tag != nil {
			tagValue := strings.Trim(field.Tag.Value, "`")
			if strings.Contains(tagValue, "json:") {
				if err := sv.validateJSONTag(tagValue); err != nil {
					fieldName := "anonymous"
					if len(field.Names) > 0 {
						fieldName = field.Names[0].Name
					}
					errors = append(errors, ValidationError{
						File:        filePath,
						StructName:  structName,
						FieldName:   fieldName,
						ErrorType:   "json_tag_error",
						Description: err.Error(),
						Line:        sv.FileSet.Position(field.Tag.Pos()).Line,
					})
				}
			}
		}
	}

	return errors
}

// validateFieldName valide le nom d'un champ
func (sv *StructValidator) validateFieldName(fieldName string) error {
	// Vérifier si le nom commence par une majuscule (exported)
	if len(fieldName) == 0 {
		return fmt.Errorf("empty field name")
	}

	// Vérifier la convention de nommage Go
	if matched, _ := regexp.MatchString(`^[A-Z][a-zA-Z0-9]*$`, fieldName); !matched {
		return fmt.Errorf("field name '%s' should follow Go naming conventions (start with uppercase letter)", fieldName)
	}

	return nil
}

// validateJSONTag valide une balise JSON
func (sv *StructValidator) validateJSONTag(tag string) error {
	// Extraire la valeur JSON de la balise
	jsonRegex := regexp.MustCompile(`json:"([^"]*)"`)
	matches := jsonRegex.FindStringSubmatch(tag)

	if len(matches) < 2 {
		return fmt.Errorf("invalid JSON tag format")
	}

	jsonValue := matches[1]
	parts := strings.Split(jsonValue, ",")

	if len(parts) == 0 {
		return fmt.Errorf("empty JSON tag value")
	}

	jsonName := parts[0]

	// Vérifier que le nom JSON n'est pas vide (sauf pour omitempty uniquement)
	if jsonName == "" && len(parts) == 1 {
		return fmt.Errorf("JSON tag name cannot be empty")
	}

	// Vérifier les options valides
	for i := 1; i < len(parts); i++ {
		option := strings.TrimSpace(parts[i])
		if option != "omitempty" && option != "string" && option != "-" {
			return fmt.Errorf("invalid JSON tag option: %s", option)
		}
	}

	return nil
}

// createSummary crée un résumé des erreurs par type
func (sv *StructValidator) createSummary(errors []ValidationError) map[string]int {
	summary := make(map[string]int)

	for _, err := range errors {
		summary[err.ErrorType]++
	}

	return summary
}

// generateReport génère un rapport JSON
func (sv *StructValidator) generateReport(report ValidationReport, outputPath string) error {
	data, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(outputPath, data, 0644)
}

// Validate implémente ToolkitOperation.Validate
func (sv *StructValidator) Validate(ctx context.Context) error {
	if sv.BaseDir == "" {
		return fmt.Errorf("BaseDir is required")
	}

	if sv.Logger == nil {
		return fmt.Errorf("Logger is required")
	}

	if _, err := os.Stat(sv.BaseDir); os.IsNotExist(err) {
		return fmt.Errorf("base directory does not exist: %s", sv.BaseDir)
	}

	return nil
}

// CollectMetrics implémente ToolkitOperation.CollectMetrics
func (sv *StructValidator) CollectMetrics() map[string]interface{} {
	return map[string]interface{}{
		"tool":           "StructValidator",
		"files_analyzed": sv.Stats.FilesAnalyzed,
		"errors_found":   sv.Stats.ErrorsFixed,
		"dry_run_mode":   sv.DryRun,
		"base_directory": sv.BaseDir,
	}
}

// HealthCheck implémente ToolkitOperation.HealthCheck
func (sv *StructValidator) HealthCheck(ctx context.Context) error {
	if sv.FileSet == nil {
		return fmt.Errorf("FileSet not initialized")
	}

	// Vérifier l'accès au répertoire cible
	if _, err := os.Stat(sv.BaseDir); os.IsNotExist(err) {
		return fmt.Errorf("base directory does not exist: %s", sv.BaseDir)
	}

	return nil
}
