package main

import (
	"context"
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"

	"./interfaces"
	"go.uber.org/zap"
)

// ImportManager provides import management functionality for the dependency manager
type ImportManager struct {
	logger      *zap.Logger
	fileSet     *token.FileSet
	projectRoot string
}

// NewImportManager creates a new ImportManager instance
func NewImportManager(logger *zap.Logger, projectRoot string) *ImportManager {
	return &ImportManager{
		logger:      logger,
		fileSet:     token.NewFileSet(),
		projectRoot: projectRoot,
	}
}

// ValidateImportPaths validates all import paths in the given project
func (m *GoModManager) ValidateImportPaths(ctx context.Context, projectPath string) (*interfaces.ImportValidationResult, error) {
	m.Log("INFO", fmt.Sprintf("Starting import validation for project: %s", projectPath))
	
	im := NewImportManager(m.logger, projectPath)
	
	result := &interfaces.ImportValidationResult{
		ProjectPath: projectPath,
		Issues:      []interfaces.ImportIssue{},
		Conflicts:   []interfaces.ImportConflict{},
		Summary:     interfaces.ValidationSummary{},
		Timestamp:   time.Now().Format(time.RFC3339),
	}

	// Walk through all Go files in the project
	err := filepath.Walk(projectPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Skip non-Go files and vendor directories
		if !strings.HasSuffix(path, ".go") || strings.Contains(path, "vendor/") || strings.Contains(path, ".git/") {
			return nil
		}

		result.TotalFiles++

		// Parse the Go file
		fileIssues, fileConflicts, err := im.validateFileImports(path)
		if err != nil {
			m.logger.Warn("Failed to validate imports in file",
				zap.String("file", path),
				zap.Error(err))
			return nil // Continue with other files
		}

		if len(fileIssues) > 0 || len(fileConflicts) > 0 {
			result.FilesWithIssues++
		}

		result.Issues = append(result.Issues, fileIssues...)
		result.Conflicts = append(result.Conflicts, fileConflicts...)

		return nil
	})

	if err != nil {
		return nil, m.errorManager.ProcessError(ctx, err, "import-validation", "walk_project", nil)
	}

	// Update summary
	result.Summary = im.calculateSummary(result.Issues)

	m.Log("INFO", fmt.Sprintf("Import validation completed. Found %d issues in %d files", len(result.Issues), result.FilesWithIssues))
	
	return result, nil
}

// validateFileImports validates imports in a single Go file
func (im *ImportManager) validateFileImports(filePath string) ([]interfaces.ImportIssue, []interfaces.ImportConflict, error) {
	src, err := os.ReadFile(filePath)
	if err != nil {
		return nil, nil, err
	}

	// Parse the file
	file, err := parser.ParseFile(im.fileSet, filePath, src, parser.ParseComments)
	if err != nil {
		return nil, nil, err
	}

	var issues []interfaces.ImportIssue
	var conflicts []interfaces.ImportConflict

	// Check each import
	for _, imp := range file.Imports {
		if imp.Path == nil {
			continue
		}

		importPath := strings.Trim(imp.Path.Value, `"`)
		lineNum := im.fileSet.Position(imp.Pos()).Line

		// Check for relative imports
		if strings.HasPrefix(importPath, ".") {
			issues = append(issues, interfaces.ImportIssue{
				FilePath:     filePath,
				LineNumber:   lineNum,
				ImportPath:   importPath,
				IssueType:    interfaces.ImportIssueRelative,
				Severity:     "high",
				Description:  "Relative import detected",
				SuggestedFix: "Convert to absolute import path",
				AutoFixable:  true,
			})
		}

		// Check for invalid paths
		if !im.isValidImportPath(importPath) {
			issues = append(issues, interfaces.ImportIssue{
				FilePath:     filePath,
				LineNumber:   lineNum,
				ImportPath:   importPath,
				IssueType:    interfaces.ImportIssueInvalidPath,
				Severity:     "high",
				Description:  "Invalid import path format",
				SuggestedFix: "Fix import path format",
				AutoFixable:  false,
			})
		}

		// Check for absolute local paths
		if im.isAbsoluteLocalPath(importPath) {
			issues = append(issues, interfaces.ImportIssue{
				FilePath:     filePath,
				LineNumber:   lineNum,
				ImportPath:   importPath,
				IssueType:    interfaces.ImportIssueInconsistent,
				Severity:     "high",
				Description:  "Absolute local path detected",
				SuggestedFix: "Convert to module-relative path",
				AutoFixable:  true,
			})
		}

		// Check for unused imports (simple heuristic)
		if im.isImportUnused(file, importPath) {
			issues = append(issues, interfaces.ImportIssue{
				FilePath:     filePath,
				LineNumber:   lineNum,
				ImportPath:   importPath,
				IssueType:    interfaces.ImportIssueUnused,
				Severity:     "medium",
				Description:  "Import appears to be unused",
				SuggestedFix: "Remove unused import",
				AutoFixable:  true,
			})
		}
	}

	// Check for import conflicts (duplicate imports, naming conflicts)
	conflicts = im.detectImportConflicts(file, filePath)

	return issues, conflicts, nil
}

// isValidImportPath checks if an import path is valid
func (im *ImportManager) isValidImportPath(importPath string) bool {
	// Basic validation - could be extended
	if importPath == "" {
		return false
	}
	
	// Check for invalid characters
	invalidChars := []string{" ", "\t", "\n", "\r"}
	for _, char := range invalidChars {
		if strings.Contains(importPath, char) {
			return false
		}
	}
	
	return true
}

// isAbsoluteLocalPath checks if import path is an absolute local path
func (im *ImportManager) isAbsoluteLocalPath(importPath string) bool {
	// Check for Windows and Unix absolute paths
	windowsPath := regexp.MustCompile(`^[A-Za-z]:\\`)
	unixPath := regexp.MustCompile(`^/`)
	
	return windowsPath.MatchString(importPath) || unixPath.MatchString(importPath)
}

// isImportUnused checks if an import appears to be unused (simple heuristic)
func (im *ImportManager) isImportUnused(file *ast.File, importPath string) bool {
	// Extract package name from import path
	packageName := filepath.Base(importPath)
	if strings.Contains(packageName, ".") {
		parts := strings.Split(packageName, ".")
		packageName = parts[len(parts)-1]
	}

	// Look for usage of the package in the file
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

	return !used
}

// detectImportConflicts detects conflicts in imports
func (im *ImportManager) detectImportConflicts(file *ast.File, filePath string) []interfaces.ImportConflict {
	var conflicts []interfaces.ImportConflict
	
	importPaths := make(map[string][]int)
	packageNames := make(map[string][]string)

	// Collect imports and their line numbers
	for _, imp := range file.Imports {
		if imp.Path == nil {
			continue
		}

		importPath := strings.Trim(imp.Path.Value, `"`)
		lineNum := im.fileSet.Position(imp.Pos()).Line
		
		importPaths[importPath] = append(importPaths[importPath], lineNum)
		
		packageName := filepath.Base(importPath)
		packageNames[packageName] = append(packageNames[packageName], importPath)
	}

	// Check for duplicate imports
	for importPath, lines := range importPaths {
		if len(lines) > 1 {
			lineStrs := make([]string, len(lines))
			for i, line := range lines {
				lineStrs[i] = strconv.Itoa(line)
			}
			
			conflicts = append(conflicts, interfaces.ImportConflict{
				Type:             "duplicate_import",
				ConflictingPaths: []string{importPath},
				Severity:         "high",
				Description:      fmt.Sprintf("Import '%s' is duplicated on lines: %s", importPath, strings.Join(lineStrs, ", ")),
				Resolution:       "Remove duplicate imports",
			})
		}
	}

	// Check for package name conflicts
	for packageName, paths := range packageNames {
		if len(paths) > 1 {
			conflicts = append(conflicts, interfaces.ImportConflict{
				Type:             "package_name_conflict",
				ConflictingPaths: paths,
				Severity:         "medium",
				Description:      fmt.Sprintf("Package name '%s' conflicts between: %s", packageName, strings.Join(paths, ", ")),
				Resolution:       "Use import aliases to resolve naming conflicts",
			})
		}
	}

	return conflicts
}

// calculateSummary calculates validation summary from issues
func (im *ImportManager) calculateSummary(issues []interfaces.ImportIssue) interfaces.ValidationSummary {
	summary := interfaces.ValidationSummary{}
	
	for _, issue := range issues {
		switch issue.IssueType {
		case interfaces.ImportIssueRelative:
			summary.RelativeImports++
		case interfaces.ImportIssueInvalidPath:
			summary.InvalidPaths++
		case interfaces.ImportIssueCircular:
			summary.CircularDependencies++
		case interfaces.ImportIssueMissingModule:
			summary.MissingModules++
		case interfaces.ImportIssueUnused:
			summary.UnusedImports++
		case interfaces.ImportIssueInconsistent:
			summary.InconsistentNaming++
		}
	}
	
	return summary
}

// FixRelativeImports fixes relative imports in the project
func (m *GoModManager) FixRelativeImports(ctx context.Context, projectPath string) error {
	m.Log("INFO", fmt.Sprintf("Starting to fix relative imports in project: %s", projectPath))
	
	// First, we need to determine the module name from go.mod
	moduleName, err := m.getModuleName(projectPath)
	if err != nil {
		return m.errorManager.ProcessError(ctx, err, "import-fix", "get_module_name", nil)
	}

	im := NewImportManager(m.logger, projectPath)
	filesFixed := 0

	err = filepath.Walk(projectPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Skip non-Go files and vendor directories
		if !strings.HasSuffix(path, ".go") || strings.Contains(path, "vendor/") || strings.Contains(path, ".git/") {
			return nil
		}

		fixed, err := im.fixRelativeImportsInFile(path, moduleName, projectPath)
		if err != nil {
			m.logger.Warn("Failed to fix relative imports in file",
				zap.String("file", path),
				zap.Error(err))
			return nil // Continue with other files
		}

		if fixed {
			filesFixed++
		}

		return nil
	})

	if err != nil {
		return m.errorManager.ProcessError(ctx, err, "import-fix", "walk_project", nil)
	}

	m.Log("INFO", fmt.Sprintf("Fixed relative imports in %d files", filesFixed))
	return nil
}

// getModuleName extracts module name from go.mod
func (m *GoModManager) getModuleName(projectPath string) (string, error) {
	goModPath := filepath.Join(projectPath, "go.mod")
	if _, err := os.Stat(goModPath); os.IsNotExist(err) {
		// Try parent directory
		goModPath = filepath.Join(filepath.Dir(projectPath), "go.mod")
	}

	data, err := os.ReadFile(goModPath)
	if err != nil {
		return "", fmt.Errorf("failed to read go.mod: %v", err)
	}

	lines := strings.Split(string(data), "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "module ") {
			return strings.TrimSpace(strings.TrimPrefix(line, "module")), nil
		}
	}

	return "", fmt.Errorf("module declaration not found in go.mod")
}

// fixRelativeImportsInFile fixes relative imports in a single file
func (im *ImportManager) fixRelativeImportsInFile(filePath, moduleName, projectRoot string) (bool, error) {
	src, err := os.ReadFile(filePath)
	if err != nil {
		return false, err
	}

	originalContent := string(src)
	content := originalContent

	// Parse the file to find relative imports
	file, err := parser.ParseFile(im.fileSet, filePath, src, parser.ParseComments)
	if err != nil {
		return false, err
	}

	hasRelativeImports := false
	for _, imp := range file.Imports {
		if imp.Path == nil {
			continue
		}

		importPath := strings.Trim(imp.Path.Value, `"`)
		
		// Check if it's a relative import
		if strings.HasPrefix(importPath, ".") {
			hasRelativeImports = true
			
			// Convert relative path to absolute module path
			absolutePath := im.convertRelativeToAbsolute(importPath, filePath, moduleName, projectRoot)
			
			// Replace in content
			oldImport := fmt.Sprintf(`"%s"`, importPath)
			newImport := fmt.Sprintf(`"%s"`, absolutePath)
			content = strings.ReplaceAll(content, oldImport, newImport)
		}
	}

	// Write back if changes were made
	if hasRelativeImports && content != originalContent {
		err = os.WriteFile(filePath, []byte(content), 0644)
		if err != nil {
			return false, err
		}
		return true, nil
	}

	return false, nil
}

// convertRelativeToAbsolute converts a relative import path to absolute module path
func (im *ImportManager) convertRelativeToAbsolute(relativePath, currentFile, moduleName, projectRoot string) string {
	// Get directory of current file
	currentDir := filepath.Dir(currentFile)
	
	// Resolve the relative path
	targetDir := filepath.Join(currentDir, relativePath)
	targetDir = filepath.Clean(targetDir)
	
	// Convert to module-relative path
	relativeToProject, err := filepath.Rel(projectRoot, targetDir)
	if err != nil {
		// Fallback
		return relativePath
	}
	
	// Build module path
	modulePath := moduleName
	if relativeToProject != "." {
		modulePath = moduleName + "/" + strings.ReplaceAll(relativeToProject, "\\", "/")
	}
		return modulePath
}

// NormalizeModulePaths normalizes all module paths to use the expected prefix
func (m *GoModManager) NormalizeModulePaths(ctx context.Context, projectPath string, expectedPrefix string) error {
	m.Log("INFO", fmt.Sprintf("Starting to normalize module paths in project: %s with prefix: %s", projectPath, expectedPrefix))
	
	im := NewImportManager(m.logger, projectPath)
	filesFixed := 0

	err := filepath.Walk(projectPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Skip non-Go files and vendor directories
		if !strings.HasSuffix(path, ".go") || strings.Contains(path, "vendor/") || strings.Contains(path, ".git/") {
			return nil
		}

		fixed, err := im.normalizeImportsInFile(path, expectedPrefix)
		if err != nil {
			m.logger.Warn("Failed to normalize imports in file",
				zap.String("file", path),
				zap.Error(err))
			return nil // Continue with other files
		}

		if fixed {
			filesFixed++
		}

		return nil
	})

	if err != nil {
		return m.errorManager.ProcessError(ctx, err, "import-normalize", "walk_project", nil)
	}

	m.Log("INFO", fmt.Sprintf("Normalized module paths in %d files", filesFixed))
	return nil
}

// normalizeImportsInFile normalizes imports in a single file
func (im *ImportManager) normalizeImportsInFile(filePath, expectedPrefix string) (bool, error) {
	src, err := os.ReadFile(filePath)
	if err != nil {
		return false, err
	}

	originalContent := string(src)
	content := originalContent

	// Parse the file to find imports that need normalization
	file, err := parser.ParseFile(im.fileSet, filePath, src, parser.ParseComments)
	if err != nil {
		return false, err
	}

	hasChanges := false
	for _, imp := range file.Imports {
		if imp.Path == nil {
			continue
		}

		importPath := strings.Trim(imp.Path.Value, `"`)
		
		// Check if it's an absolute local path that needs normalization
		if im.isAbsoluteLocalPath(importPath) {
			hasChanges = true
			
			// Convert to expected module prefix
			normalizedPath := im.normalizeLocalPath(importPath, expectedPrefix)
			
			// Replace in content
			oldImport := fmt.Sprintf(`"%s"`, importPath)
			newImport := fmt.Sprintf(`"%s"`, normalizedPath)
			content = strings.ReplaceAll(content, oldImport, newImport)
		}
	}

	// Write back if changes were made
	if hasChanges && content != originalContent {
		err = os.WriteFile(filePath, []byte(content), 0644)
		if err != nil {
			return false, err
		}
		return true, nil
	}

	return false, nil
}

// normalizeLocalPath converts a local absolute path to expected module prefix
func (im *ImportManager) normalizeLocalPath(localPath, expectedPrefix string) string {
	// Common patterns to replace
	patterns := map[string]string{
		// Windows paths
		`d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/development/managers/`:     expectedPrefix + "/managers/",
		`D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/development/managers/`:     expectedPrefix + "/managers/",
		`d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\managers\`:     expectedPrefix + "/managers/",
		`D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\managers\`:     expectedPrefix + "/managers/",
		
		// Unix paths
		`/development/managers/`:                                               expectedPrefix + "/managers/",
		
		// Generic project paths
		`github.com/gerivdb/email-sender-1/development/managers/`:                        expectedPrefix + "/managers/",
		`github.com/gerivdb/email-sender-1/managers/`:                                    expectedPrefix + "/managers/",
	}

	normalizedPath := localPath
	for pattern, replacement := range patterns {
		if strings.Contains(normalizedPath, pattern) {
			normalizedPath = strings.ReplaceAll(normalizedPath, pattern, replacement)
			break
		}
	}

	// Clean up path separators
	normalizedPath = strings.ReplaceAll(normalizedPath, "\\", "/")
	
	return normalizedPath
}

// DetectImportConflicts detects import conflicts in the project
func (m *GoModManager) DetectImportConflicts(ctx context.Context, projectPath string) ([]interfaces.ImportConflict, error) {
	m.Log("INFO", fmt.Sprintf("Detecting import conflicts in project: %s", projectPath))
	
	im := NewImportManager(m.logger, projectPath)
	var allConflicts []interfaces.ImportConflict

	err := filepath.Walk(projectPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Skip non-Go files and vendor directories
		if !strings.HasSuffix(path, ".go") || strings.Contains(path, "vendor/") || strings.Contains(path, ".git/") {
			return nil
		}

		// Parse the file
		src, err := os.ReadFile(path)
		if err != nil {
			return err
		}

		file, err := parser.ParseFile(im.fileSet, path, src, parser.ParseComments)
		if err != nil {
			m.logger.Warn("Failed to parse file for conflict detection",
				zap.String("file", path),
				zap.Error(err))
			return nil // Continue with other files
		}

		conflicts := im.detectImportConflicts(file, path)
		allConflicts = append(allConflicts, conflicts...)

		return nil
	})

	if err != nil {
		return nil, m.errorManager.ProcessError(ctx, err, "import-conflicts", "walk_project", nil)
	}

	m.Log("INFO", fmt.Sprintf("Found %d import conflicts", len(allConflicts)))
	return allConflicts, nil
}

// ScanInvalidImports scans for invalid imports in the project
func (m *GoModManager) ScanInvalidImports(ctx context.Context, projectPath string) ([]interfaces.ImportIssue, error) {
	m.Log("INFO", fmt.Sprintf("Scanning for invalid imports in project: %s", projectPath))
	
	im := NewImportManager(m.logger, projectPath)
	var allIssues []interfaces.ImportIssue

	err := filepath.Walk(projectPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Skip non-Go files and vendor directories
		if !strings.HasSuffix(path, ".go") || strings.Contains(path, "vendor/") || strings.Contains(path, ".git/") {
			return nil
		}

		// Parse and validate the file
		issues, _, err := im.validateFileImports(path)
		if err != nil {
			m.logger.Warn("Failed to scan imports in file",
				zap.String("file", path),
				zap.Error(err))
			return nil // Continue with other files
		}

		allIssues = append(allIssues, issues...)

		return nil
	})

	if err != nil {
		return nil, m.errorManager.ProcessError(ctx, err, "import-scan", "walk_project", nil)
	}

	m.Log("INFO", fmt.Sprintf("Found %d import issues", len(allIssues)))
	return allIssues, nil
}

// AutoFixImports automatically fixes import issues in the project
func (m *GoModManager) AutoFixImports(ctx context.Context, projectPath string, options *interfaces.ImportFixOptions) (*interfaces.ImportFixResult, error) {
	m.Log("INFO", fmt.Sprintf("Starting auto-fix imports in project: %s", projectPath))
	
	if options == nil {
		options = &interfaces.ImportFixOptions{
			FixRelativeImports:   true,
			NormalizeModulePaths: true,
			RemoveUnusedImports:  true,
			StandardizeNaming:    true,
			CreateBackups:        true,
		}
	}

	result := &interfaces.ImportFixResult{
		FilesModified:   []string{},
		FilesCreated:    []string{},
		BackupsCreated:  []string{},
		IssuesFixed:     0,
		IssuesRemaining: 0,
	}

	// Get initial issue count
	initialIssues, err := m.ScanInvalidImports(ctx, projectPath)
	if err != nil {
		return nil, err
	}

	initialCount := len(initialIssues)

	// Create backup if requested
	if options.CreateBackups {
		backupDir, err := m.createProjectBackup(projectPath)
		if err != nil {
			m.logger.Warn("Failed to create backup", zap.Error(err))
		} else {
			result.BackupsCreated = append(result.BackupsCreated, backupDir)
		}
	}

	// Fix relative imports
	if options.FixRelativeImports {
		err = m.FixRelativeImports(ctx, projectPath)
		if err != nil {
			m.logger.Warn("Failed to fix relative imports", zap.Error(err))
		}
	}

	// Normalize module paths
	if options.NormalizeModulePaths && options.ExpectedModulePrefix != "" {
		err = m.NormalizeModulePaths(ctx, projectPath, options.ExpectedModulePrefix)
		if err != nil {
			m.logger.Warn("Failed to normalize module paths", zap.Error(err))
		}
	}

	// Remove unused imports
	if options.RemoveUnusedImports {
		filesFixed, err := m.removeUnusedImports(ctx, projectPath)
		if err != nil {
			m.logger.Warn("Failed to remove unused imports", zap.Error(err))
		} else {
			result.FilesModified = append(result.FilesModified, filesFixed...)
		}
	}

	// Get final issue count
	finalIssues, err := m.ScanInvalidImports(ctx, projectPath)
	if err != nil {
		return nil, err
	}

	finalCount := len(finalIssues)
	result.IssuesFixed = initialCount - finalCount
	result.IssuesRemaining = finalCount

	result.Summary = fmt.Sprintf("Fixed %d issues, %d remaining", result.IssuesFixed, result.IssuesRemaining)

	m.Log("INFO", fmt.Sprintf("Auto-fix completed: %s", result.Summary))
	return result, nil
}

// createProjectBackup creates a backup of the project
func (m *GoModManager) createProjectBackup(projectPath string) (string, error) {
	timestamp := time.Now().Format("20060102-150405")
	backupDir := fmt.Sprintf("%s.backup.%s", projectPath, timestamp)
	
	// Create backup directory
	err := os.MkdirAll(backupDir, 0755)
	if err != nil {
		return "", err
	}

	// Copy Go files (simple implementation - could be enhanced)
	err = filepath.Walk(projectPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Skip directories and non-Go files
		if info.IsDir() || !strings.HasSuffix(path, ".go") {
			return nil
		}

		relPath, err := filepath.Rel(projectPath, path)
		if err != nil {
			return err
		}

		backupPath := filepath.Join(backupDir, relPath)
		
		// Ensure backup directory exists
		err = os.MkdirAll(filepath.Dir(backupPath), 0755)
		if err != nil {
			return err
		}

		// Copy file
		data, err := os.ReadFile(path)
		if err != nil {
			return err
		}

		return os.WriteFile(backupPath, data, info.Mode())
	})

	if err != nil {
		os.RemoveAll(backupDir) // Clean up on error
		return "", err
	}

	return backupDir, nil
}

// removeUnusedImports removes unused imports from Go files
func (m *GoModManager) removeUnusedImports(ctx context.Context, projectPath string) ([]string, error) {
	var modifiedFiles []string
	im := NewImportManager(m.logger, projectPath)

	err := filepath.Walk(projectPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Skip non-Go files and vendor directories
		if !strings.HasSuffix(path, ".go") || strings.Contains(path, "vendor/") || strings.Contains(path, ".git/") {
			return nil
		}

		modified, err := im.removeUnusedImportsFromFile(path)
		if err != nil {
			m.logger.Warn("Failed to remove unused imports from file",
				zap.String("file", path),
				zap.Error(err))
			return nil // Continue with other files
		}

		if modified {
			modifiedFiles = append(modifiedFiles, path)
		}

		return nil
	})

	if err != nil {
		return nil, m.errorManager.ProcessError(ctx, err, "remove-unused-imports", "walk_project", nil)
	}

	return modifiedFiles, nil
}

// removeUnusedImportsFromFile removes unused imports from a single file
func (im *ImportManager) removeUnusedImportsFromFile(filePath string) (bool, error) {
	src, err := os.ReadFile(filePath)
	if err != nil {
		return false, err
	}

	originalContent := string(src)

	// Parse the file
	file, err := parser.ParseFile(im.fileSet, filePath, src, parser.ParseComments)
	if err != nil {
		return false, err
	}

	// Find unused imports
	var unusedImports []string
	for _, imp := range file.Imports {
		if imp.Path == nil {
			continue
		}

		importPath := strings.Trim(imp.Path.Value, `"`)
		if im.isImportUnused(file, importPath) {
			unusedImports = append(unusedImports, importPath)
		}
	}

	if len(unusedImports) == 0 {
		return false, nil
	}

	// Remove unused imports from content
	content := originalContent
	for _, unusedImport := range unusedImports {
		content = im.removeImportFromContent(content, unusedImport)
	}

	// Write back if changes were made
	if content != originalContent {
		err = os.WriteFile(filePath, []byte(content), 0644)
		if err != nil {
			return false, err
		}
		return true, nil
	}

	return false, nil
}

// removeImportFromContent removes an import line from file content
func (im *ImportManager) removeImportFromContent(content, importPath string) string {
	lines := strings.Split(content, "\n")
	var result []string
	
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		
		// Check if this line contains the import to remove
		if strings.Contains(trimmed, `"`+importPath+`"`) {
			// Skip this line
			continue
		}
		
		result = append(result, line)
	}
	
	return strings.Join(result, "\n")
}

// ValidateModuleStructure validates the overall module structure
func (m *GoModManager) ValidateModuleStructure(ctx context.Context, projectPath string) (*interfaces.ModuleStructureValidation, error) {
	m.Log("INFO", fmt.Sprintf("Validating module structure for project: %s", projectPath))
	
	validation := &interfaces.ModuleStructureValidation{
		ModuleName:        "",
		GoModValid:        false,
		GoSumValid:        false,
		ModulePathCorrect: false,
		DependenciesValid: false,
		Errors:            []string{},
		Warnings:          []string{},
	}

	// Check go.mod exists and is valid
	goModPath := filepath.Join(projectPath, "go.mod")
	if _, err := os.Stat(goModPath); os.IsNotExist(err) {
		validation.Errors = append(validation.Errors, "go.mod file not found")
	} else {
		// Validate go.mod content
		moduleName, err := m.getModuleName(projectPath)
		if err != nil {
			validation.Errors = append(validation.Errors, fmt.Sprintf("Invalid go.mod: %v", err))
		} else {
			validation.ModuleName = moduleName
			validation.GoModValid = true
			validation.ModulePathCorrect = m.isValidModulePath(moduleName)
		}
	}

	// Check go.sum exists (optional but recommended)
	goSumPath := filepath.Join(projectPath, "go.sum")
	if _, err := os.Stat(goSumPath); os.IsNotExist(err) {
		validation.Warnings = append(validation.Warnings, "go.sum file not found - dependencies may not be locked")
	} else {
		validation.GoSumValid = true
	}

	// Validate dependencies
	if validation.GoModValid {
		deps, err := m.List()
		if err != nil {
			validation.Errors = append(validation.Errors, fmt.Sprintf("Failed to list dependencies: %v", err))
		} else {
			validation.DependenciesValid = m.validateDependencies(deps, validation)
		}
	}

	m.Log("INFO", fmt.Sprintf("Module structure validation completed. Valid: %t", len(validation.Errors) == 0))
	return validation, nil
}

// isValidModulePath checks if a module path is valid
func (m *GoModManager) isValidModulePath(modulePath string) bool {
	// Basic validation - should start with domain/organization/repo
	parts := strings.Split(modulePath, "/")
	
	// Should have at least 3 parts: domain/org/repo
	if len(parts) < 3 {
		return false
	}
	
	// Domain should contain a dot
	if !strings.Contains(parts[0], ".") {
		return false
	}
	
	return true
}

// validateDependencies validates the listed dependencies
func (m *GoModManager) validateDependencies(deps []Dependency, validation *interfaces.ModuleStructureValidation) bool {
	valid := true
	
	for _, dep := range deps {
		// Check for empty names or versions
		if dep.Name == "" {
			validation.Errors = append(validation.Errors, "Dependency with empty name found")
			valid = false
		}
		
		if dep.Version == "" {
			validation.Warnings = append(validation.Warnings, fmt.Sprintf("Dependency %s has no version specified", dep.Name))
		}
		
		// Check for suspicious version patterns
		if strings.Contains(dep.Version, "v0.0.0-") {
			validation.Warnings = append(validation.Warnings, fmt.Sprintf("Dependency %s uses pseudo-version %s", dep.Name, dep.Version))
		}
	}
	
	return valid
}

// GenerateImportReport generates a comprehensive import report
func (m *GoModManager) GenerateImportReport(ctx context.Context, projectPath string) (*interfaces.ImportReport, error) {
	m.Log("INFO", fmt.Sprintf("Generating import report for project: %s", projectPath))
	
	im := NewImportManager(m.logger, projectPath)
	
	// Get module name
	moduleName, err := m.getModuleName(projectPath)
	if err != nil {
		moduleName = "unknown"
	}
	
	report := &interfaces.ImportReport{
		ProjectPath:     projectPath,
		ModuleName:      moduleName,
		TotalGoFiles:    0,
		TotalImports:    0,
		ExternalImports: 0,
		InternalImports: 0,
		RelativeImports: 0,
		Issues:          []interfaces.ImportIssue{},
		DependencyGraph: make(map[string][]string),
		Statistics:      interfaces.ImportStatistics{},
		Recommendations: []string{},
		GeneratedAt:     time.Now().Format(time.RFC3339),
	}

	// Collect import information
	dependencyMap := make(map[string]int)
	internalModuleMap := make(map[string]int)

	err = filepath.Walk(projectPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Skip non-Go files and vendor directories
		if !strings.HasSuffix(path, ".go") || strings.Contains(path, "vendor/") || strings.Contains(path, ".git/") {
			return nil
		}

		report.TotalGoFiles++

		// Parse file for imports
		src, err := os.ReadFile(path)
		if err != nil {
			return err
		}

		file, err := parser.ParseFile(im.fileSet, path, src, parser.ParseComments)
		if err != nil {
			return nil // Skip files that can't be parsed
		}

		var fileImports []string
		for _, imp := range file.Imports {
			if imp.Path == nil {
				continue
			}

			importPath := strings.Trim(imp.Path.Value, `"`)
			report.TotalImports++
			fileImports = append(fileImports, importPath)

			// Categorize import
			if strings.HasPrefix(importPath, ".") {
				report.RelativeImports++
			} else if strings.HasPrefix(importPath, moduleName) {
				report.InternalImports++
				internalModuleMap[importPath]++
			} else {
				report.ExternalImports++
				
				// Extract root dependency
				rootDep := strings.Split(importPath, "/")
				if len(rootDep) > 0 {
					dependencyMap[rootDep[0]]++
				}
			}
		}

		// Add to dependency graph
		if len(fileImports) > 0 {
			relPath, _ := filepath.Rel(projectPath, path)
			report.DependencyGraph[relPath] = fileImports
		}

		return nil
	})

	if err != nil {
		return nil, m.errorManager.ProcessError(ctx, err, "import-report", "walk_project", nil)
	}

	// Generate statistics
	report.Statistics = im.generateStatistics(dependencyMap, internalModuleMap)

	// Get issues
	report.Issues, err = m.ScanInvalidImports(ctx, projectPath)
	if err != nil {
		m.logger.Warn("Failed to scan imports for report", zap.Error(err))
	}

	// Generate recommendations
	report.Recommendations = im.generateRecommendations(report)

	m.Log("INFO", fmt.Sprintf("Import report generated with %d files, %d imports", report.TotalGoFiles, report.TotalImports))
	return report, nil
}

// generateStatistics generates usage statistics
func (im *ImportManager) generateStatistics(dependencyMap, internalModuleMap map[string]int) interfaces.ImportStatistics {
	stats := interfaces.ImportStatistics{
		TopExternalDependencies: []interfaces.DependencyUsage{},
		LargestInternalModules:  []interfaces.ModuleUsage{},
	}

	// Top external dependencies
	for dep, count := range dependencyMap {
		stats.TopExternalDependencies = append(stats.TopExternalDependencies, interfaces.DependencyUsage{
			Name:  dep,
			Count: count,
		})
	}

	// Sort by usage count
	sort.Slice(stats.TopExternalDependencies, func(i, j int) bool {
		return stats.TopExternalDependencies[i].Count > stats.TopExternalDependencies[j].Count
	})

	// Keep only top 10
	if len(stats.TopExternalDependencies) > 10 {
		stats.TopExternalDependencies = stats.TopExternalDependencies[:10]
	}

	// Top internal modules
	for module, count := range internalModuleMap {
		stats.LargestInternalModules = append(stats.LargestInternalModules, interfaces.ModuleUsage{
			Path:  module,
			Count: count,
		})
	}

	// Sort by usage count
	sort.Slice(stats.LargestInternalModules, func(i, j int) bool {
		return stats.LargestInternalModules[i].Count > stats.LargestInternalModules[j].Count
	})

	// Keep only top 10
	if len(stats.LargestInternalModules) > 10 {
		stats.LargestInternalModules = stats.LargestInternalModules[:10]
	}

	return stats
}

// generateRecommendations generates recommendations based on the report
func (im *ImportManager) generateRecommendations(report *interfaces.ImportReport) []string {
	var recommendations []string

	// Check for relative imports
	if report.RelativeImports > 0 {
		recommendations = append(recommendations, fmt.Sprintf("Consider fixing %d relative imports for better maintainability", report.RelativeImports))
	}

	// Check import ratio
	if report.ExternalImports > 0 {
		ratio := float64(report.ExternalImports) / float64(report.TotalImports)
		if ratio > 0.8 {
			recommendations = append(recommendations, "High external dependency ratio - consider reducing external dependencies")
		}
	}

	// Check for issues
	if len(report.Issues) > 0 {
		recommendations = append(recommendations, fmt.Sprintf("Fix %d import issues found during analysis", len(report.Issues)))
	}

	// Check module structure
	if !strings.Contains(report.ModuleName, ".") {
		recommendations = append(recommendations, "Consider using a fully qualified module name (e.g., github.com/org/repo)")
	}

	return recommendations
}
