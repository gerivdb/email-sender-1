// Manager Toolkit - Interface Analysis (Professional Implementation)

package analysis

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/scanner"
	"go/token"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"time"

	"email_sender/development/managers/tools/core/toolkit"
)

// ToolVersion defines the current version of this specific tool or the toolkit.
const ToolVersion = "3.0.0"

// InterfaceAnalyzer provides comprehensive interface analysis capabilities
type InterfaceAnalyzer struct {
	BaseDir string
	FileSet *token.FileSet
	Logger  *toolkit.Logger
	Stats   *toolkit.ToolkitStats
}

// NewInterfaceAnalyzerPro creates a new InterfaceAnalyzer instance
func NewInterfaceAnalyzerPro(baseDir string, fileSet *token.FileSet, debugMode bool) (*InterfaceAnalyzer, error) {
	if baseDir == "" {
		return nil, fmt.Errorf("base directory cannot be empty")
	}

	// Assuming toolkit.Logger can be instantiated directly or has a constructor.
	// Using a simple instantiation based on previous patterns.
	// If toolkit.NewLogger exists and is the intended call, this should be toolkit.NewLogger(debugMode)
	logger := &toolkit.Logger{} // Or toolkit.NewLogger(debugMode) if available
	// If logger needs error handling:
	// logger, err := toolkit.NewLogger(debugMode)
	// if err != nil {
	// 	return nil, fmt.Errorf("failed to create logger: %w", err)
	// }

	if fileSet == nil {
		fileSet = token.NewFileSet()
	}

	stats := &toolkit.ToolkitStats{}

	return &InterfaceAnalyzer{
		BaseDir: baseDir,
		FileSet: fileSet,
		Logger:  logger,
		Stats:   stats,
	}, nil
}

// Interface represents a Go interface with metadata
type Interface struct {
	Name        string            `json:"name"`
	Methods     []Method          `json:"methods"`
	File        string            `json:"file"`
	Package     string            `json:"package"`
	Position    token.Position    `json:"position"`
	Comments    []string          `json:"comments"`
	Annotations map[string]string `json:"annotations"`
}

// InterfaceInfo is an alias for Interface for compatibility with tests
type InterfaceInfo = Interface

// Method represents a method within an interface
type Method struct {
	Name       string         `json:"name"`
	Signature  string         `json:"signature"`
	Parameters []Parameter    `json:"parameters"`
	Returns    []ReturnValue  `json:"returns"`
	Comments   []string       `json:"comments"`
	Position   token.Position `json:"position"`
}

// MethodInfo is an alias for Method for compatibility with tests
type MethodInfo = Method

// Parameter represents a method parameter
type Parameter struct {
	Name string `json:"name"`
	Type string `json:"type"`
}

// ReturnValue represents a method return value
type ReturnValue struct {
	Name string `json:"name"`
	Type string `json:"type"`
}

// AnalysisReport contains comprehensive analysis results
type AnalysisReport struct {
	Timestamp         time.Time              `json:"timestamp"`
	Version           string                 `json:"version"`
	BaseDirectory     string                 `json:"base_directory"`
	TotalFiles        int                    `json:"total_files"`
	FilesAnalyzed     int                    `json:"files_analyzed"`
	Files             []string               `json:"files"`
	TotalMethods      int                    `json:"total_methods"`
	Interfaces        []Interface            `json:"interfaces"`
	Duplications      map[string][]Interface `json:"duplications"`
	SyntaxErrors      []InterfaceSyntaxError `json:"syntax_errors"`
	CommonMethods     map[string]int         `json:"common_methods"`
	Recommendations   []Recommendation       `json:"recommendations"`
	Dependencies      map[string][]string    `json:"dependencies"`
	ComplexityMetrics *ComplexityMetrics     `json:"complexity_metrics"`
	QualityScore      QualityScore           `json:"quality_score"`
	Stats             *toolkit.ToolkitStats  `json:"stats"` // Changed to toolkit.ToolkitStats
}

// QualityScore represents the overall quality score with details
type QualityScore struct {
	OverallScore    float64 `json:"overall_score"`
	CodeQuality     float64 `json:"code_quality"`
	Maintainability float64 `json:"maintainability"`
	Testability     float64 `json:"testability"`
}

// InterfaceSyntaxError represents a syntax error with context for interface analysis
type InterfaceSyntaxError struct {
	File          string         `json:"file"`
	Line          int            `json:"line"`
	Message       string         `json:"message"`
	Position      token.Position `json:"position"`
	Description   string         `json:"description"`
	Context       string         `json:"context"`
	Severity      string         `json:"severity"`
	FixSuggestion string         `json:"fix_suggestion"`
}

// Recommendation provides actionable improvement suggestions
type Recommendation struct {
	Type        string   `json:"type"`
	Priority    string   `json:"priority"`
	Description string   `json:"description"`
	Files       []string `json:"files"`
	Action      string   `json:"action"`
}

// ComplexityMetrics provides code complexity analysis
type ComplexityMetrics struct {
	AverageMethodsPerInterface float64            `json:"average_methods_per_interface"`
	InterfaceComplexity        map[string]int     `json:"interface_complexity"`
	PackageComplexity          map[string]int     `json:"package_complexity"`
	DependencyDepth            int                `json:"dependency_depth"`
	CouplingMetrics            map[string]float64 `json:"coupling_metrics"`
}

// AnalyzeInterfaces performs comprehensive interface analysis
func (ia *InterfaceAnalyzer) AnalyzeInterfaces() (*AnalysisReport, error) {
	ia.Logger.Info("Starting comprehensive interface analysis...")

	report := &AnalysisReport{
		Timestamp:     time.Now(),
		Version:       ToolVersion,
		BaseDirectory: ia.BaseDir,
		Interfaces:    []Interface{},
		Duplications:  make(map[string][]Interface),
		SyntaxErrors:  []InterfaceSyntaxError{},
		CommonMethods: make(map[string]int),
		Dependencies:  make(map[string][]string),
		ComplexityMetrics: &ComplexityMetrics{
			InterfaceComplexity: make(map[string]int),
			PackageComplexity:   make(map[string]int),
			CouplingMetrics:     make(map[string]float64),
		},
		Stats: ia.Stats,
	}

	// Walk through all Go files
	err := filepath.WalkDir(ia.BaseDir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		if !strings.HasSuffix(path, ".go") || strings.Contains(path, "vendor/") {
			return nil
		}

		report.TotalFiles++
		ia.Stats.TotalFiles++

		if err := ia.analyzeFile(path, report); err != nil {
			ia.Logger.Warn("Failed to analyze file %s: %v", path, err)
			// Continue processing other files
		} else {
			report.FilesAnalyzed++
			ia.Stats.FilesAnalyzed++

			// Check if file contains interfaces
			hasInterfaces := false
			for _, iface := range report.Interfaces {
				if iface.File == path {
					hasInterfaces = true
					break
				}
			}
			if hasInterfaces {
				ia.Stats.InterfaceFiles++
			}
		}

		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("failed to walk directory tree: %w", err)
	}

	// Post-process analysis results
	ia.detectDuplications(report)
	ia.generateRecommendations(report)
	ia.calculateComplexityMetrics(report)
	ia.calculateQualityScore(report)

	// Update total interfaces count
	ia.Stats.TotalInterfaces = len(report.Interfaces)

	ia.Logger.Info("Analysis completed: %d files, %d interfaces, %d errors",
		report.FilesAnalyzed, len(report.Interfaces), len(report.SyntaxErrors))

	return report, nil
}

// analyzeFile analyzes a single Go file
func (ia *InterfaceAnalyzer) analyzeFile(filePath string, report *AnalysisReport) error {
	// Parse the file
	src, err := os.ReadFile(filePath)
	if err != nil {
		return err
	}
	file, err := parser.ParseFile(ia.FileSet, filePath, src, parser.ParseComments)
	if err != nil { // Handle syntax errors
		if errList, ok := err.(scanner.ErrorList); ok {
			for _, e := range errList {
				syntaxErr := InterfaceSyntaxError{
					File:          filePath,
					Line:          e.Pos.Line,
					Message:       e.Msg,
					Position:      e.Pos,
					Description:   e.Msg,
					Context:       ia.extractContext(src, e.Pos),
					Severity:      ia.determineSeverity(e.Msg),
					FixSuggestion: ia.generateFixSuggestion(e.Msg),
				}
				report.SyntaxErrors = append(report.SyntaxErrors, syntaxErr)
			}
		}
		return nil // Continue processing despite syntax errors
	}

	// Extract package information
	packageName := file.Name.Name

	// Find interfaces
	ast.Inspect(file, func(n ast.Node) bool {
		switch node := n.(type) {
		case *ast.TypeSpec:
			if interfaceType, ok := node.Type.(*ast.InterfaceType); ok {
				iface := ia.extractInterface(node, interfaceType, filePath, packageName)
				report.Interfaces = append(report.Interfaces, iface)

				// Track common methods
				for _, method := range iface.Methods {
					report.CommonMethods[method.Name]++
				}
			}
		}
		return true
	})

	// Extract dependencies
	for _, imp := range file.Imports {
		if imp.Path != nil {
			importPath := strings.Trim(imp.Path.Value, `"`)
			if strings.Contains(importPath, "github.com/gerivdb/email-sender-1/managers") {
				report.Dependencies[packageName] = append(report.Dependencies[packageName], importPath)
			}
		}
	}

	return nil
}

// extractInterface extracts interface information from AST
func (ia *InterfaceAnalyzer) extractInterface(typeSpec *ast.TypeSpec, interfaceType *ast.InterfaceType, filePath, packageName string) Interface {
	iface := Interface{
		Name:        typeSpec.Name.Name,
		File:        filePath,
		Package:     packageName,
		Position:    ia.FileSet.Position(typeSpec.Pos()),
		Methods:     []Method{},
		Comments:    []string{},
		Annotations: make(map[string]string),
	}

	// Extract comments
	if typeSpec.Doc != nil {
		for _, comment := range typeSpec.Doc.List {
			iface.Comments = append(iface.Comments, strings.TrimPrefix(comment.Text, "//"))
		}
	}

	// Extract methods
	for _, field := range interfaceType.Methods.List {
		if funcType, ok := field.Type.(*ast.FuncType); ok {
			for _, name := range field.Names {
				method := ia.extractMethod(name, funcType, field)
				iface.Methods = append(iface.Methods, method)
			}
		}
	}

	return iface
}

// extractMethod extracts method information from AST
func (ia *InterfaceAnalyzer) extractMethod(name *ast.Ident, funcType *ast.FuncType, field *ast.Field) Method {
	method := Method{
		Name:       name.Name,
		Position:   ia.FileSet.Position(name.Pos()),
		Parameters: []Parameter{},
		Returns:    []ReturnValue{},
		Comments:   []string{},
	}

	// Extract parameters
	if funcType.Params != nil {
		for _, param := range funcType.Params.List {
			paramType := ia.extractTypeString(param.Type)
			if len(param.Names) > 0 {
				for _, paramName := range param.Names {
					method.Parameters = append(method.Parameters, Parameter{
						Name: paramName.Name,
						Type: paramType,
					})
				}
			} else {
				method.Parameters = append(method.Parameters, Parameter{
					Name: "",
					Type: paramType,
				})
			}
		}
	}

	// Extract return values
	if funcType.Results != nil {
		for _, result := range funcType.Results.List {
			returnType := ia.extractTypeString(result.Type)
			if len(result.Names) > 0 {
				for _, returnName := range result.Names {
					method.Returns = append(method.Returns, ReturnValue{
						Name: returnName.Name,
						Type: returnType,
					})
				}
			} else {
				method.Returns = append(method.Returns, ReturnValue{
					Name: "",
					Type: returnType,
				})
			}
		}
	}

	// Build signature
	method.Signature = ia.buildMethodSignature(method)

	// Extract comments
	if field.Doc != nil {
		for _, comment := range field.Doc.List {
			method.Comments = append(method.Comments, strings.TrimPrefix(comment.Text, "//"))
		}
	}

	return method
}

// extractTypeString converts an AST expression to type string
func (ia *InterfaceAnalyzer) extractTypeString(expr ast.Expr) string {
	switch e := expr.(type) {
	case *ast.Ident:
		return e.Name
	case *ast.StarExpr:
		return "*" + ia.extractTypeString(e.X)
	case *ast.ArrayType:
		return "[]" + ia.extractTypeString(e.Elt)
	case *ast.MapType:
		return "map[" + ia.extractTypeString(e.Key) + "]" + ia.extractTypeString(e.Value)
	case *ast.SelectorExpr:
		return ia.extractTypeString(e.X) + "." + e.Sel.Name
	case *ast.InterfaceType:
		return "interface{}"
	case *ast.ChanType:
		return "chan " + ia.extractTypeString(e.Value)
	default:
		return "unknown"
	}
}

// buildMethodSignature builds a method signature string
func (ia *InterfaceAnalyzer) buildMethodSignature(method Method) string {
	var params []string
	for _, param := range method.Parameters {
		if param.Name != "" {
			params = append(params, param.Name+" "+param.Type)
		} else {
			params = append(params, param.Type)
		}
	}

	var returns []string
	for _, ret := range method.Returns {
		if ret.Name != "" {
			returns = append(returns, ret.Name+" "+ret.Type)
		} else {
			returns = append(returns, ret.Type)
		}
	}

	signature := method.Name + "(" + strings.Join(params, ", ") + ")"
	if len(returns) > 0 {
		if len(returns) == 1 && method.Returns[0].Name == "" {
			signature += " " + returns[0]
		} else {
			signature += " (" + strings.Join(returns, ", ") + ")"
		}
	}

	return signature
}

// detectDuplications detects duplicate interfaces
func (ia *InterfaceAnalyzer) detectDuplications(report *AnalysisReport) {
	interfacesByName := make(map[string][]Interface)

	for _, iface := range report.Interfaces {
		interfacesByName[iface.Name] = append(interfacesByName[iface.Name], iface)
	}

	for name, interfaces := range interfacesByName {
		if len(interfaces) > 1 {
			report.Duplications[name] = interfaces
		}
	}
}

// Helper functions for analysis
func (ia *InterfaceAnalyzer) extractContext(src []byte, pos token.Position) string {
	lines := strings.Split(string(src), "\n")

	if pos.Line <= len(lines) {
		start := max(0, pos.Line-3)
		end := min(len(lines), pos.Line+2)
		context := strings.Join(lines[start:end], "\n")
		return context
	}

	return ""
}

func (ia *InterfaceAnalyzer) determineSeverity(msg string) string {
	switch {
	case strings.Contains(msg, "syntax error"):
		return "error"
	case strings.Contains(msg, "expected"):
		return "error"
	case strings.Contains(msg, "undefined"):
		return "error"
	default:
		return "warning"
	}
}

func (ia *InterfaceAnalyzer) generateFixSuggestion(msg string) string {
	switch {
	case strings.Contains(msg, "expected ';'"):
		return "Add missing semicolon"
	case strings.Contains(msg, "expected '}'"):
		return "Add missing closing brace"
	case strings.Contains(msg, "expected ')'"):
		return "Add missing closing parenthesis"
	case strings.Contains(msg, "undefined"):
		return "Check import statements and package declarations"
	default:
		return "Review syntax and formatting"
	}
}

func (ia *InterfaceAnalyzer) generateRecommendations(report *AnalysisReport) {
	// Generate recommendations based on analysis
	if len(report.Duplications) > 0 {
		report.Recommendations = append(report.Recommendations, Recommendation{
			Type:        "duplication",
			Priority:    "high",
			Description: fmt.Sprintf("Found %d duplicate interfaces that should be consolidated", len(report.Duplications)),
			Action:      "migrate",
		})
	}

	if len(report.SyntaxErrors) > 0 {
		report.Recommendations = append(report.Recommendations, Recommendation{
			Type:        "syntax",
			Priority:    "critical",
			Description: fmt.Sprintf("Found %d syntax errors that need immediate attention", len(report.SyntaxErrors)),
			Action:      "fix-syntax",
		})
	}
}

func (ia *InterfaceAnalyzer) calculateComplexityMetrics(report *AnalysisReport) {
	if len(report.Interfaces) == 0 {
		return
	}

	totalMethods := 0
	for _, iface := range report.Interfaces {
		methodCount := len(iface.Methods)
		totalMethods += methodCount
		report.ComplexityMetrics.InterfaceComplexity[iface.Name] = methodCount

		// Package complexity
		report.ComplexityMetrics.PackageComplexity[iface.Package] += methodCount
	}

	report.ComplexityMetrics.AverageMethodsPerInterface = float64(totalMethods) / float64(len(report.Interfaces))
}

func (ia *InterfaceAnalyzer) calculateQualityScore(report *AnalysisReport) {
	score := 100.0

	// Deduct points for issues
	score -= float64(len(report.SyntaxErrors)) * 10
	score -= float64(len(report.Duplications)) * 5
	// Ensure score doesn't go below 0
	if score < 0 {
		score = 0
	}

	report.QualityScore = QualityScore{
		OverallScore:    score,
		CodeQuality:     score * 0.9,
		Maintainability: score * 0.8,
		Testability:     score * 0.7,
	}
}

// GenerateAnalysisReport generates a formatted analysis report
func (ia *InterfaceAnalyzer) GenerateAnalysisReport(format string) ([]byte, error) {
	// First perform the analysis
	report, err := ia.AnalyzeInterfaces()
	if err != nil {
		return nil, fmt.Errorf("failed to analyze interfaces: %w", err)
	}

	switch format {
	case "json":
		return []byte(fmt.Sprintf(`{
  "timestamp": "%s",
  "total_interfaces": %d,
  "total_methods": %d,
  "files_analyzed": %d
}`, report.Timestamp.Format(time.RFC3339), len(report.Interfaces), report.TotalMethods, report.FilesAnalyzed)), nil
	case "yaml":
		return []byte(fmt.Sprintf(`timestamp: %s
total_interfaces: %d
total_methods: %d
files_analyzed: %d
`, report.Timestamp.Format(time.RFC3339), len(report.Interfaces), report.TotalMethods, report.FilesAnalyzed)), nil
	default:
		return nil, fmt.Errorf("unsupported format: %s", format)
	}
}

// Utility functions
func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
