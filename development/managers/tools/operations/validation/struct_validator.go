// Manager Toolkit - Struct Validator
// Version: 3.0.0
// Validates Go struct declarations for syntax errors, field types, and JSON tags

package validation

import (
	/*
	   "github.com/gerivdb/email-sender-1/tools/core/registry"
	   "github.com/gerivdb/email-sender-1/tools/core/toolkit"
	*/
	"context"
	"docmanager/development/managers/tools/core/toolkit"
	"encoding/json"
	"fmt"
	"go/ast"
	"go/importer"
	"go/parser"
	"go/token"
	"go/types"
	"os"
	"regexp"
	"strings"
	"time"
)

// StructValidator implémente l'interface toolkit.ToolkitOperation pour la validation des structures
type StructValidator struct {
	BaseDir     string
	FileSet     *token.FileSet
	Logger      *toolkit.Logger
	Stats       *toolkit.ToolkitStats
	DryRun      bool
	TypeChecker *types.Checker
	Package     *types.Package
}

// ValidationError représente une erreur de validation
type ValidationError struct {
	File         string `json:"file"`
	StructName   string `json:"struct_name"`
	FieldName    string `json:"field_name,omitempty"`
	ErrorType    string `json:"error_type"`
	Description  string `json:"description"`
	Line         int    `json:"line"`
	Column       int    `json:"column,omitempty"`
	Severity     string `json:"severity"`
	SuggestedFix string `json:"suggested_fix,omitempty"`
	RuleViolated string `json:"rule_violated,omitempty"`
}

// ValidationReport représente le rapport de validation
type ValidationReport struct {
	Tool             string                  `json:"tool"`
	Version          string                  `json:"version"`
	Timestamp        time.Time               `json:"timestamp"`
	FilesAnalyzed    int                     `json:"files_analyzed"`
	StructsAnalyzed  int                     `json:"structs_analyzed"`
	FieldsAnalyzed   int                     `json:"fields_analyzed"`
	ErrorsFound      int                     `json:"errors_found"`
	WarningsFound    int                     `json:"warnings_found"`
	ValidationErrors []ValidationError       `json:"validation_errors"`
	Summary          map[string]int          `json:"summary"`
	SeverityCounts   map[string]int          `json:"severity_counts"`
	DurationMs       int64                   `json:"duration_ms"`
	Configuration    map[string]interface{}  `json:"configuration"`
	SemanticAnalysis *SemanticAnalysisResult `json:"semantic_analysis,omitempty"`
}

// SemanticAnalysisResult contient les résultats de l'analyse sémantique
type SemanticAnalysisResult struct {
	TypesChecked     int      `json:"types_checked"`
	UndefinedTypes   []string `json:"undefined_types"`
	UnusedTypes      []string `json:"unused_types"`
	CircularDeps     []string `json:"circular_dependencies"`
	RecommendedFixes []string `json:"recommended_fixes"`
}

// NewStructValidator crée une nouvelle instance de StructValidator
func NewStructValidator(baseDir string, logger *toolkit.Logger, dryRun bool) (*StructValidator, error) {
	if baseDir == "" {
		return nil, fmt.Errorf("base directory cannot be empty")
	}

	// Vérifier que le répertoire existe
	if _, err := os.Stat(baseDir); os.IsNotExist(err) {
		return nil, fmt.Errorf("base directory does not exist: %s", baseDir)
	}
	if logger == nil {
		logger = &toolkit.Logger{} // Créer un toolkit.Logger par défaut
	}

	return &StructValidator{
		BaseDir: baseDir,
		FileSet: token.NewFileSet(),
		Logger:  logger,
		Stats:   &toolkit.ToolkitStats{},
		DryRun:  dryRun,
	}, nil
}

// Execute implémente ToolkitOperation.Execute
func (sv *StructValidator) Execute(ctx context.Context, options *toolkit.OperationOptions) error {
	sv.Logger.Info("🔍 Starting comprehensive struct validation on: %s", options.Target)
	startTime := time.Now()

	if sv.FileSet == nil {
		sv.FileSet = token.NewFileSet()
	}

	// Phase 1: Parse directory and collect all packages
	fset := token.NewFileSet()
	pkgs, err := parser.ParseDir(fset, options.Target, nil, parser.ParseComments)
	if err != nil {
		sv.Logger.Error("Failed to parse directory: %v", err)
		return err
	}

	var errors []ValidationError
	var warnings []ValidationError
	structsAnalyzed := 0
	fieldsAnalyzed := 0
	filesAnalyzed := 0

	// Phase 2: Enhanced validation with semantic analysis
	for pkgName, pkg := range pkgs {
		sv.Logger.Info("Analyzing package: %s", pkgName)

		// Setup type checker for semantic analysis
		config := types.Config{
			Importer: importer.Default(),
			Error: func(err error) {
				sv.Logger.Warn("Type checker error: %v", err)
			},
		}
		info := &types.Info{
			Types: make(map[ast.Expr]types.TypeAndValue),
			Defs:  make(map[*ast.Ident]types.Object),
			Uses:  make(map[*ast.Ident]types.Object),
		}

		var files []*ast.File
		for _, file := range pkg.Files {
			files = append(files, file)
			filesAnalyzed++
		}

		// Run type checker
		sv.Package, err = config.Check(pkgName, fset, files, info)
		if err != nil {
			sv.Logger.Warn("Type checking failed for package %s: %v", pkgName, err)
		}

		// Analyze each file
		for fileName, file := range pkg.Files {
			select {
			case <-ctx.Done():
				return ctx.Err()
			default:
			}

			sv.Logger.Debug("Analyzing file: %s", fileName)

			fileErrors, fileWarnings, fileStructs, fileFields := sv.validateFileEnhanced(fileName, file, info)
			errors = append(errors, fileErrors...)
			warnings = append(warnings, fileWarnings...)
			structsAnalyzed += fileStructs
			fieldsAnalyzed += fileFields
		}
	}

	duration := time.Since(startTime)

	// Update standardized statistics
	sv.Stats.FilesAnalyzed += filesAnalyzed
	sv.Stats.ErrorsFixed += len(errors)

	// Generate comprehensive report if requested
	if options.Output != "" && !sv.DryRun {
		semanticAnalysis := sv.performSemanticAnalysis(pkgs)

		report := ValidationReport{
			Tool:             "StructValidator",
			Version:          "3.1.0",
			Timestamp:        time.Now(),
			FilesAnalyzed:    filesAnalyzed,
			StructsAnalyzed:  structsAnalyzed,
			FieldsAnalyzed:   fieldsAnalyzed,
			ErrorsFound:      len(errors),
			WarningsFound:    len(warnings),
			ValidationErrors: append(errors, warnings...),
			Summary:          sv.createEnhancedSummary(errors, warnings),
			SeverityCounts:   sv.calculateSeverityCounts(errors, warnings),
			DurationMs:       duration.Milliseconds(),
			Configuration:    sv.getConfiguration(),
			SemanticAnalysis: semanticAnalysis,
		}

		if err := sv.generateReport(report, options.Output); err != nil {
			sv.Logger.Error("Failed to generate report: %v", err)
			return err
		}

		sv.Logger.Info("Comprehensive validation report saved to: %s", options.Output)
	}

	sv.Logger.Info("✅ Enhanced struct validation completed: %d files, %d structs, %d fields, %d errors, %d warnings in %v",
		filesAnalyzed, structsAnalyzed, fieldsAnalyzed, len(errors), len(warnings), duration)

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
		"tool":              "StructValidator",
		"version":           "3.1.0",
		"files_analyzed":    sv.Stats.FilesAnalyzed,
		"structs_analyzed":  sv.Stats.FilesModified, // Réutilisation de cette métrique
		"errors_found":      sv.Stats.ErrorsFixed,
		"dry_run":           sv.DryRun,                // Changed key
		"base_dir":          sv.BaseDir,               // Changed key
		"semantic_analysis": true,
		"type_checking":     sv.Package != nil,
		"validation_rules":  []string{"naming", "json_tags", "type_safety", "best_practices"},
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

// validateFileEnhanced effectue une validation complète d'un fichier avec analyse sémantique
func (sv *StructValidator) validateFileEnhanced(filePath string, file *ast.File, info *types.Info) ([]ValidationError, []ValidationError, int, int) {
	var errors []ValidationError
	var warnings []ValidationError
	structsCount := 0
	fieldsCount := 0

	for _, decl := range file.Decls {
		if typeDecl, ok := decl.(*ast.GenDecl); ok && typeDecl.Tok == token.TYPE {
			for _, spec := range typeDecl.Specs {
				if typeSpec, ok := spec.(*ast.TypeSpec); ok {
					if structType, ok := typeSpec.Type.(*ast.StructType); ok {
						structsCount++
						structErrors, structWarnings, structFields := sv.validateStructEnhanced(filePath, typeSpec.Name.Name, structType, info)
						errors = append(errors, structErrors...)
						warnings = append(warnings, structWarnings...)
						fieldsCount += structFields
					}
				}
			}
		}
	}

	return errors, warnings, structsCount, fieldsCount
}

// validateStructEnhanced valide une structure avec analyse sémantique avancée
func (sv *StructValidator) validateStructEnhanced(filePath, structName string, structType *ast.StructType, info *types.Info) ([]ValidationError, []ValidationError, int) {
	var errors []ValidationError
	var warnings []ValidationError
	fieldsCount := 0

	if structType.Fields == nil {
		return errors, warnings, fieldsCount
	}

	// Vérifier la convention de nommage de la structure
	if err := sv.validateStructName(structName); err != nil {
		errors = append(errors, ValidationError{
			File:         filePath,
			StructName:   structName,
			ErrorType:    "struct_name_error",
			Description:  err.Error(),
			Line:         sv.FileSet.Position(structType.Pos()).Line,
			Column:       sv.FileSet.Position(structType.Pos()).Column,
			Severity:     "error",
			SuggestedFix: sv.suggestStructNameFix(structName),
			RuleViolated: "go_naming_conventions",
		})
	}

	// Analyser chaque champ
	for _, field := range structType.Fields.List {
		fieldsCount++

		// Valider les noms de champs
		if len(field.Names) > 0 {
			for _, name := range field.Names {
				if err := sv.validateFieldName(name.Name); err != nil {
					severity := "error"
					if strings.Contains(err.Error(), "should") {
						severity = "warning"
					}

					errors = append(errors, ValidationError{
						File:         filePath,
						StructName:   structName,
						FieldName:    name.Name,
						ErrorType:    "field_name_error",
						Description:  err.Error(),
						Line:         sv.FileSet.Position(name.Pos()).Line,
						Column:       sv.FileSet.Position(name.Pos()).Column,
						Severity:     severity,
						SuggestedFix: sv.suggestFieldNameFix(name.Name),
						RuleViolated: "go_naming_conventions",
					})
				}

				// Analyse sémantique du type de champ
				if info != nil {
					if err := sv.validateFieldType(name, field.Type, info); err != nil {
						errors = append(errors, ValidationError{
							File:         filePath,
							StructName:   structName,
							FieldName:    name.Name,
							ErrorType:    "type_error",
							Description:  err.Error(),
							Line:         sv.FileSet.Position(field.Type.Pos()).Line,
							Column:       sv.FileSet.Position(field.Type.Pos()).Column,
							Severity:     "error",
							SuggestedFix: sv.suggestTypeFix(field.Type),
							RuleViolated: "type_safety",
						})
					}
				}
			}
		}

		// Valider les balises
		if field.Tag != nil {
			tagValue := strings.Trim(field.Tag.Value, "`")

			// Validation des balises JSON
			if strings.Contains(tagValue, "json:") {
				if err := sv.validateJSONTag(tagValue); err != nil {
					fieldName := "anonymous"
					if len(field.Names) > 0 {
						fieldName = field.Names[0].Name
					}

					severity := "error"
					if strings.Contains(err.Error(), "recommend") {
						severity = "warning"
					}

					errors = append(errors, ValidationError{
						File:         filePath,
						StructName:   structName,
						FieldName:    fieldName,
						ErrorType:    "json_tag_error",
						Description:  err.Error(),
						Line:         sv.FileSet.Position(field.Tag.Pos()).Line,
						Column:       sv.FileSet.Position(field.Tag.Pos()).Column,
						Severity:     severity,
						SuggestedFix: sv.suggestJSONTagFix(tagValue),
						RuleViolated: "json_serialization",
					})
				}
			}

			// Validation des autres balises courantes
			if tagSpecificWarnings := sv.validateOtherTags(tagValue); len(tagSpecificWarnings) > 0 { // Renamed to avoid shadowing
				for _, warningMsg := range tagSpecificWarnings { // Iterate over string warnings
					fieldName := "anonymous"
					if len(field.Names) > 0 {
						fieldName = field.Names[0].Name
					}

					// Append to the outer 'warnings' slice which is of type []ValidationError
					warnings = append(warnings, ValidationError{
						File:         filePath,
						StructName:   structName,
						FieldName:    fieldName,
						ErrorType:    "tag_warning",
						Description:  warningMsg, // Use the string message here
						Line:         sv.FileSet.Position(field.Tag.Pos()).Line,
						Column:       sv.FileSet.Position(field.Tag.Pos()).Column,
						Severity:     "warning",
						RuleViolated: "tag_best_practices",
					})
				}
			}
		}
	}

	return errors, warnings, fieldsCount
}

// performSemanticAnalysis effectue une analyse sémantique complète
func (sv *StructValidator) performSemanticAnalysis(pkgs map[string]*ast.Package) *SemanticAnalysisResult {
	result := &SemanticAnalysisResult{
		UndefinedTypes:   []string{},
		UnusedTypes:      []string{},
		CircularDeps:     []string{},
		RecommendedFixes: []string{},
	}

	// Collecter tous les types définis
	definedTypes := make(map[string]bool)
	usedTypes := make(map[string]bool)

	for _, pkg := range pkgs {
		for _, file := range pkg.Files {
			// Analyser les types définis
			for _, decl := range file.Decls {
				if typeDecl, ok := decl.(*ast.GenDecl); ok && typeDecl.Tok == token.TYPE {
					for _, spec := range typeDecl.Specs {
						if typeSpec, ok := spec.(*ast.TypeSpec); ok {
							typeName := typeSpec.Name.Name
							definedTypes[typeName] = true
							result.TypesChecked++
						}
					}
				}
			}
		}
	}

	// Détecter les types non définis et générer des recommandations
	for typeName := range usedTypes {
		if !definedTypes[typeName] {
			result.UndefinedTypes = append(result.UndefinedTypes, typeName)
			result.RecommendedFixes = append(result.RecommendedFixes,
				fmt.Sprintf("Define type '%s' or import the package containing it", typeName))
		}
	}

	// Détecter les types non utilisés
	for typeName := range definedTypes {
		if !usedTypes[typeName] {
			result.UnusedTypes = append(result.UnusedTypes, typeName)
			result.RecommendedFixes = append(result.RecommendedFixes,
				fmt.Sprintf("Consider removing unused type '%s' or make it private", typeName))
		}
	}

	return result
}

// createEnhancedSummary crée un résumé détaillé des erreurs
func (sv *StructValidator) createEnhancedSummary(errors, warnings []ValidationError) map[string]int {
	summary := make(map[string]int)

	for _, err := range errors {
		summary[err.ErrorType]++
	}

	for _, warning := range warnings {
		summary[warning.ErrorType+"_warnings"]++
	}

	summary["total_errors"] = len(errors)
	summary["total_warnings"] = len(warnings)
	summary["total_issues"] = len(errors) + len(warnings)

	return summary
}

// calculateSeverityCounts calcule le nombre d'erreurs par sévérité
func (sv *StructValidator) calculateSeverityCounts(errors, warnings []ValidationError) map[string]int {
	counts := make(map[string]int)

	for _, err := range errors {
		counts[err.Severity]++
	}

	for _, warning := range warnings {
		counts[warning.Severity]++
	}

	return counts
}

// getConfiguration retourne la configuration actuelle
func (sv *StructValidator) getConfiguration() map[string]interface{} {
	return map[string]interface{}{
		"dry_run":           sv.DryRun,
		"base_directory":    sv.BaseDir,
		"semantic_analysis": true,
		"validation_rules": []string{
			"go_naming_conventions",
			"json_serialization",
			"type_safety",
			"tag_best_practices",
		},
	}
}

// validateStructName valide le nom d'une structure
func (sv *StructValidator) validateStructName(structName string) error {
	if len(structName) == 0 {
		return fmt.Errorf("empty struct name")
	}

	if matched, _ := regexp.MatchString(`^[A-Z][a-zA-Z0-9]*$`, structName); !matched {
		return fmt.Errorf("struct name '%s' should follow Go naming conventions (start with uppercase letter)", structName)
	}

	return nil
}

// validateFieldType valide le type d'un champ avec analyse sémantique
func (sv *StructValidator) validateFieldType(name *ast.Ident, fieldType ast.Expr, info *types.Info) error {
	if info == nil {
		return nil
	}

	// Vérifier si le type est défini
	if typeAndValue, ok := info.Types[fieldType]; ok {
		if typeAndValue.Type == nil {
			return fmt.Errorf("undefined type for field '%s'", name.Name)
		}
	}

	return nil
}

// validateOtherTags valide les autres balises courantes
func (sv *StructValidator) validateOtherTags(tag string) []string {
	var warnings []string

	// Vérifier les balises DB
	if strings.Contains(tag, "db:") {
		dbRegex := regexp.MustCompile(`db:"([^"]*)"`)
		if matches := dbRegex.FindStringSubmatch(tag); len(matches) > 1 {
			dbValue := matches[1]
			if dbValue == "" {
				warnings = append(warnings, "Empty db tag value")
			}
		}
	}

	// Vérifier les balises de validation
	if strings.Contains(tag, "validate:") {
		validateRegex := regexp.MustCompile(`validate:"([^"]*)"`)
		if matches := validateRegex.FindStringSubmatch(tag); len(matches) > 1 {
			validateValue := matches[1]
			if validateValue == "" {
				warnings = append(warnings, "Empty validate tag value")
			}
		}
	}

	return warnings
}

// suggestStructNameFix propose une correction pour le nom de structure
func (sv *StructValidator) suggestStructNameFix(structName string) string {
	if len(structName) == 0 {
		return "Provide a meaningful struct name starting with uppercase letter"
	}

	// Capitaliser la première lettre
	if len(structName) > 0 && structName[0] >= 'a' && structName[0] <= 'z' {
		return strings.ToUpper(string(structName[0])) + structName[1:]
	}

	return "Ensure struct name follows Go naming conventions"
}

// suggestFieldNameFix propose une correction pour le nom de champ
func (sv *StructValidator) suggestFieldNameFix(fieldName string) string {
	if len(fieldName) == 0 {
		return "Provide a meaningful field name starting with uppercase letter"
	}

	// Capitaliser la première lettre
	if len(fieldName) > 0 && fieldName[0] >= 'a' && fieldName[0] <= 'z' {
		return strings.ToUpper(string(fieldName[0])) + fieldName[1:]
	}

	return "Ensure field name follows Go naming conventions"
}

// suggestJSONTagFix propose une correction pour les balises JSON
func (sv *StructValidator) suggestJSONTagFix(tag string) string {
	if !strings.Contains(tag, "json:") {
		return `Add json tag: json:"field_name"`
	}

	// Analyser la balise actuelle et proposer des améliorations
	jsonRegex := regexp.MustCompile(`json:"([^"]*)"`)
	if matches := jsonRegex.FindStringSubmatch(tag); len(matches) > 1 {
		jsonValue := matches[1]
		if jsonValue == "" {
			return `Use meaningful json tag: json:"field_name"`
		}

		parts := strings.Split(jsonValue, ",")
		if len(parts) > 1 {
			// Vérifier les options valides
			for i := 1; i < len(parts); i++ {
				option := strings.TrimSpace(parts[i])
				if option != "omitempty" && option != "string" && option != "-" {
					return fmt.Sprintf(`Invalid option '%s', use: omitempty, string, or -`, option)
				}
			}
		}
	}

	return "Ensure json tag follows correct format"
}

// suggestTypeFix propose une correction pour les types
func (sv *StructValidator) suggestTypeFix(fieldType ast.Expr) string {
	return "Ensure the type is properly defined and imported"
}

// toolkit.ToolkitOperation interface implementation (Phase 2.1 - New methods)

// String returns the tool identifier
func (sv *StructValidator) String() string {
	return "StructValidator"
}

// GetDescription returns the tool description
func (sv *StructValidator) GetDescription() string {
	return "Validates Go struct declarations for syntax errors, field types, and JSON tags"
}

// Stop handles graceful shutdown
func (sv *StructValidator) Stop(ctx context.Context) error {
	// Struct validator doesn't have background processes to stop
	if sv.Logger != nil {
		sv.Logger.Info("StructValidator stopping gracefully")
	}
	return nil
}

// init registers the StructValidator tool automatically
func init() {
fmt.Println("Avertissement : imports privés 'github.com/gerivdb/email-sender-1/tools/core/registry' et 'core/toolkit' non disponibles. L’enregistrement StructValidator est désactivé.")
}
