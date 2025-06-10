package ai

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"math"
	"strings"

	"github.com/chrlesur/Email_Sender/development/managers/ai-template-manager/interfaces"
)

// PatternProcessor implements neural pattern recognition for code analysis
type PatternProcessor struct {
	fset *token.FileSet
}

// NewPatternProcessor creates a new pattern processor instance
func NewPatternProcessor() *PatternProcessor {
	return &PatternProcessor{
		fset: token.NewFileSet(),
	}
}

// AnalyzeCodePatterns analyzes Go code patterns in a project
func (pp *PatternProcessor) AnalyzeCodePatterns(projectPath string) (*interfaces.PatternAnalysis, error) {
	files, err := parser.ParseDir(pp.fset, projectPath, nil, parser.ParseComments)
	if err != nil {
		return nil, fmt.Errorf("parsing error: %w", err)
	}

	patterns := &interfaces.PatternAnalysis{
		Functions:       []interfaces.FunctionInfo{},
		Structs:         []interfaces.StructInfo{},
		Variables:       []interfaces.VariablePattern{},
		Patterns:        []interfaces.CodePattern{},
		Complexity:      interfaces.ComplexityMetrics{},
		Recommendations: []interfaces.Recommendation{},
	}

	for _, pkg := range files {
		for _, file := range pkg.Files {
			pp.analyzeFile(file, patterns)
		}
	}

	pp.calculateComplexityMetrics(patterns)
	pp.generateRecommendations(patterns)

	return patterns, nil
}

// analyzeFile processes a single Go file for pattern analysis
func (pp *PatternProcessor) analyzeFile(file *ast.File, patterns *interfaces.PatternAnalysis) {
	ast.Inspect(file, func(n ast.Node) bool {
		switch x := n.(type) {
		case *ast.FuncDecl:
			if x.Name != nil {
				funcInfo := pp.extractFunctionInfo(x)
				patterns.Functions = append(patterns.Functions, funcInfo)
			}
		case *ast.GenDecl:
			if x.Tok == token.TYPE {
				for _, spec := range x.Specs {
					if typeSpec, ok := spec.(*ast.TypeSpec); ok {
						if structType, ok := typeSpec.Type.(*ast.StructType); ok {
							structInfo := pp.extractStructInfo(typeSpec.Name.Name, structType)
							patterns.Structs = append(patterns.Structs, structInfo)
						}
					}
				}
			}
		case *ast.AssignStmt:
			pp.analyzeVariableAssignment(x, patterns)
		}
		return true
	})
}

// extractFunctionInfo extracts detailed information about a function
func (pp *PatternProcessor) extractFunctionInfo(funcDecl *ast.FuncDecl) interfaces.FunctionInfo {
	info := interfaces.FunctionInfo{
		Name:        funcDecl.Name.Name,
		Parameters:  []interfaces.ParameterInfo{},
		ReturnType:  "void",
		Complexity:  pp.calculateCyclomaticComplexity(funcDecl),
		UsageCount:  0, // This would be calculated through cross-referencing
		Metadata:    make(map[string]string),
	}

	// Extract parameters
	if funcDecl.Type.Params != nil {
		for _, param := range funcDecl.Type.Params.List {
			for _, name := range param.Names {
				paramInfo := interfaces.ParameterInfo{
					Name:     name.Name,
					Type:     pp.typeToString(param.Type),
					Optional: false,
				}
				info.Parameters = append(info.Parameters, paramInfo)
			}
		}
	}

	// Extract return type
	if funcDecl.Type.Results != nil && len(funcDecl.Type.Results.List) > 0 {
		returnTypes := []string{}
		for _, result := range funcDecl.Type.Results.List {
			returnTypes = append(returnTypes, pp.typeToString(result.Type))
		}
		info.ReturnType = strings.Join(returnTypes, ", ")
	}

	return info
}

// extractStructInfo extracts information about a struct
func (pp *PatternProcessor) extractStructInfo(name string, structType *ast.StructType) interfaces.StructInfo {
	info := interfaces.StructInfo{
		Name:     name,
		Fields:   []interfaces.FieldInfo{},
		Methods:  []string{},
		Tags:     []string{},
		Metadata: make(map[string]string),
	}

	// Extract fields
	for _, field := range structType.Fields.List {
		for _, fieldName := range field.Names {
			fieldInfo := interfaces.FieldInfo{
				Name: fieldName.Name,
				Type: pp.typeToString(field.Type),
			}
			if field.Tag != nil {
				fieldInfo.Tag = field.Tag.Value
			}
			info.Fields = append(info.Fields, fieldInfo)
		}
	}

	return info
}

// analyzeVariableAssignment analyzes variable assignment patterns
func (pp *PatternProcessor) analyzeVariableAssignment(assign *ast.AssignStmt, patterns *interfaces.PatternAnalysis) {
	for i, lhs := range assign.Lhs {
		if ident, ok := lhs.(*ast.Ident); ok {
			varType := "interface{}"
			if i < len(assign.Rhs) {
				varType = pp.inferVariableType(assign.Rhs[i])
			}

			varPattern := interfaces.VariablePattern{
				Name:         ident.Name,
				Type:         varType,
				Scope:        "local", // This could be enhanced with scope analysis
				UsagePattern: "assignment",
				Frequency:    1, // This would be calculated through analysis
			}
			patterns.Variables = append(patterns.Variables, varPattern)
		}
	}
}

// InferVariableType infers the type of a variable from its expression
func (pp *PatternProcessor) inferVariableType(expr ast.Expr) string {
	switch t := expr.(type) {
	case *ast.BasicLit:
		return t.Kind.String()
	case *ast.Ident:
		return t.Name
	case *ast.CallExpr:
		if ident, ok := t.Fun.(*ast.Ident); ok {
			return ident.Name + "()"
		}
		return "function_call"
	case *ast.CompositeLit:
		if t.Type != nil {
			return pp.typeToString(t.Type)
		}
		return "composite"
	default:
		return "interface{}"
	}
}

// typeToString converts an AST type to string representation
func (pp *PatternProcessor) typeToString(expr ast.Expr) string {
	switch t := expr.(type) {
	case *ast.Ident:
		return t.Name
	case *ast.StarExpr:
		return "*" + pp.typeToString(t.X)
	case *ast.ArrayType:
		return "[]" + pp.typeToString(t.Elt)
	case *ast.MapType:
		return "map[" + pp.typeToString(t.Key) + "]" + pp.typeToString(t.Value)
	case *ast.InterfaceType:
		return "interface{}"
	case *ast.SelectorExpr:
		return pp.typeToString(t.X) + "." + t.Sel.Name
	default:
		return "unknown"
	}
}

// calculateCyclomaticComplexity calculates the cyclomatic complexity of a function
func (pp *PatternProcessor) calculateCyclomaticComplexity(funcDecl *ast.FuncDecl) int {
	complexity := 1 // Base complexity

	if funcDecl.Body != nil {
		ast.Inspect(funcDecl.Body, func(n ast.Node) bool {
			switch n.(type) {
			case *ast.IfStmt, *ast.RangeStmt, *ast.ForStmt, *ast.TypeSwitchStmt, *ast.SwitchStmt:
				complexity++
			case *ast.CaseClause:
				complexity++
			}
			return true
		})
	}

	return complexity
}

// calculateTechnicalDebt estimates technical debt based on complexity
func (pp *PatternProcessor) calculateTechnicalDebt(complexity, loc int) float64 {
	if loc == 0 {
		return 0
	}
	// Technical debt increases exponentially with complexity
	complexityRatio := float64(complexity) / float64(loc)
	return math.Min(complexityRatio*10, 100.0) // Cap at 100%
}

// calculateMaintainability calculates maintainability index
func (pp *PatternProcessor) calculateMaintainability(complexity, loc int) float64 {
	if loc == 0 {
		return 100.0
	}
	// Simplified maintainability index calculation
	complexityPenalty := float64(complexity) / float64(loc) * 50
	maintainability := 100.0 - complexityPenalty
	return math.Max(maintainability, 0.0)
}

// calculateComplexityMetrics calculates overall complexity metrics
func (pp *PatternProcessor) calculateComplexityMetrics(patterns *interfaces.PatternAnalysis) {
	totalComplexity := 0
	maxComplexity := 0
	totalLOC := 0

	for _, function := range patterns.Functions {
		totalComplexity += function.Complexity
		if function.Complexity > maxComplexity {
			maxComplexity = function.Complexity
		}
		// LOC estimation - would need actual implementation
		totalLOC += 10 // Placeholder
	}

	patterns.Complexity = interfaces.ComplexityMetrics{
		CyclomaticComplexity: totalComplexity,
		CognitiveComplexity:  int(float64(totalComplexity) * 1.2), // Estimated
		LinesOfCode:          totalLOC,
		TechnicalDebt:        pp.calculateTechnicalDebt(totalComplexity, totalLOC),
		Maintainability:      pp.calculateMaintainability(totalComplexity, totalLOC),
	}
}

// generateRecommendations generates AI-powered recommendations
func (pp *PatternProcessor) generateRecommendations(patterns *interfaces.PatternAnalysis) {
	recommendations := []interfaces.Recommendation{}

	// High complexity functions
	for _, function := range patterns.Functions {
		if function.Complexity > 10 {
			recommendations = append(recommendations, interfaces.Recommendation{
				Type:        "complexity",
				Priority:    1,
				Description: fmt.Sprintf("Function '%s' has high cyclomatic complexity (%d)", function.Name, function.Complexity),
				Action:      "Consider breaking down this function into smaller, more focused functions",
				Impact:      "Improved maintainability and testability",
				References:  []string{"Clean Code", "Refactoring: Improving the Design of Existing Code"},
			})
		}
	}

	// Large structs
	for _, structInfo := range patterns.Structs {
		if len(structInfo.Fields) > 15 {
			recommendations = append(recommendations, interfaces.Recommendation{
				Type:        "design",
				Priority:    2,
				Description: fmt.Sprintf("Struct '%s' has many fields (%d)", structInfo.Name, len(structInfo.Fields)),
				Action:      "Consider decomposing into smaller, cohesive structs",
				Impact:      "Better encapsulation and easier maintenance",
				References:  []string{"Domain-Driven Design", "Clean Architecture"},
			})
		}
	}

	// Technical debt warning
	if patterns.Complexity.TechnicalDebt > 50 {
		recommendations = append(recommendations, interfaces.Recommendation{
			Type:        "technical_debt",
			Priority:    1,
			Description: fmt.Sprintf("High technical debt detected (%.1f%%)", patterns.Complexity.TechnicalDebt),
			Action:      "Schedule refactoring sessions to reduce complexity",
			Impact:      "Reduced maintenance costs and improved development velocity",
			References:  []string{"Technical Debt Management", "Refactoring Techniques"},
		})
	}

	patterns.Recommendations = recommendations
}

// AnalyzeScope analyzes the scope of variables in a given AST node
func (pp *PatternProcessor) AnalyzeScope(node ast.Node) *interfaces.ScopeInfo {
	info := &interfaces.ScopeInfo{
		Variables: make(map[string]string),
		Functions: []string{},
		Types:     []string{},
		Imports:   []string{},
	}

	ast.Inspect(node, func(n ast.Node) bool {
		switch x := n.(type) {
		case *ast.AssignStmt:
			for i, lhs := range x.Lhs {
				if ident, ok := lhs.(*ast.Ident); ok {
					varType := "interface{}"
					if i < len(x.Rhs) {
						varType = pp.inferVariableType(x.Rhs[i])
					}
					info.Variables[ident.Name] = varType
				}
			}
		case *ast.FuncDecl:
			if x.Name != nil {
				info.Functions = append(info.Functions, x.Name.Name)
			}
		case *ast.GenDecl:
			if x.Tok == token.TYPE {
				for _, spec := range x.Specs {
					if typeSpec, ok := spec.(*ast.TypeSpec); ok {
						info.Types = append(info.Types, typeSpec.Name.Name)
					}
				}
			}
		case *ast.ImportSpec:
			if x.Path != nil {
				info.Imports = append(info.Imports, x.Path.Value)
			}
		}
		return true
	})

	return info
}
