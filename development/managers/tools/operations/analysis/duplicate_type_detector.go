// Manager Toolkit - Duplicate Type Detector
// Version: 3.0.0
// Detects duplicate type definitions across Go packages and modules

package analysis

import (
	"github.com/email-sender/tools/core/registry"
	"github.com/email-sender/tools/core/toolkit"
	"context"
	"encoding/json"
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// DuplicateTypeDetector implémente l'interface toolkit.ToolkitOperation pour la détection des types dupliqués
type DuplicateTypeDetector struct {
	BaseDir string
	FileSet *token.FileSet
	toolkit.Logger  *Logger
	Stats   *ToolkitStats
	DryRun  bool
}

// TypeDefinition représente une définition de type
type TypeDefinition struct {
	Name      string `json:"name"`
	Package   string `json:"package"`
	File      string `json:"file"`
	Line      int    `json:"line"`
	TypeKind  string `json:"type_kind"` // struct, interface, alias, etc.
	Signature string `json:"signature"` // Signature simplifiée du type
}

// DuplicateType représente un type dupliqué
type DuplicateType struct {
	TypeName    string           `json:"type_name"`
	Occurrences []TypeDefinition `json:"occurrences"`
	Severity    string           `json:"severity"` // high, medium, low
	Suggestion  string           `json:"suggestion"`
}

// DuplicationReport représente le rapport de détection des doublons
type DuplicationReport struct {
	Tool            string          `json:"tool"`
	Timestamp       time.Time       `json:"timestamp"`
	FilesAnalyzed   int             `json:"files_analyzed"`
	TypesAnalyzed   int             `json:"types_analyzed"`
	DuplicatesFound int             `json:"duplicates_found"`
	DuplicateTypes  []DuplicateType `json:"duplicate_types"`
	Summary         map[string]int  `json:"summary"`
	DurationMs      int64           `json:"duration_ms"`
}

// NewDuplicateTypeDetector crée une nouvelle instance de DuplicateTypeDetector
func NewDuplicateTypeDetector(baseDir string, toolkit.Logger *Logger, dryRun bool) (*DuplicateTypeDetector, error) {
	if baseDir == "" {
		return nil, fmt.Errorf("base directory cannot be empty")
	}

	// Vérifier que le répertoire existe
	if _, err := os.Stat(baseDir); os.IsNotExist(err) {
		return nil, fmt.Errorf("base directory does not exist: %s", baseDir)
	}

	if toolkit.Logger == nil {
		toolkit.Logger = &Logger{verbose: false} // Créer un toolkit.Logger par défaut
	}

	return &DuplicateTypeDetector{
		BaseDir: baseDir,
		FileSet: token.NewFileSet(),
		Logger:  logger,
		Stats:   &ToolkitStats{},
		DryRun:  dryRun,
	}, nil
}

// Execute implémente ToolkitOperation.Execute
func (dtd *DuplicateTypeDetector) Execute(ctx context.Context, options *OperationOptions) error {
	dtd.Logger.Info("🔍 Starting duplicate type detection on: %s", options.Target)
	startTime := time.Now()

	if dtd.FileSet == nil {
		dtd.FileSet = token.NewFileSet()
	}

	typeRegistry := make(map[string][]TypeDefinition)
	filesAnalyzed := 0
	typesAnalyzed := 0

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

		dtd.Logger.Info("Analyzing file: %s", path)
		filesAnalyzed++

		fileTypes, err := dtd.analyzeFile(path)
		if err != nil {
			dtd.Logger.Warn("Failed to analyze file %s: %v", path, err)
			return nil // Continue avec les autres fichiers
		}

		// Enregistrer les types trouvés
		for _, typeDef := range fileTypes {
			typeRegistry[typeDef.Name] = append(typeRegistry[typeDef.Name], typeDef)
			typesAnalyzed++
		}

		return nil
	})

	if err != nil {
		dtd.Logger.Error("Failed to walk directory: %v", err)
		return err
	}

	// Identifier les doublons
	duplicates := dtd.findDuplicates(typeRegistry)
	duration := time.Since(startTime)

	// Mettre à jour les statistiques standardisées
	dtd.Stats.FilesAnalyzed += filesAnalyzed
	dtd.Stats.ErrorsFixed += len(duplicates)

	// Générer le rapport si demandé
	if options.Output != "" && !dtd.DryRun {
		report := DuplicationReport{
			Tool:            "DuplicateTypeDetector",
			Timestamp:       time.Now(),
			FilesAnalyzed:   filesAnalyzed,
			TypesAnalyzed:   typesAnalyzed,
			DuplicatesFound: len(duplicates),
			DuplicateTypes:  duplicates,
			Summary:         dtd.createSummary(duplicates),
			DurationMs:      duration.Milliseconds(),
		}

		if err := dtd.generateReport(report, options.Output); err != nil {
			dtd.Logger.Error("Failed to generate report: %v", err)
			return err
		}

		dtd.Logger.Info("Duplication report saved to: %s", options.Output)
	}

	dtd.Logger.Info("✅ Duplicate type detection completed: %d files, %d types, %d duplicates found in %v",
		filesAnalyzed, typesAnalyzed, len(duplicates), duration)

	return nil
}

// analyzeFile analyse un fichier Go pour extraire les définitions de types
func (dtd *DuplicateTypeDetector) analyzeFile(filePath string) ([]TypeDefinition, error) {
	src, err := os.ReadFile(filePath)
	if err != nil {
		return nil, err
	}

	file, err := parser.ParseFile(dtd.FileSet, filePath, src, parser.ParseComments)
	if err != nil {
		return nil, err
	}

	var types []TypeDefinition
	packageName := file.Name.Name

	// Analyser toutes les déclarations de types
	for _, decl := range file.Decls {
		if typeDecl, ok := decl.(*ast.GenDecl); ok && typeDecl.Tok == token.TYPE {
			for _, spec := range typeDecl.Specs {
				if typeSpec, ok := spec.(*ast.TypeSpec); ok {
					typeDef := TypeDefinition{
						Name:      typeSpec.Name.Name,
						Package:   packageName,
						File:      filePath,
						Line:      dtd.FileSet.Position(typeSpec.Pos()).Line,
						TypeKind:  dtd.getTypeKind(typeSpec.Type),
						Signature: dtd.getTypeSignature(typeSpec.Type),
					}
					types = append(types, typeDef)
				}
			}
		}
	}

	return types, nil
}

// getTypeKind détermine le type de déclaration
func (dtd *DuplicateTypeDetector) getTypeKind(expr ast.Expr) string {
	switch expr.(type) {
	case *ast.StructType:
		return "struct"
	case *ast.InterfaceType:
		return "interface"
	case *ast.ArrayType:
		return "array"
	case *ast.MapType:
		return "map"
	case *ast.ChanType:
		return "channel"
	case *ast.FuncType:
		return "function"
	case *ast.Ident:
		return "alias"
	case *ast.SelectorExpr:
		return "external_type"
	default:
		return "unknown"
	}
}

// getTypeSignature génère une signature simplifiée du type
func (dtd *DuplicateTypeDetector) getTypeSignature(expr ast.Expr) string {
	switch t := expr.(type) {
	case *ast.StructType:
		if t.Fields == nil {
			return "struct{}"
		}
		return fmt.Sprintf("struct{%d_fields}", len(t.Fields.List))
	case *ast.InterfaceType:
		if t.Methods == nil {
			return "interface{}"
		}
		return fmt.Sprintf("interface{%d_methods}", len(t.Methods.List))
	case *ast.ArrayType:
		return fmt.Sprintf("[]%s", dtd.getTypeSignature(t.Elt))
	case *ast.MapType:
		return fmt.Sprintf("map[%s]%s", dtd.getTypeSignature(t.Key), dtd.getTypeSignature(t.Value))
	case *ast.Ident:
		return t.Name
	case *ast.SelectorExpr:
		if ident, ok := t.X.(*ast.Ident); ok {
			return fmt.Sprintf("%s.%s", ident.Name, t.Sel.Name)
		}
		return "external_type"
	default:
		return "unknown"
	}
}

// findDuplicates identifie les types dupliqués
func (dtd *DuplicateTypeDetector) findDuplicates(typeRegistry map[string][]TypeDefinition) []DuplicateType {
	var duplicates []DuplicateType

	for typeName, occurrences := range typeRegistry {
		if len(occurrences) > 1 {
			// Vérifier si ce sont de vrais doublons (même signature)
			signatureGroups := make(map[string][]TypeDefinition)

			for _, occurrence := range occurrences {
				signature := occurrence.Signature
				signatureGroups[signature] = append(signatureGroups[signature], occurrence)
			}

			// Créer un rapport pour chaque groupe de signatures dupliquées
			for signature, group := range signatureGroups {
				if len(group) > 1 {
					duplicate := DuplicateType{
						TypeName:    typeName,
						Occurrences: group,
						Severity:    dtd.calculateSeverity(group),
						Suggestion:  dtd.generateSuggestion(typeName, group, signature),
					}
					duplicates = append(duplicates, duplicate)
				}
			}
		}
	}

	return duplicates
}

// calculateSeverity calcule la sévérité du doublon
func (dtd *DuplicateTypeDetector) calculateSeverity(occurrences []TypeDefinition) string {
	// Vérifier si les types sont dans des packages différents
	packages := make(map[string]bool)
	for _, occ := range occurrences {
		packages[occ.Package] = true
	}

	if len(packages) > 1 {
		return "high" // Doublons dans différents packages
	}

	if len(occurrences) > 3 {
		return "medium" // Beaucoup de doublons
	}

	return "low" // Doublons limités dans le même package
}

// generateSuggestion génère une suggestion de résolution
func (dtd *DuplicateTypeDetector) generateSuggestion(typeName string, occurrences []TypeDefinition, signature string) string {
	packages := make(map[string]bool)
	for _, occ := range occurrences {
		packages[occ.Package] = true
	}

	if len(packages) > 1 {
		return fmt.Sprintf("Consider consolidating type '%s' into a shared package or renaming conflicting types", typeName)
	}

	return fmt.Sprintf("Remove duplicate definitions of type '%s' and keep only one instance", typeName)
}

// createSummary crée un résumé des doublons par sévérité
func (dtd *DuplicateTypeDetector) createSummary(duplicates []DuplicateType) map[string]int {
	summary := map[string]int{
		"high_severity":   0,
		"medium_severity": 0,
		"low_severity":    0,
		"struct_types":    0,
		"interface_types": 0,
		"alias_types":     0,
	}

	for _, duplicate := range duplicates {
		switch duplicate.Severity {
		case "high":
			summary["high_severity"]++
		case "medium":
			summary["medium_severity"]++
		case "low":
			summary["low_severity"]++
		}

		// Compter par type
		if len(duplicate.Occurrences) > 0 {
			switch duplicate.Occurrences[0].TypeKind {
			case "struct":
				summary["struct_types"]++
			case "interface":
				summary["interface_types"]++
			case "alias":
				summary["alias_types"]++
			}
		}
	}

	return summary
}

// generateReport génère un rapport JSON
func (dtd *DuplicateTypeDetector) generateReport(report DuplicationReport, outputPath string) error {
	data, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(outputPath, data, 0644)
}

// Validate implémente ToolkitOperation.Validate
func (dtd *DuplicateTypeDetector) Validate(ctx context.Context) error {
	if dtd.BaseDir == "" {
		return fmt.Errorf("BaseDir is required")
	}

	if dtd.Logger == nil {
		return fmt.Errorf("Logger is required")
	}

	if _, err := os.Stat(dtd.BaseDir); os.IsNotExist(err) {
		return fmt.Errorf("base directory does not exist: %s", dtd.BaseDir)
	}

	return nil
}

// CollectMetrics implémente ToolkitOperation.CollectMetrics
func (dtd *DuplicateTypeDetector) CollectMetrics() map[string]interface{} {
	return map[string]interface{}{
		"tool":             "DuplicateTypeDetector",
		"files_analyzed":   dtd.Stats.FilesAnalyzed,
		"duplicates_found": dtd.Stats.ErrorsFixed,
		"dry_run_mode":     dtd.DryRun,
		"base_directory":   dtd.BaseDir,
	}
}

// HealthCheck implémente ToolkitOperation.HealthCheck
func (dtd *DuplicateTypeDetector) HealthCheck(ctx context.Context) error {
	if dtd.FileSet == nil {
		return fmt.Errorf("FileSet not initialized")
	}

	// Vérifier l'accès au répertoire cible
	if _, err := os.Stat(dtd.BaseDir); os.IsNotExist(err) {
		return fmt.Errorf("base directory does not exist: %s", dtd.BaseDir)
	}

	return nil
}

// String implémente ToolkitOperation.String - identification de l'outil
func (dtd *DuplicateTypeDetector) String() string {
	return "DuplicateTypeDetector"
}

// GetDescription implémente ToolkitOperation.GetDescription - description de l'outil
func (dtd *DuplicateTypeDetector) GetDescription() string {
	return "Detects duplicate type definitions in Go packages"
}

// Stop implémente ToolkitOperation.Stop - gestion des signaux d'arrêt
func (dtd *DuplicateTypeDetector) Stop(ctx context.Context) error {
	return nil
}

// init registers the DuplicateTypeDetector tool automatically
func init() {
	if globalRegistry == nil {
		globalRegistry = NewToolRegistry()
	}
	
	// Create a default instance for registration
	defaultTool := &DuplicateTypeDetector{
		BaseDir: "",
		FileSet: token.NewFileSet(),
		Logger:  nil,
		Stats:   &ToolkitStats{},
		DryRun:  false,
	}
	
	err := globalRegistry.Register(OpDetectDuplicates, defaultTool)
	if err != nil {
		// Log error but don't panic during package initialization
		fmt.Printf("Warning: Failed to register DuplicateTypeDetector: %v\n", err)
	}
}


