// Manager Toolkit - Import Conflict Resolver
// Version: 3.0.0
// Detects and resolves import conflicts in Go packages

package correction

import (
	"github.com/gerivdb/email-sender-1/tools/core/registry"
	"github.com/gerivdb/email-sender-1/tools/core/toolkit"
	"context"
	"encoding/json"
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

// ImportConflictResolver implémente l'interface toolkit.ToolkitOperation pour résoudre les conflits d'imports
type ImportConflictResolver struct {
	BaseDir string
	FileSet *token.FileSet
	Logger  *toolkit.Logger
	Stats   *toolkit.ToolkitStats
	DryRun  bool
}

// ImportConflict représente un conflit d'import détecté
type ImportConflict struct {
	File            string   `json:"file"`
	ConflictType    string   `json:"conflict_type"`
	ImportPath      string   `json:"import_path"`
	Alias           string   `json:"alias,omitempty"`
	ConflictingWith []string `json:"conflicting_with"`
	Description     string   `json:"description"`
	Line            int      `json:"line"`
	Suggestion      string   `json:"suggestion"`
}

// ImportAnalysis représente l'analyse d'imports d'un fichier
type ImportAnalysis struct {
	File       string            `json:"file"`
	Imports    []ImportInfo      `json:"imports"`
	Duplicates []string          `json:"duplicates"`
	Unused     []string          `json:"unused"`
	Conflicts  []ImportConflict  `json:"conflicts"`
	PackageMap map[string]string `json:"package_map"`
}

// NewImportConflictResolver crée une nouvelle instance de ImportConflictResolver
func NewImportConflictResolver(baseDir string, logger *toolkit.Logger, dryRun bool) (*ImportConflictResolver, error) {
	if baseDir == "" {
		return nil, fmt.Errorf("base directory cannot be empty")
	}

	// Vérifier que le répertoire existe
	if _, err := os.Stat(baseDir); os.IsNotExist(err) {
		return nil, fmt.Errorf("base directory does not exist: %s", baseDir)
	}

	if logger == nil {
		// Assuming toolkit.Logger can be instantiated directly or has a constructor.
		logger = &toolkit.Logger{} // Simplistic instantiation
	}

	return &ImportConflictResolver{
		BaseDir: baseDir,
		FileSet: token.NewFileSet(),
		Logger:  logger,
		Stats:   &toolkit.ToolkitStats{},
		DryRun:  dryRun,
	}, nil
}

// ImportInfo représente les informations d'un import
type ImportInfo struct {
	Path  string `json:"path"`
	Alias string `json:"alias,omitempty"`
	Line  int    `json:"line"`
	Used  bool   `json:"used"`
}

// ImportReport représente le rapport de résolution des conflits d'imports
type ImportReport struct {
	Tool            string           `json:"tool"`
	Timestamp       time.Time        `json:"timestamp"`
	FilesAnalyzed   int              `json:"files_analyzed"`
	ConflictsFound  int              `json:"conflicts_found"`
	ConflictsFixed  int              `json:"conflicts_fixed"`
	ImportConflicts []ImportConflict `json:"import_conflicts"`
	FileAnalyses    []ImportAnalysis `json:"file_analyses"`
	Summary         map[string]int   `json:"summary"`
	DurationMs      int64            `json:"duration_ms"`
}

// Execute implémente ToolkitOperation.Execute
func (icr *ImportConflictResolver) Execute(ctx context.Context, options *toolkit.OperationOptions) error {
	icr.Logger.Info("🔍 Starting import conflict resolution on: %s", options.Target)
	startTime := time.Now()

	if icr.FileSet == nil {
		icr.FileSet = token.NewFileSet()
	}

	var conflicts []ImportConflict
	var analyses []ImportAnalysis
	filesAnalyzed := 0
	conflictsFixed := 0

	err := filepath.Walk(options.Target, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Analyser uniquement les fichiers Go (exclure les tests)
		if !strings.HasSuffix(path, ".go") || strings.Contains(path, "_test.go") {
			return nil
		}

		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
		}

		icr.Logger.Info("Analyzing imports in file: %s", path)
		filesAnalyzed++

		analysis, err := icr.analyzeFileImports(path)
		if err != nil {
			icr.Logger.Warn("Failed to analyze imports in file %s: %v", path, err)
			return nil // Continue avec les autres fichiers
		}

		analyses = append(analyses, *analysis)
		conflicts = append(conflicts, analysis.Conflicts...)

		// Résoudre les conflits si pas en mode dry-run
		if !icr.DryRun && len(analysis.Conflicts) > 0 {
			fixed, err := icr.resolveConflicts(path, analysis)
			if err != nil {
				icr.Logger.Warn("Failed to resolve conflicts in %s: %v", path, err)
			} else {
				conflictsFixed += fixed
			}
		}

		return nil
	})

	if err != nil {
		icr.Logger.Error("Failed to walk directory: %v", err)
		return err
	}

	duration := time.Since(startTime)

	// Mettre à jour les statistiques standardisées
	icr.Stats.FilesAnalyzed += filesAnalyzed
	icr.Stats.ErrorsFixed += conflictsFixed

	// Générer le rapport si demandé
	if options.Output != "" {
		report := ImportReport{
			Tool:            "ImportConflictResolver",
			Timestamp:       time.Now(),
			FilesAnalyzed:   filesAnalyzed,
			ConflictsFound:  len(conflicts),
			ConflictsFixed:  conflictsFixed,
			ImportConflicts: conflicts,
			FileAnalyses:    analyses,
			Summary:         icr.createSummary(conflicts),
			DurationMs:      duration.Milliseconds(),
		}

		if err := icr.generateReport(report, options.Output); err != nil {
			icr.Logger.Error("Failed to generate report: %v", err)
			return err
		}

		icr.Logger.Info("Import conflict report saved to: %s", options.Output)
	}

	icr.Logger.Info("✅ Import conflict resolution completed: %d files, %d conflicts found, %d conflicts fixed in %v",
		filesAnalyzed, len(conflicts), conflictsFixed, duration)

	return nil
}

// analyzeFileImports analyse les imports d'un fichier spécifique
func (icr *ImportConflictResolver) analyzeFileImports(filePath string) (*ImportAnalysis, error) {
	src, err := os.ReadFile(filePath)
	if err != nil {
		return nil, err
	}

	file, err := parser.ParseFile(icr.FileSet, filePath, src, parser.ParseComments)
	if err != nil {
		return nil, fmt.Errorf("failed to parse file: %v", err)
	}

	analysis := &ImportAnalysis{
		File:       filePath,
		Imports:    []ImportInfo{},
		Duplicates: []string{},
		Unused:     []string{},
		Conflicts:  []ImportConflict{},
		PackageMap: make(map[string]string),
	}

	// Collecter tous les imports
	importPaths := make(map[string][]ImportInfo)
	packageNames := make(map[string][]string)

	for _, imp := range file.Imports {
		importPath := strings.Trim(imp.Path.Value, `"`)
		alias := ""

		if imp.Name != nil {
			alias = imp.Name.Name
		}

		info := ImportInfo{
			Path:  importPath,
			Alias: alias,
			Line:  icr.FileSet.Position(imp.Pos()).Line,
			Used:  icr.isImportUsed(file, importPath, alias),
		}

		analysis.Imports = append(analysis.Imports, info)
		importPaths[importPath] = append(importPaths[importPath], info)

		// Déterminer le nom du package
		packageName := icr.getPackageName(importPath, alias)
		packageNames[packageName] = append(packageNames[packageName], importPath)
		analysis.PackageMap[importPath] = packageName
	}

	// Détecter les conflits
	analysis.Conflicts = icr.detectConflicts(filePath, importPaths, packageNames)

	// Détecter les doublons
	for path, infos := range importPaths {
		if len(infos) > 1 {
			analysis.Duplicates = append(analysis.Duplicates, path)
		}
	}

	// Détecter les imports non utilisés
	for _, info := range analysis.Imports {
		if !info.Used {
			analysis.Unused = append(analysis.Unused, info.Path)
		}
	}

	return analysis, nil
}

// detectConflicts détecte les différents types de conflits d'imports
func (icr *ImportConflictResolver) detectConflicts(filePath string, importPaths map[string][]ImportInfo, packageNames map[string][]string) []ImportConflict {
	var conflicts []ImportConflict

	// Conflit 1: Imports dupliqués
	for path, infos := range importPaths {
		if len(infos) > 1 {
			for i, info := range infos {
				if i > 0 { // Garder le premier, marquer les autres comme conflits
					conflicts = append(conflicts, ImportConflict{
						File:            filePath,
						ConflictType:    "duplicate_import",
						ImportPath:      path,
						Alias:           info.Alias,
						ConflictingWith: []string{path},
						Description:     fmt.Sprintf("Duplicate import of package '%s'", path),
						Line:            info.Line,
						Suggestion:      "Remove duplicate import",
					})
				}
			}
		}
	}

	// Conflit 2: Noms de packages en conflit
	for packageName, paths := range packageNames {
		if len(paths) > 1 && packageName != "" {
			for _, path := range paths {
				if infos, exists := importPaths[path]; exists {
					for _, info := range infos {
						if info.Alias == "" { // Seulement si pas d'alias
							otherPaths := []string{}
							for _, otherPath := range paths {
								if otherPath != path {
									otherPaths = append(otherPaths, otherPath)
								}
							}

							conflicts = append(conflicts, ImportConflict{
								File:            filePath,
								ConflictType:    "package_name_conflict",
								ImportPath:      path,
								Alias:           info.Alias,
								ConflictingWith: otherPaths,
								Description:     fmt.Sprintf("Package name '%s' conflicts with other imports", packageName),
								Line:            info.Line,
								Suggestion:      fmt.Sprintf("Add alias: import %s \"%s\"", icr.suggestAlias(path), path),
							})
						}
					}
				}
			}
		}
	}

	return conflicts
}

// isImportUsed vérifie si un import est utilisé dans le fichier
func (icr *ImportConflictResolver) isImportUsed(file *ast.File, importPath, alias string) bool {
	packageName := icr.getPackageName(importPath, alias)

	used := false
	ast.Inspect(file, func(n ast.Node) bool {
		switch node := n.(type) {
		case *ast.SelectorExpr:
			if ident, ok := node.X.(*ast.Ident); ok {
				if ident.Name == packageName {
					used = true
					return false
				}
			}
		case *ast.Ident:
			if node.Name == packageName {
				used = true
				return false
			}
		}
		return true
	})

	return used
}

// getPackageName retourne le nom du package utilisé dans le code
func (icr *ImportConflictResolver) getPackageName(importPath, alias string) string {
	if alias != "" && alias != "_" && alias != "." {
		return alias
	}

	// Extraire le nom du package du chemin
	parts := strings.Split(importPath, "/")
	if len(parts) > 0 {
		return parts[len(parts)-1]
	}

	return importPath
}

// suggestAlias suggère un alias pour résoudre un conflit
func (icr *ImportConflictResolver) suggestAlias(importPath string) string {
	parts := strings.Split(importPath, "/")
	if len(parts) >= 2 {
		// Utiliser les deux dernières parties
		return strings.ToLower(parts[len(parts)-2]) + strings.Title(parts[len(parts)-1])
	} else if len(parts) == 1 {
		return parts[0] + "Pkg"
	}
	return "pkg"
}

// resolveConflicts résout automatiquement les conflits dans un fichier
func (icr *ImportConflictResolver) resolveConflicts(filePath string, analysis *ImportAnalysis) (int, error) {
	if len(analysis.Conflicts) == 0 {
		return 0, nil
	}

	icr.Logger.Info("Resolving %d conflicts in file: %s", len(analysis.Conflicts), filePath)

	// Lire le contenu du fichier
	content, err := os.ReadFile(filePath)
	if err != nil {
		return 0, err
	}

	lines := strings.Split(string(content), "\n")
	fixed := 0

	// Trier les conflits par ligne (descendant pour éviter les décalages)
	sort.Slice(analysis.Conflicts, func(i, j int) bool {
		return analysis.Conflicts[i].Line > analysis.Conflicts[j].Line
	})

	for _, conflict := range analysis.Conflicts {
		switch conflict.ConflictType {
		case "duplicate_import":
			// Supprimer l'import dupliqué
			if conflict.Line-1 < len(lines) {
				lines = append(lines[:conflict.Line-1], lines[conflict.Line:]...)
				fixed++
				icr.Logger.Info("Removed duplicate import: %s", conflict.ImportPath)
			}
		case "package_name_conflict":
			// Ajouter un alias
			if conflict.Line-1 < len(lines) {
				line := lines[conflict.Line-1]
				alias := icr.suggestAlias(conflict.ImportPath)
				newLine := strings.Replace(line,
					fmt.Sprintf(`"%s"`, conflict.ImportPath),
					fmt.Sprintf(`%s "%s"`, alias, conflict.ImportPath), 1)
				lines[conflict.Line-1] = newLine
				fixed++
				icr.Logger.Info("Added alias '%s' for import: %s", alias, conflict.ImportPath)
			}
		}
	}

	// Réécrire le fichier si des modifications ont été apportées
	if fixed > 0 {
		newContent := strings.Join(lines, "\n")
		if err := os.WriteFile(filePath, []byte(newContent), 0644); err != nil {
			return 0, err
		}
	}

	return fixed, nil
}

// createSummary crée un résumé des conflits par type
func (icr *ImportConflictResolver) createSummary(conflicts []ImportConflict) map[string]int {
	summary := make(map[string]int)

	for _, conflict := range conflicts {
		summary[conflict.ConflictType]++
	}

	return summary
}

// generateReport génère un rapport JSON
func (icr *ImportConflictResolver) generateReport(report ImportReport, outputPath string) error {
	data, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(outputPath, data, 0644)
}

// Validate implémente ToolkitOperation.Validate
func (icr *ImportConflictResolver) Validate(ctx context.Context) error {
	if icr.BaseDir == "" {
		return fmt.Errorf("BaseDir is required")
	}

	if icr.Logger == nil {
		return fmt.Errorf("Logger is required")
	}

	if _, err := os.Stat(icr.BaseDir); os.IsNotExist(err) {
		return fmt.Errorf("base directory does not exist: %s", icr.BaseDir)
	}

	return nil
}

// CollectMetrics implémente ToolkitOperation.CollectMetrics
func (icr *ImportConflictResolver) CollectMetrics() map[string]interface{} {
	return map[string]interface{}{
		"tool":             "ImportConflictResolver",
		"files_analyzed":   icr.Stats.FilesAnalyzed,    // Number of files checked
		"conflicts_fixed":  icr.Stats.ErrorsFixed,      // Number of conflicts actually fixed
		"dry_run":          icr.DryRun,                 // Changed key from dry_run_mode
		"base_dir":         icr.BaseDir,                // Changed key from base_directory
		// "conflicts_found": placeholder_value, // Test expects this, but it's not explicitly tracked in stats. Could be len(conflicts) from Execute.
		// "duplicates_removed": not applicable to this tool
	}
}

// HealthCheck implémente ToolkitOperation.HealthCheck
func (icr *ImportConflictResolver) HealthCheck(ctx context.Context) error {
	if icr.FileSet == nil {
		return fmt.Errorf("FileSet not initialized")
	}

	// Vérifier l'accès au répertoire cible
	if _, err := os.Stat(icr.BaseDir); os.IsNotExist(err) {
		return fmt.Errorf("base directory does not exist: %s", icr.BaseDir)
	}

	return nil
}

// String implémente ToolkitOperation.String - identification de l'outil
func (icr *ImportConflictResolver) String() string {
	return "ImportConflictResolver"
}

// GetDescription implémente ToolkitOperation.GetDescription - description de l'outil
func (icr *ImportConflictResolver) GetDescription() string {
	return "Detects and resolves import conflicts in Go packages"
}

// Stop implémente ToolkitOperation.Stop - gestion des signaux d'arrêt
func (icr *ImportConflictResolver) Stop(ctx context.Context) error {
	return nil
}

// init registers the ImportConflictResolver tool automatically
func init() {
	globalReg := registry.GetGlobalRegistry()
	if globalReg == nil {
		globalReg = registry.NewToolRegistry()
		// registry.SetGlobalRegistry(globalReg) // If a setter exists
	}
	
	// Create a default instance for registration
	defaultTool := &ImportConflictResolver{
		BaseDir: "", // Default or placeholder
		FileSet: token.NewFileSet(), // Initialize FileSet
		Logger:  nil, // Logger should be initialized by the toolkit
		Stats:   &toolkit.ToolkitStats{},
		DryRun:  false,
	}
	
	err := globalReg.Register(toolkit.ResolveImports, defaultTool) // Changed to toolkit.ResolveImports
	if err != nil {
		// Log error but don't panic during package initialization
		fmt.Printf("Warning: Failed to register ImportConflictResolver: %v\n", err)
	}
}


