package detector

import (
	"go/ast"
	"go/token"
	"go/types"
	"strings"
	"time"
)

// UnusedVariablePattern détecte les variables non utilisées
type UnusedVariablePattern struct{}

func (p *UnusedVariablePattern) Name() string {
	return "unused_variable"
}

func (p *UnusedVariablePattern) Priority() int {
	return 3
}

func (p *UnusedVariablePattern) Detect(node ast.Node, info *types.Info, fset *token.FileSet) []DetectedError {
	var errors []DetectedError

	switch n := node.(type) {
	case *ast.GenDecl:
		if n.Tok == token.VAR {
			for _, spec := range n.Specs {
				if valueSpec, ok := spec.(*ast.ValueSpec); ok {
					for _, name := range valueSpec.Names {
						if name.Name != "_" && strings.HasPrefix(name.Name, "_") {
							continue // Skip intentionally unused variables
						}

						// Vérifier si la variable est utilisée
						if obj := info.Defs[name]; obj != nil {
							if !p.isVariableUsed(name, info) {
								pos := fset.Position(name.Pos())
								errors = append(errors, DetectedError{
									ID:       generateID("unused_var", pos),
									Type:     "unused_variable",
									Severity: SeverityWarning,
									Message:  "Variable '" + name.Name + "' is declared but never used",
									File:     pos.Filename,
									Line:     pos.Line,
									Column:   pos.Column,
									Context: map[string]string{
										"variable_name": name.Name,
										"declaration":   "var " + name.Name,
									},
									Suggestions: []string{
										"Remove the unused variable",
										"Prefix with underscore if intentionally unused",
									},
									DetectedAt: time.Now(),
								})
							}
						}
					}
				}
			}
		}
	}

	return errors
}

func (p *UnusedVariablePattern) isVariableUsed(ident *ast.Ident, info *types.Info) bool {
	obj := info.Defs[ident]
	if obj == nil {
		return true // Assume used if we can't determine
	}

	for _, use := range info.Uses {
		if use == obj {
			return true
		}
	}
	return false
}

// CircularDependencyPattern détecte les dépendances circulaires
type CircularDependencyPattern struct{}

func (p *CircularDependencyPattern) Name() string {
	return "circular_dependency"
}

func (p *CircularDependencyPattern) Priority() int {
	return 1 // High priority
}

func (p *CircularDependencyPattern) Detect(node ast.Node, info *types.Info, fset *token.FileSet) []DetectedError {
	var errors []DetectedError

	if importSpec, ok := node.(*ast.ImportSpec); ok {
		importPath := strings.Trim(importSpec.Path.Value, "\"")
		
		// Logic to detect circular imports would be more complex
		// This is a simplified version
		if p.hasCircularDependency(importPath) {
			pos := fset.Position(importSpec.Pos())
			errors = append(errors, DetectedError{
				ID:       generateID("circular_dep", pos),
				Type:     "circular_dependency",
				Severity: SeverityError,
				Message:  "Circular dependency detected with package: " + importPath,
				File:     pos.Filename,
				Line:     pos.Line,
				Column:   pos.Column,
				Context: map[string]string{
					"import_path": importPath,
				},
				Suggestions: []string{
					"Refactor to break circular dependency",
					"Extract common interface to separate package",
				},
				DetectedAt: time.Now(),
			})
		}
	}

	return errors
}

func (p *CircularDependencyPattern) hasCircularDependency(importPath string) bool {
	// Simplified check - in reality, this would analyze the full dependency graph
	return false
}

// TypeMismatchPattern détecte les erreurs de type
type TypeMismatchPattern struct{}

func (p *TypeMismatchPattern) Name() string {
	return "type_mismatch"
}

func (p *TypeMismatchPattern) Priority() int {
	return 2
}

func (p *TypeMismatchPattern) Detect(node ast.Node, info *types.Info, fset *token.FileSet) []DetectedError {
	var errors []DetectedError

	if callExpr, ok := node.(*ast.CallExpr); ok {
		// Check for potential type conversion issues
		if len(callExpr.Args) > 0 {
			for _, arg := range callExpr.Args {
				if tv, ok := info.Types[arg]; ok {
					if p.isUnsafeTypeConversion(tv.Type) {
						pos := fset.Position(arg.Pos())
						errors = append(errors, DetectedError{
							ID:       generateID("type_mismatch", pos),
							Type:     "type_mismatch",
							Severity: SeverityWarning,
							Message:  "Potentially unsafe type conversion detected",
							File:     pos.Filename,
							Line:     pos.Line,
							Column:   pos.Column,
							Context: map[string]string{
								"type": tv.Type.String(),
							},
							Suggestions: []string{
								"Add explicit type checking",
								"Use type assertion with ok check",
							},
							DetectedAt: time.Now(),
						})
					}
				}
			}
		}
	}

	return errors
}

func (p *TypeMismatchPattern) isUnsafeTypeConversion(t types.Type) bool {
	// Simplified check for demonstration
	return false
}

// ComplexityPattern détecte la complexité excessive
type ComplexityPattern struct{}

func (p *ComplexityPattern) Name() string {
	return "complexity"
}

func (p *ComplexityPattern) Priority() int {
	return 4
}

func (p *ComplexityPattern) Detect(node ast.Node, info *types.Info, fset *token.FileSet) []DetectedError {
	var errors []DetectedError

	if funcDecl, ok := node.(*ast.FuncDecl); ok {
		complexity := p.calculateCyclomaticComplexity(funcDecl)
		if complexity > 10 { // Threshold
			pos := fset.Position(funcDecl.Pos())
			errors = append(errors, DetectedError{
				ID:       generateID("complexity", pos),
				Type:     "high_complexity",
				Severity: SeverityWarning,
				Message:  "Function has high cyclomatic complexity",
				File:     pos.Filename,
				Line:     pos.Line,
				Column:   pos.Column,
				Context: map[string]string{
					"function_name": funcDecl.Name.Name,
					"complexity":    string(rune(complexity)),
				},
				Suggestions: []string{
					"Break function into smaller functions",
					"Reduce conditional complexity",
					"Extract helper methods",
				},
				DetectedAt: time.Now(),
			})
		}
	}

	return errors
}

func (p *ComplexityPattern) calculateCyclomaticComplexity(fn *ast.FuncDecl) int {
	complexity := 1 // Base complexity

	ast.Inspect(fn, func(n ast.Node) bool {
		switch n.(type) {
		case *ast.IfStmt, *ast.ForStmt, *ast.RangeStmt, *ast.SwitchStmt, *ast.TypeSwitchStmt:
			complexity++
		case *ast.CaseClause:
			complexity++
		}
		return true
	})

	return complexity
}

// generateID génère un ID unique pour une erreur
func generateID(errorType string, pos token.Position) string {
	return errorType + "_" + pos.Filename + "_" + string(rune(pos.Line)) + "_" + string(rune(pos.Column))
}
