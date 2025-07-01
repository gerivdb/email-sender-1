package analyzer

import (
	"EMAIL_SENDER_1/development/managers/smart-variable-manager/interfaces"
	"context"
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

// ContextAnalyzer provides comprehensive project context analysis
type ContextAnalyzer struct {
	fset *token.FileSet
}

// NewContextAnalyzer creates a new context analyzer instance
func NewContextAnalyzer() *ContextAnalyzer {
	return &ContextAnalyzer{
		fset: token.NewFileSet(),
	}
}

// AnalyzeProject performs comprehensive project context analysis
func (ca *ContextAnalyzer) AnalyzeProject(ctx context.Context, projectPath string) (*interfaces.ContextAnalysis, error) {
	analysis := &interfaces.ContextAnalysis{
		ProjectInfo:     interfaces.ProjectInfo{},
		CodePatterns:    interfaces.CodePatterns{},
		Dependencies:    []interfaces.DependencyInfo{},
		ConventionInfo:  interfaces.ConventionInfo{},
		HistoricalData:  interfaces.HistoricalData{},
		EnvironmentInfo: interfaces.EnvironmentInfo{},
		Confidence:      0.0,
		AnalyzedAt:      time.Now(),
	}

	// Analyze project structure and metadata
	if err := ca.analyzeProjectInfo(projectPath, &analysis.ProjectInfo); err != nil {
		return nil, fmt.Errorf("failed to analyze project info: %w", err)
	}

	// Analyze code patterns
	if err := ca.analyzeCodePatterns(projectPath, &analysis.CodePatterns); err != nil {
		return nil, fmt.Errorf("failed to analyze code patterns: %w", err)
	}

	// Analyze dependencies
	if err := ca.analyzeDependencies(projectPath, &analysis.Dependencies); err != nil {
		return nil, fmt.Errorf("failed to analyze dependencies: %w", err)
	}

	// Analyze coding conventions
	if err := ca.analyzeConventions(projectPath, &analysis.ConventionInfo); err != nil {
		return nil, fmt.Errorf("failed to analyze conventions: %w", err)
	}

	// Analyze environment
	if err := ca.analyzeEnvironment(&analysis.EnvironmentInfo); err != nil {
		return nil, fmt.Errorf("failed to analyze environment: %w", err)
	}

	// Load historical data (placeholder - would integrate with storage)
	ca.loadHistoricalData(&analysis.HistoricalData)

	// Calculate confidence score
	analysis.Confidence = ca.calculateAnalysisConfidence(analysis)

	return analysis, nil
}

// analyzeProjectInfo analyzes basic project information
func (ca *ContextAnalyzer) analyzeProjectInfo(projectPath string, projectInfo *interfaces.ProjectInfo) error {
	// Extract project name from path
	projectInfo.Name = filepath.Base(projectPath)

	// Detect language and framework
	if err := ca.detectLanguageAndFramework(projectPath, projectInfo); err != nil {
		return err
	}

	// Detect version
	if err := ca.detectVersion(projectPath, projectInfo); err != nil {
		// Non-critical error, continue
		projectInfo.Version = "unknown"
	}

	// Detect architecture
	projectInfo.Architecture = ca.detectArchitecture(projectPath)

	// Initialize metadata
	projectInfo.Metadata = make(map[string]string)
	projectInfo.Metadata["analyzed_at"] = time.Now().Format(time.RFC3339)

	return nil
}

// detectLanguageAndFramework detects the primary language and framework
func (ca *ContextAnalyzer) detectLanguageAndFramework(projectPath string, projectInfo *interfaces.ProjectInfo) error {
	// Check for Go files
	goModPath := filepath.Join(projectPath, "go.mod")
	if _, err := os.Stat(goModPath); err == nil {
		projectInfo.Language = "go"

		// Try to detect Go framework
		framework := ca.detectGoFramework(projectPath)
		projectInfo.Framework = framework
		return nil
	}

	// Check for other languages (extensible)
	if ca.hasFiles(projectPath, ".py") {
		projectInfo.Language = "python"
		projectInfo.Framework = ca.detectPythonFramework(projectPath)
		return nil
	}

	if ca.hasFiles(projectPath, ".js") || ca.hasFiles(projectPath, ".ts") {
		projectInfo.Language = "javascript"
		projectInfo.Framework = ca.detectJavaScriptFramework(projectPath)
		return nil
	}

	// Default to unknown
	projectInfo.Language = "unknown"
	projectInfo.Framework = "unknown"
	return nil
}

// detectGoFramework detects Go framework being used
func (ca *ContextAnalyzer) detectGoFramework(projectPath string) string {
	goModContent, err := os.ReadFile(filepath.Join(projectPath, "go.mod"))
	if err != nil {
		return "standard"
	}

	content := string(goModContent)

	// Check for popular Go frameworks
	if strings.Contains(content, "github.com/gin-gonic/gin") {
		return "gin"
	}
	if strings.Contains(content, "github.com/gorilla/mux") {
		return "gorilla"
	}
	if strings.Contains(content, "github.com/labstack/echo") {
		return "echo"
	}
	if strings.Contains(content, "github.com/gofiber/fiber") {
		return "fiber"
	}
	if strings.Contains(content, "go.uber.org/fx") {
		return "fx"
	}

	return "standard"
}

// detectPythonFramework detects Python framework (placeholder)
func (ca *ContextAnalyzer) detectPythonFramework(projectPath string) string {
	// Check for requirements.txt or setup.py
	if ca.containsInFile(filepath.Join(projectPath, "requirements.txt"), "django") {
		return "django"
	}
	if ca.containsInFile(filepath.Join(projectPath, "requirements.txt"), "flask") {
		return "flask"
	}
	if ca.containsInFile(filepath.Join(projectPath, "requirements.txt"), "fastapi") {
		return "fastapi"
	}
	return "standard"
}

// detectJavaScriptFramework detects JavaScript framework (placeholder)
func (ca *ContextAnalyzer) detectJavaScriptFramework(projectPath string) string {
	packageJsonPath := filepath.Join(projectPath, "package.json")
	if ca.containsInFile(packageJsonPath, "react") {
		return "react"
	}
	if ca.containsInFile(packageJsonPath, "vue") {
		return "vue"
	}
	if ca.containsInFile(packageJsonPath, "angular") {
		return "angular"
	}
	if ca.containsInFile(packageJsonPath, "next") {
		return "nextjs"
	}
	return "standard"
}

// detectVersion detects project version
func (ca *ContextAnalyzer) detectVersion(projectPath string, projectInfo *interfaces.ProjectInfo) error {
	// Try go.mod first
	if projectInfo.Language == "go" {
		goModContent, err := os.ReadFile(filepath.Join(projectPath, "go.mod"))
		if err == nil {
			lines := strings.Split(string(goModContent), "\n")
			for _, line := range lines {
				if strings.HasPrefix(strings.TrimSpace(line), "module") {
					// Extract module version if available
					parts := strings.Fields(line)
					if len(parts) > 2 {
						projectInfo.Version = parts[2]
						return nil
					}
				}
			}
		}
	}

	// Try package.json
	packageJsonPath := filepath.Join(projectPath, "package.json")
	if content, err := os.ReadFile(packageJsonPath); err == nil {
		versionRegex := regexp.MustCompile(`"version":\s*"([^"]+)"`)
		if matches := versionRegex.FindStringSubmatch(string(content)); len(matches) > 1 {
			projectInfo.Version = matches[1]
			return nil
		}
	}

	// Try VERSION file
	versionPath := filepath.Join(projectPath, "VERSION")
	if content, err := os.ReadFile(versionPath); err == nil {
		projectInfo.Version = strings.TrimSpace(string(content))
		return nil
	}

	return fmt.Errorf("version not found")
}

// detectArchitecture detects project architecture pattern
func (ca *ContextAnalyzer) detectArchitecture(projectPath string) string {
	// Check for common architecture patterns
	if ca.hasDirectory(projectPath, "cmd") && ca.hasDirectory(projectPath, "internal") {
		return "standard_go_layout"
	}
	if ca.hasDirectory(projectPath, "controllers") && ca.hasDirectory(projectPath, "models") {
		return "mvc"
	}
	if ca.hasDirectory(projectPath, "handlers") && ca.hasDirectory(projectPath, "services") {
		return "layered"
	}
	if ca.hasDirectory(projectPath, "domain") && ca.hasDirectory(projectPath, "infrastructure") {
		return "clean_architecture"
	}
	if ca.hasDirectory(projectPath, "microservices") {
		return "microservices"
	}
	return "unknown"
}

// analyzeCodePatterns analyzes code patterns in the project
func (ca *ContextAnalyzer) analyzeCodePatterns(projectPath string, codePatterns *interfaces.CodePatterns) error {
	// Initialize pattern structures
	codePatterns.NamingConventions = []interfaces.NamingPattern{}
	codePatterns.TypeUsage = make(map[string]int)
	codePatterns.CommonStructures = []interfaces.StructurePattern{}
	codePatterns.FunctionSignatures = []interfaces.FunctionPattern{}
	codePatterns.VariableScopes = []interfaces.ScopePattern{}

	// Analyze Go files if it's a Go project
	return filepath.Walk(projectPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil // Continue walking on errors
		}

		if !info.IsDir() && strings.HasSuffix(path, ".go") {
			if err := ca.analyzeGoFile(path, codePatterns); err != nil {
				// Log error but continue
				fmt.Printf("Warning: failed to analyze %s: %v\n", path, err)
			}
		}

		return nil
	})
}

// analyzeGoFile analyzes a single Go file for patterns
func (ca *ContextAnalyzer) analyzeGoFile(filePath string, codePatterns *interfaces.CodePatterns) error {
	content, err := os.ReadFile(filePath)
	if err != nil {
		return err
	}

	file, err := parser.ParseFile(ca.fset, filePath, content, parser.ParseComments)
	if err != nil {
		return err
	}

	// Analyze naming conventions
	ca.analyzeNamingConventions(file, codePatterns)

	// Analyze type usage
	ca.analyzeTypeUsage(file, codePatterns)

	// Analyze structures
	ca.analyzeStructures(file, codePatterns)

	// Analyze function signatures
	ca.analyzeFunctionSignatures(file, codePatterns)

	// Analyze variable scopes
	ca.analyzeVariableScopes(file, codePatterns)

	return nil
}

// analyzeNamingConventions analyzes naming conventions in the code
func (ca *ContextAnalyzer) analyzeNamingConventions(file *ast.File, codePatterns *interfaces.CodePatterns) {
	namingPatterns := make(map[string]*interfaces.NamingPattern)

	ast.Inspect(file, func(n ast.Node) bool {
		switch node := n.(type) {
		case *ast.FuncDecl:
			if node.Name != nil {
				pattern := ca.detectNamingPattern(node.Name.Name)
				ca.updateNamingPattern(namingPatterns, "function", pattern, node.Name.Name)
			}
		case *ast.GenDecl:
			if node.Tok == token.VAR || node.Tok == token.CONST {
				for _, spec := range node.Specs {
					if valueSpec, ok := spec.(*ast.ValueSpec); ok {
						for _, name := range valueSpec.Names {
							pattern := ca.detectNamingPattern(name.Name)
							tokenType := "variable"
							if node.Tok == token.CONST {
								tokenType = "constant"
							}
							ca.updateNamingPattern(namingPatterns, tokenType, pattern, name.Name)
						}
					}
				}
			} else if node.Tok == token.TYPE {
				for _, spec := range node.Specs {
					if typeSpec, ok := spec.(*ast.TypeSpec); ok {
						pattern := ca.detectNamingPattern(typeSpec.Name.Name)
						ca.updateNamingPattern(namingPatterns, "type", pattern, typeSpec.Name.Name)
					}
				}
			}
		}
		return true
	})

	// Convert map to slice
	for _, pattern := range namingPatterns {
		pattern.Confidence = float64(pattern.Frequency) / 10.0 // Simple confidence calculation
		if pattern.Confidence > 1.0 {
			pattern.Confidence = 1.0
		}
		codePatterns.NamingConventions = append(codePatterns.NamingConventions, *pattern)
	}
}

// detectNamingPattern detects the naming pattern used
func (ca *ContextAnalyzer) detectNamingPattern(name string) string {
	if name == strings.ToUpper(name) {
		return "UPPER_CASE"
	}
	if name == strings.ToLower(name) {
		if strings.Contains(name, "_") {
			return "snake_case"
		}
		return "lowercase"
	}
	if strings.Contains(name, "_") {
		return "Snake_Case"
	}
	if name[0] >= 'A' && name[0] <= 'Z' {
		return "PascalCase"
	}
	return "camelCase"
}

// updateNamingPattern updates the naming pattern statistics
func (ca *ContextAnalyzer) updateNamingPattern(patterns map[string]*interfaces.NamingPattern, typ, pattern, example string) {
	key := typ + "_" + pattern
	if existing, exists := patterns[key]; exists {
		existing.Frequency++
		if len(existing.Examples) < 5 { // Keep up to 5 examples
			existing.Examples = append(existing.Examples, example)
		}
	} else {
		patterns[key] = &interfaces.NamingPattern{
			Type:      typ,
			Pattern:   pattern,
			Frequency: 1,
			Examples:  []string{example},
		}
	}
}

// analyzeTypeUsage analyzes type usage patterns
func (ca *ContextAnalyzer) analyzeTypeUsage(file *ast.File, codePatterns *interfaces.CodePatterns) {
	ast.Inspect(file, func(n ast.Node) bool {
		switch node := n.(type) {
		case *ast.Field:
			typeStr := ca.typeToString(node.Type)
			codePatterns.TypeUsage[typeStr]++
		case *ast.FuncDecl:
			if node.Type.Params != nil {
				for _, param := range node.Type.Params.List {
					typeStr := ca.typeToString(param.Type)
					codePatterns.TypeUsage[typeStr]++
				}
			}
			if node.Type.Results != nil {
				for _, result := range node.Type.Results.List {
					typeStr := ca.typeToString(result.Type)
					codePatterns.TypeUsage[typeStr]++
				}
			}
		}
		return true
	})
}

// analyzeStructures analyzes common structure patterns
func (ca *ContextAnalyzer) analyzeStructures(file *ast.File, codePatterns *interfaces.CodePatterns) {
	ast.Inspect(file, func(n ast.Node) bool {
		if genDecl, ok := n.(*ast.GenDecl); ok && genDecl.Tok == token.TYPE {
			for _, spec := range genDecl.Specs {
				if typeSpec, ok := spec.(*ast.TypeSpec); ok {
					if structType, ok := typeSpec.Type.(*ast.StructType); ok {
						structPattern := ca.analyzeStructPattern(typeSpec.Name.Name, structType)
						codePatterns.CommonStructures = append(codePatterns.CommonStructures, structPattern)
					}
				}
			}
		}
		return true
	})
}

// analyzeStructPattern analyzes a struct pattern
func (ca *ContextAnalyzer) analyzeStructPattern(name string, structType *ast.StructType) interfaces.StructurePattern {
	pattern := interfaces.StructurePattern{
		Type:     "struct",
		Name:     name,
		Fields:   []interfaces.FieldPattern{},
		Usage:    1, // Would need cross-reference analysis for accurate count
		Context:  "definition",
		Metadata: make(map[string]string),
	}

	for _, field := range structType.Fields.List {
		for _, fieldName := range field.Names {
			fieldPattern := interfaces.FieldPattern{
				Name:      fieldName.Name,
				Type:      ca.typeToString(field.Type),
				Required:  true, // Default assumption
				Frequency: 1,
			}

			if field.Tag != nil {
				fieldPattern.Tags = []string{field.Tag.Value}
			}

			pattern.Fields = append(pattern.Fields, fieldPattern)
		}
	}

	return pattern
}

// analyzeFunctionSignatures analyzes function signature patterns
func (ca *ContextAnalyzer) analyzeFunctionSignatures(file *ast.File, codePatterns *interfaces.CodePatterns) {
	ast.Inspect(file, func(n ast.Node) bool {
		if funcDecl, ok := n.(*ast.FuncDecl); ok && funcDecl.Name != nil {
			pattern := ca.analyzeFunctionPattern(funcDecl)
			codePatterns.FunctionSignatures = append(codePatterns.FunctionSignatures, pattern)
		}
		return true
	})
}

// analyzeFunctionPattern analyzes a function pattern
func (ca *ContextAnalyzer) analyzeFunctionPattern(funcDecl *ast.FuncDecl) interfaces.FunctionPattern {
	pattern := interfaces.FunctionPattern{
		Name:        funcDecl.Name.Name,
		Parameters:  []interfaces.ParameterPattern{},
		ReturnTypes: []string{},
		Usage:       1,
		Category:    ca.categorizeFunctionName(funcDecl.Name.Name),
		Complexity:  ca.calculateFunctionComplexity(funcDecl),
	}

	// Analyze parameters
	if funcDecl.Type.Params != nil {
		for i, param := range funcDecl.Type.Params.List {
			for _, name := range param.Names {
				paramPattern := interfaces.ParameterPattern{
					Name:      name.Name,
					Type:      ca.typeToString(param.Type),
					Position:  i,
					Optional:  false, // Go doesn't have optional parameters
					Frequency: 1,
				}
				pattern.Parameters = append(pattern.Parameters, paramPattern)
			}
		}
	}

	// Analyze return types
	if funcDecl.Type.Results != nil {
		for _, result := range funcDecl.Type.Results.List {
			pattern.ReturnTypes = append(pattern.ReturnTypes, ca.typeToString(result.Type))
		}
	}

	return pattern
}

// categorizeFunctionName categorizes a function based on its name
func (ca *ContextAnalyzer) categorizeFunctionName(name string) string {
	name = strings.ToLower(name)

	if strings.HasPrefix(name, "handle") || strings.HasSuffix(name, "handler") {
		return "handler"
	}
	if strings.HasPrefix(name, "get") || strings.HasPrefix(name, "fetch") || strings.HasPrefix(name, "retrieve") {
		return "getter"
	}
	if strings.HasPrefix(name, "set") || strings.HasPrefix(name, "update") || strings.HasPrefix(name, "save") {
		return "setter"
	}
	if strings.HasPrefix(name, "create") || strings.HasPrefix(name, "new") || strings.HasPrefix(name, "make") {
		return "constructor"
	}
	if strings.HasPrefix(name, "validate") || strings.HasPrefix(name, "check") || strings.HasPrefix(name, "verify") {
		return "validator"
	}
	if strings.HasPrefix(name, "parse") || strings.HasPrefix(name, "convert") || strings.HasPrefix(name, "transform") {
		return "transformer"
	}
	if strings.HasPrefix(name, "test") || strings.HasSuffix(name, "test") {
		return "test"
	}

	return "business"
}

// calculateFunctionComplexity calculates function complexity (simplified)
func (ca *ContextAnalyzer) calculateFunctionComplexity(funcDecl *ast.FuncDecl) int {
	complexity := 1 // Base complexity

	if funcDecl.Body != nil {
		ast.Inspect(funcDecl.Body, func(n ast.Node) bool {
			switch n.(type) {
			case *ast.IfStmt, *ast.ForStmt, *ast.RangeStmt, *ast.SwitchStmt, *ast.TypeSwitchStmt:
				complexity++
			case *ast.CaseClause:
				complexity++
			}
			return true
		})
	}

	return complexity
}

// analyzeVariableScopes analyzes variable scope patterns
func (ca *ContextAnalyzer) analyzeVariableScopes(file *ast.File, codePatterns *interfaces.CodePatterns) {
	// Analyze package-level variables
	packageScope := interfaces.ScopePattern{
		Scope:     "package",
		Variables: []interfaces.VariableInfo{},
		Usage:     1,
		Context:   "package_level",
		Metadata:  make(map[string]string),
	}

	ast.Inspect(file, func(n ast.Node) bool {
		if genDecl, ok := n.(*ast.GenDecl); ok && genDecl.Tok == token.VAR {
			for _, spec := range genDecl.Specs {
				if valueSpec, ok := spec.(*ast.ValueSpec); ok {
					for i, name := range valueSpec.Names {
						varInfo := interfaces.VariableInfo{
							Name:       name.Name,
							Type:       "unknown",
							Mutability: "var",
							Lifetime:   "persistent",
							Purpose:    "unknown",
						}

						if valueSpec.Type != nil {
							varInfo.Type = ca.typeToString(valueSpec.Type)
						}

						if i < len(valueSpec.Values) {
							varInfo.InitialValue = ca.extractValue(valueSpec.Values[i])
						}

						packageScope.Variables = append(packageScope.Variables, varInfo)
					}
				}
			}
		}
		return true
	})

	if len(packageScope.Variables) > 0 {
		codePatterns.VariableScopes = append(codePatterns.VariableScopes, packageScope)
	}
}

// analyzeDependencies analyzes project dependencies
func (ca *ContextAnalyzer) analyzeDependencies(projectPath string, dependencies *[]interfaces.DependencyInfo) error {
	// Analyze Go dependencies
	goModPath := filepath.Join(projectPath, "go.mod")
	if _, err := os.Stat(goModPath); err == nil {
		return ca.analyzeGoDependencies(goModPath, dependencies)
	}

	// Analyze other dependency files (extensible)
	packageJsonPath := filepath.Join(projectPath, "package.json")
	if _, err := os.Stat(packageJsonPath); err == nil {
		return ca.analyzeNodeDependencies(packageJsonPath, dependencies)
	}

	requirementsPath := filepath.Join(projectPath, "requirements.txt")
	if _, err := os.Stat(requirementsPath); err == nil {
		return ca.analyzePythonDependencies(requirementsPath, dependencies)
	}

	return nil // No dependencies found, not an error
}

// analyzeGoDependencies analyzes Go module dependencies
func (ca *ContextAnalyzer) analyzeGoDependencies(goModPath string, dependencies *[]interfaces.DependencyInfo) error {
	content, err := os.ReadFile(goModPath)
	if err != nil {
		return err
	}

	lines := strings.Split(string(content), "\n")
	inRequireBlock := false

	for _, line := range lines {
		line = strings.TrimSpace(line)

		if line == "require (" {
			inRequireBlock = true
			continue
		}

		if line == ")" && inRequireBlock {
			inRequireBlock = false
			continue
		}

		if inRequireBlock || strings.HasPrefix(line, "require ") {
			// Parse dependency line
			if dep := ca.parseGoDependency(line); dep != nil {
				*dependencies = append(*dependencies, *dep)
			}
		}
	}

	return nil
}

// parseGoDependency parses a Go dependency line
func (ca *ContextAnalyzer) parseGoDependency(line string) *interfaces.DependencyInfo {
	line = strings.TrimSpace(line)
	line = strings.TrimPrefix(line, "require ")

	parts := strings.Fields(line)
	if len(parts) < 2 {
		return nil
	}

	name := parts[0]
	version := parts[1]

	// Determine dependency type and common variables
	depType := "direct"
	if strings.Contains(line, "// indirect") {
		depType = "indirect"
	}

	commonVars := ca.getCommonVariablesForDependency(name)

	return &interfaces.DependencyInfo{
		Name:      name,
		Version:   version,
		Type:      depType,
		Usage:     []string{}, // Would need code analysis to populate
		Variables: commonVars,
		Metadata:  make(map[string]string),
	}
}

// getCommonVariablesForDependency returns common variables for known dependencies
func (ca *ContextAnalyzer) getCommonVariablesForDependency(name string) []string {
	commonVars := map[string][]string{
		"github.com/gin-gonic/gin": {
			"router", "engine", "port", "host", "middleware",
		},
		"github.com/gorilla/mux": {
			"router", "handler", "path", "method", "vars",
		},
		"github.com/labstack/echo": {
			"echo", "context", "handler", "middleware", "port",
		},
		"gorm.io/gorm": {
			"db", "connection", "model", "query", "transaction",
		},
		"github.com/redis/go-redis": {
			"client", "key", "value", "expiration", "pipeline",
		},
		"go.uber.org/zap": {
			"logger", "level", "field", "message", "config",
		},
	}

	if vars, exists := commonVars[name]; exists {
		return vars
	}
	return []string{}
}

// analyzeNodeDependencies analyzes Node.js dependencies (placeholder)
func (ca *ContextAnalyzer) analyzeNodeDependencies(packageJsonPath string, dependencies *[]interfaces.DependencyInfo) error {
	// Implementation would parse package.json
	return nil
}

// analyzePythonDependencies analyzes Python dependencies (placeholder)
func (ca *ContextAnalyzer) analyzePythonDependencies(requirementsPath string, dependencies *[]interfaces.DependencyInfo) error {
	// Implementation would parse requirements.txt
	return nil
}

// analyzeConventions analyzes coding conventions
func (ca *ContextAnalyzer) analyzeConventions(projectPath string, conventionInfo *interfaces.ConventionInfo) error {
	conventionInfo.Language = "go" // Default assumption
	conventionInfo.Style = "standard"
	conventionInfo.Rules = make(map[string]interface{})
	conventionInfo.Enforced = false
	conventionInfo.ToolsUsed = []string{}
	conventionInfo.CustomRules = []interfaces.ConventionRule{}

	// Check for linting configuration files
	if ca.hasLintConfig(projectPath) {
		conventionInfo.Enforced = true
		conventionInfo.ToolsUsed = ca.detectLintingTools(projectPath)
	}

	// Detect style guide
	conventionInfo.Style = ca.detectStyleGuide(projectPath)

	// Set common Go rules
	conventionInfo.Rules["naming"] = "camelCase for unexported, PascalCase for exported"
	conventionInfo.Rules["error_handling"] = "explicit error handling required"
	conventionInfo.Rules["imports"] = "standard library first, then third-party, then local"

	return nil
}

// hasLintConfig checks for linting configuration files
func (ca *ContextAnalyzer) hasLintConfig(projectPath string) bool {
	configFiles := []string{
		".golangci.yml",
		".golangci.yaml",
		"golangci.yml",
		".golint.json",
		".revive.toml",
	}

	for _, configFile := range configFiles {
		if _, err := os.Stat(filepath.Join(projectPath, configFile)); err == nil {
			return true
		}
	}

	return false
}

// detectLintingTools detects linting tools being used
func (ca *ContextAnalyzer) detectLintingTools(projectPath string) []string {
	tools := []string{}

	if _, err := os.Stat(filepath.Join(projectPath, ".golangci.yml")); err == nil {
		tools = append(tools, "golangci-lint")
	}
	if _, err := os.Stat(filepath.Join(projectPath, ".revive.toml")); err == nil {
		tools = append(tools, "revive")
	}

	// Check go.mod for staticcheck
	if ca.containsInFile(filepath.Join(projectPath, "go.mod"), "staticcheck") {
		tools = append(tools, "staticcheck")
	}

	return tools
}

// detectStyleGuide detects the style guide being used
func (ca *ContextAnalyzer) detectStyleGuide(projectPath string) string {
	// Check for specific style guide indicators
	if ca.containsInFile(filepath.Join(projectPath, "README.md"), "Google Go Style") {
		return "google"
	}
	if ca.containsInFile(filepath.Join(projectPath, "README.md"), "Uber Go Style") {
		return "uber"
	}

	// Default to effective Go
	return "effective_go"
}

// analyzeEnvironment analyzes the development environment
func (ca *ContextAnalyzer) analyzeEnvironment(envInfo *interfaces.EnvironmentInfo) error {
	// Detect IDE (simplified - would need more sophisticated detection)
	envInfo.IDE = ca.detectIDE()

	// Get Go version
	envInfo.GoVersion = ca.getGoVersion()

	// Detect OS
	envInfo.OperatingSystem = ca.detectOS()

	// Detect available tools
	envInfo.ToolsAvailable = ca.detectAvailableTools()

	// Initialize other fields
	envInfo.Extensions = []string{} // Would need IDE-specific detection
	envInfo.Configuration = make(map[string]string)

	return nil
}

// detectIDE detects the IDE being used (simplified)
func (ca *ContextAnalyzer) detectIDE() string {
	// Check for IDE-specific files/directories
	if _, err := os.Stat(".vscode"); err == nil {
		return "vscode"
	}
	if _, err := os.Stat(".idea"); err == nil {
		return "intellij"
	}

	return "unknown"
}

// getGoVersion gets the Go version (simplified)
func (ca *ContextAnalyzer) getGoVersion() string {
	// This would typically run `go version` command
	return "1.21" // Placeholder
}

// detectOS detects the operating system (simplified)
func (ca *ContextAnalyzer) detectOS() string {
	// This would use runtime.GOOS or similar
	return "unknown" // Placeholder
}

// detectAvailableTools detects available development tools
func (ca *ContextAnalyzer) detectAvailableTools() []string {
	tools := []string{}

	// This would check if tools are available in PATH
	commonTools := []string{"git", "docker", "make", "golangci-lint", "gofmt", "goimports"}

	for _, tool := range commonTools {
		// Simplified check - would use exec.LookPath in real implementation
		tools = append(tools, tool)
	}

	return tools
}

// loadHistoricalData loads historical usage data (placeholder)
func (ca *ContextAnalyzer) loadHistoricalData(historicalData *interfaces.HistoricalData) {
	// Initialize empty historical data
	historicalData.VariableUsage = make(map[string]interfaces.VariableUsageHistory)
	historicalData.PatternEvolution = []interfaces.PatternEvolution{}
	historicalData.SuccessRates = make(map[string]float64)
	historicalData.UserPreferences = interfaces.UserPreferences{
		PreferredNaming:     "camelCase",
		PreferredTypes:      []string{"string", "int", "bool"},
		AvoidedPatterns:     []string{},
		CustomConventions:   []string{},
		LearningEnabled:     true,
		SuggestionLevel:     "moderate",
		PersonalizationData: make(map[string]interface{}),
	}
	historicalData.ProjectHistory = []interfaces.ProjectSnapshot{}

	// In a real implementation, this would load from storage
	// For now, we'll populate with some sample data
	ca.populateSampleHistoricalData(historicalData)
}

// populateSampleHistoricalData populates sample historical data
func (ca *ContextAnalyzer) populateSampleHistoricalData(historicalData *interfaces.HistoricalData) {
	// Sample variable usage history
	historicalData.VariableUsage["config"] = interfaces.VariableUsageHistory{
		Name:        "config",
		Type:        "Config",
		UsageCount:  25,
		SuccessRate: 0.95,
		Contexts:    []interfaces.UsageContext{},
		Trends:      []interfaces.UsageTrend{},
		LastUsed:    time.Now().Add(-24 * time.Hour),
	}

	historicalData.VariableUsage["logger"] = interfaces.VariableUsageHistory{
		Name:        "logger",
		Type:        "*zap.Logger",
		UsageCount:  40,
		SuccessRate: 0.98,
		Contexts:    []interfaces.UsageContext{},
		Trends:      []interfaces.UsageTrend{},
		LastUsed:    time.Now().Add(-2 * time.Hour),
	}

	// Sample success rates
	historicalData.SuccessRates["api_handler"] = 0.92
	historicalData.SuccessRates["database_model"] = 0.88
	historicalData.SuccessRates["service_layer"] = 0.95
}

// calculateAnalysisConfidence calculates the confidence score for the analysis
func (ca *ContextAnalyzer) calculateAnalysisConfidence(analysis *interfaces.ContextAnalysis) float64 {
	confidence := 0.0
	factors := 0

	// Project info confidence
	if analysis.ProjectInfo.Language != "unknown" {
		confidence += 0.2
	}
	if analysis.ProjectInfo.Framework != "unknown" {
		confidence += 0.1
	}
	factors++

	// Code patterns confidence
	if len(analysis.CodePatterns.NamingConventions) > 0 {
		confidence += 0.2
	}
	if len(analysis.CodePatterns.CommonStructures) > 0 {
		confidence += 0.1
	}
	factors++

	// Dependencies confidence
	if len(analysis.Dependencies) > 0 {
		confidence += 0.15
	}
	factors++

	// Conventions confidence
	if analysis.ConventionInfo.Enforced {
		confidence += 0.1
	}
	factors++

	// Environment confidence
	if analysis.EnvironmentInfo.GoVersion != "" {
		confidence += 0.1
	}
	factors++

	// Historical data confidence
	if len(analysis.HistoricalData.VariableUsage) > 0 {
		confidence += 0.15
	}
	factors++

	if factors > 0 {
		return confidence
	}

	return 0.5 // Base confidence
}

// Helper methods

// typeToString converts an AST type to string representation
func (ca *ContextAnalyzer) typeToString(expr ast.Expr) string {
	switch t := expr.(type) {
	case *ast.Ident:
		return t.Name
	case *ast.StarExpr:
		return "*" + ca.typeToString(t.X)
	case *ast.ArrayType:
		return "[]" + ca.typeToString(t.Elt)
	case *ast.MapType:
		return "map[" + ca.typeToString(t.Key) + "]" + ca.typeToString(t.Value)
	case *ast.InterfaceType:
		return "interface{}"
	case *ast.SelectorExpr:
		return ca.typeToString(t.X) + "." + t.Sel.Name
	case *ast.FuncType:
		return "func"
	default:
		return "unknown"
	}
}

// extractValue extracts a simple value from an expression (for initial values)
func (ca *ContextAnalyzer) extractValue(expr ast.Expr) interface{} {
	switch e := expr.(type) {
	case *ast.BasicLit:
		switch e.Kind {
		case token.STRING:
			return e.Value[1 : len(e.Value)-1] // Remove quotes
		case token.INT:
			return e.Value
		case token.FLOAT:
			return e.Value
		}
	case *ast.Ident:
		if e.Name == "true" {
			return true
		}
		if e.Name == "false" {
			return false
		}
		if e.Name == "nil" {
			return nil
		}
		return e.Name
	}
	return "complex_expression"
}

// hasFiles checks if directory contains files with given extension
func (ca *ContextAnalyzer) hasFiles(dir, ext string) bool {
	found := false
	filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil
		}
		if !info.IsDir() && strings.HasSuffix(path, ext) {
			found = true
			return filepath.SkipDir
		}
		return nil
	})
	return found
}

// hasDirectory checks if a directory exists
func (ca *ContextAnalyzer) hasDirectory(basePath, dirName string) bool {
	dirPath := filepath.Join(basePath, dirName)
	if info, err := os.Stat(dirPath); err == nil && info.IsDir() {
		return true
	}
	return false
}

// containsInFile checks if a file contains a specific string
func (ca *ContextAnalyzer) containsInFile(filePath, searchStr string) bool {
	content, err := os.ReadFile(filePath)
	if err != nil {
		return false
	}
	return strings.Contains(string(content), searchStr)
}
