// Règles de détection personnalisées - Phase 9.2
// Plan de développement v42 - Gestionnaire d'erreurs avancé
package static

import (
	"fmt"
	"go/ast"
	"go/token"
	"go/types"
	"strings"
)

// CustomLintRules contient toutes les règles de lint personnalisées
type CustomLintRules struct {
	rules []LintRule
}

// NewCustomLintRules crée une nouvelle instance des règles personnalisées
func NewCustomLintRules() *CustomLintRules {
	rules := &CustomLintRules{
		rules: make([]LintRule, 0),
	}
	
	// Ajouter toutes les règles personnalisées
	rules.rules = append(rules.rules,
		&DRYViolationRule{},
		&KISSViolationRule{},
		&SOLIDViolationRule{},
		&ComplexityRule{},
		&NamingConventionRule{},
		&ErrorHandlingRule{},
		&PerformanceRule{},
		&SecurityRule{},
		&MaintainabilityRule{},
		&TestabilityRule{},
	)
	
	return rules
}

// GetRules retourne toutes les règles
func (c *CustomLintRules) GetRules() []LintRule {
	return c.rules
}

// DRYViolationRule détecte les violations du principe DRY (Don't Repeat Yourself)
type DRYViolationRule struct{}

func (r *DRYViolationRule) Name() string        { return "dry_violation" }
func (r *DRYViolationRule) Description() string { return "Detect DRY (Don't Repeat Yourself) violations" }
func (r *DRYViolationRule) Category() IssueCategory { return CategoryMaintenance }
func (r *DRYViolationRule) Severity() IssueSeverity { return SeverityWarning }

func (r *DRYViolationRule) Check(file *ast.File, fset *token.FileSet, info *types.Info) []StaticIssue {
	issues := make([]StaticIssue, 0)
	codeBlocks := make(map[string][]*ast.Node)
	
	// Analyser les blocs de code similaires
	ast.Inspect(file, func(node ast.Node) bool {
		switch n := node.(type) {
		case *ast.FuncDecl:
			if n.Body != nil {
				// Extraire la signature de la fonction pour détecter les duplications
				signature := r.extractFunctionSignature(n, fset)
				codeBlocks[signature] = append(codeBlocks[signature], &node)
			}
		case *ast.BlockStmt:
			// Analyser les blocs de code similaires
			signature := r.extractBlockSignature(n, fset)
			if len(signature) > 50 { // Seulement pour les blocs significatifs
				codeBlocks[signature] = append(codeBlocks[signature], &node)
			}
		}
		return true
	})
	
	// Détecter les duplications
	for signature, nodes := range codeBlocks {
		if len(nodes) > 1 {
			for _, node := range nodes {
				pos := fset.Position((*node).Pos())
				issues = append(issues, StaticIssue{
					Type:     IssueTypeSecurity,
					Severity: r.Severity(),
					Message:  fmt.Sprintf("Potential DRY violation: duplicate code pattern detected (%d occurrences)", len(nodes)),
					Line:     pos.Line,
					Column:   pos.Column,
					Rule:     r.Name(),
					Category: r.Category(),
					Context: map[string]interface{}{
						"signature":    signature,
						"occurrences":  len(nodes),
						"pattern_type": "code_duplication",
					},
				})
			}
		}
	}
	
	return issues
}

func (r *DRYViolationRule) extractFunctionSignature(fn *ast.FuncDecl, fset *token.FileSet) string {
	var signature strings.Builder
	
	// Nom de la fonction
	if fn.Name != nil {
		signature.WriteString(fn.Name.Name)
	}
	
	// Paramètres
	if fn.Type.Params != nil {
		signature.WriteString("(")
		for i, param := range fn.Type.Params.List {
			if i > 0 {
				signature.WriteString(",")
			}
			if param.Type != nil {
				signature.WriteString(fmt.Sprintf("%v", param.Type))
			}
		}
		signature.WriteString(")")
	}
	
	return signature.String()
}

func (r *DRYViolationRule) extractBlockSignature(block *ast.BlockStmt, fset *token.FileSet) string {
	// Extraire une signature simplifiée du bloc de code
	var signature strings.Builder
	
	for _, stmt := range block.List {
		switch s := stmt.(type) {
		case *ast.AssignStmt:
			signature.WriteString("assign;")
		case *ast.IfStmt:
			signature.WriteString("if;")
		case *ast.ForStmt:
			signature.WriteString("for;")
		case *ast.ExprStmt:
			signature.WriteString("expr;")
		case *ast.ReturnStmt:
			signature.WriteString("return;")
		default:
			signature.WriteString(fmt.Sprintf("%T;", s))
		}
	}
	
	return signature.String()
}

// KISSViolationRule détecte les violations du principe KISS (Keep It Simple, Stupid)
type KISSViolationRule struct{}

func (r *KISSViolationRule) Name() string        { return "kiss_violation" }
func (r *KISSViolationRule) Description() string { return "Detect KISS (Keep It Simple, Stupid) violations" }
func (r *KISSViolationRule) Category() IssueCategory { return CategoryMaintenance }
func (r *KISSViolationRule) Severity() IssueSeverity { return SeverityWarning }

func (r *KISSViolationRule) Check(file *ast.File, fset *token.FileSet, info *types.Info) []StaticIssue {
	issues := make([]StaticIssue, 0)
	
	ast.Inspect(file, func(node ast.Node) bool {
		switch n := node.(type) {
		case *ast.FuncDecl:
			if n.Body != nil {
				// Vérifier la complexité de la fonction
				complexity := r.calculateFunctionComplexity(n)
				if complexity > 15 {
					pos := fset.Position(n.Pos())
					issues = append(issues, StaticIssue{
						Type:     IssueTypeComplexity,
						Severity: r.Severity(),
						Message:  fmt.Sprintf("Function too complex (complexity: %d). Consider breaking it down.", complexity),
						Line:     pos.Line,
						Column:   pos.Column,
						Rule:     r.Name(),
						Category: r.Category(),
						Context: map[string]interface{}{
							"complexity":     complexity,
							"function_name":  n.Name.Name,
							"max_complexity": 15,
						},
					})
				}
				
				// Vérifier le nombre de paramètres
				if n.Type.Params != nil && len(n.Type.Params.List) > 5 {
					pos := fset.Position(n.Pos())
					issues = append(issues, StaticIssue{
						Type:     IssueTypeStyle,
						Severity: SeverityInfo,
						Message:  fmt.Sprintf("Function has too many parameters (%d). Consider using a struct.", len(n.Type.Params.List)),
						Line:     pos.Line,
						Column:   pos.Column,
						Rule:     r.Name(),
						Category: r.Category(),
						Context: map[string]interface{}{
							"parameter_count": len(n.Type.Params.List),
							"function_name":   n.Name.Name,
							"max_parameters":  5,
						},
					})
				}
			}
		case *ast.IfStmt:
			// Détecter les chaînes if-else trop longues
			elseCount := r.countElseChain(n)
			if elseCount > 3 {
				pos := fset.Position(n.Pos())
				issues = append(issues, StaticIssue{
					Type:     IssueTypeComplexity,
					Severity: SeverityWarning,
					Message:  fmt.Sprintf("Too many else-if statements (%d). Consider using switch or map.", elseCount),
					Line:     pos.Line,
					Column:   pos.Column,
					Rule:     r.Name(),
					Category: r.Category(),
					Context: map[string]interface{}{
						"else_count": elseCount,
						"max_else":   3,
					},
				})
			}
		}
		return true
	})
	
	return issues
}

func (r *KISSViolationRule) calculateFunctionComplexity(fn *ast.FuncDecl) int {
	complexity := 1
	
	ast.Inspect(fn, func(node ast.Node) bool {
		switch node.(type) {
		case *ast.IfStmt, *ast.ForStmt, *ast.RangeStmt, *ast.SwitchStmt, *ast.TypeSwitchStmt:
			complexity++
		case *ast.CaseClause:
			complexity++
		}
		return true
	})
	
	return complexity
}

func (r *KISSViolationRule) countElseChain(ifStmt *ast.IfStmt) int {
	count := 0
	current := ifStmt
	
	for current != nil {
		if current.Else != nil {
			count++
			if elseIf, ok := current.Else.(*ast.IfStmt); ok {
				current = elseIf
			} else {
				break
			}
		} else {
			break
		}
	}
	
	return count
}

// SOLIDViolationRule détecte les violations des principes SOLID
type SOLIDViolationRule struct{}

func (r *SOLIDViolationRule) Name() string        { return "solid_violation" }
func (r *SOLIDViolationRule) Description() string { return "Detect SOLID principles violations" }
func (r *SOLIDViolationRule) Category() IssueCategory { return CategoryMaintenance }
func (r *SOLIDViolationRule) Severity() IssueSeverity { return SeverityWarning }

func (r *SOLIDViolationRule) Check(file *ast.File, fset *token.FileSet, info *types.Info) []StaticIssue {
	issues := make([]StaticIssue, 0)
	
	ast.Inspect(file, func(node ast.Node) bool {
		switch n := node.(type) {
		case *ast.TypeSpec:
			if structType, ok := n.Type.(*ast.StructType); ok {
				// Single Responsibility Principle - trop de champs
				if structType.Fields != nil && len(structType.Fields.List) > 10 {
					pos := fset.Position(n.Pos())
					issues = append(issues, StaticIssue{
						Type:     IssueTypeStyle,
						Severity: r.Severity(),
						Message:  fmt.Sprintf("Struct '%s' may violate SRP: too many fields (%d)", n.Name.Name, len(structType.Fields.List)),
						Line:     pos.Line,
						Column:   pos.Column,
						Rule:     r.Name(),
						Category: r.Category(),
						Context: map[string]interface{}{
							"struct_name":  n.Name.Name,
							"field_count":  len(structType.Fields.List),
							"principle":    "Single Responsibility",
							"max_fields":   10,
						},
					})
				}
			}
		case *ast.FuncDecl:
			// Interface Segregation Principle - vérifier les méthodes
			if n.Recv != nil && n.Body != nil {
				// Analyser les dépendances de la méthode
				dependencies := r.analyzeDependencies(n)
				if len(dependencies) > 5 {
					pos := fset.Position(n.Pos())
					issues = append(issues, StaticIssue{
						Type:     IssueTypeStyle,
						Severity: SeverityInfo,
						Message:  fmt.Sprintf("Method '%s' has many dependencies (%d). Consider interface segregation.", n.Name.Name, len(dependencies)),
						Line:     pos.Line,
						Column:   pos.Column,
						Rule:     r.Name(),
						Category: r.Category(),
						Context: map[string]interface{}{
							"method_name":      n.Name.Name,
							"dependency_count": len(dependencies),
							"principle":        "Interface Segregation",
							"max_dependencies": 5,
						},
					})
				}
			}
		}
		return true
	})
	
	return issues
}

func (r *SOLIDViolationRule) analyzeDependencies(fn *ast.FuncDecl) []string {
	dependencies := make(map[string]bool)
	
	ast.Inspect(fn, func(node ast.Node) bool {
		switch n := node.(type) {
		case *ast.SelectorExpr:
			if ident, ok := n.X.(*ast.Ident); ok {
				dependencies[ident.Name] = true
			}
		case *ast.CallExpr:
			if fun, ok := n.Fun.(*ast.Ident); ok {
				dependencies[fun.Name] = true
			}
		}
		return true
	})
	
	result := make([]string, 0, len(dependencies))
	for dep := range dependencies {
		result = append(result, dep)
	}
	
	return result
}

// ComplexityRule détecte les problèmes de complexité
type ComplexityRule struct{}

func (r *ComplexityRule) Name() string        { return "complexity" }
func (r *ComplexityRule) Description() string { return "Detect complexity issues" }
func (r *ComplexityRule) Category() IssueCategory { return CategoryMaintenance }
func (r *ComplexityRule) Severity() IssueSeverity { return SeverityWarning }

func (r *ComplexityRule) Check(file *ast.File, fset *token.FileSet, info *types.Info) []StaticIssue {
	issues := make([]StaticIssue, 0)
	
	ast.Inspect(file, func(node ast.Node) bool {
		switch n := node.(type) {
		case *ast.FuncDecl:
			if n.Body != nil {
				// Calculer la profondeur d'imbrication
				maxDepth := r.calculateNestingDepth(n.Body, 0)
				if maxDepth > 4 {
					pos := fset.Position(n.Pos())
					issues = append(issues, StaticIssue{
						Type:     IssueTypeComplexity,
						Severity: r.Severity(),
						Message:  fmt.Sprintf("Function '%s' has deep nesting (depth: %d). Consider refactoring.", n.Name.Name, maxDepth),
						Line:     pos.Line,
						Column:   pos.Column,
						Rule:     r.Name(),
						Category: r.Category(),
						Context: map[string]interface{}{
							"function_name": n.Name.Name,
							"nesting_depth": maxDepth,
							"max_depth":     4,
						},
					})
				}
			}
		}
		return true
	})
	
	return issues
}

func (r *ComplexityRule) calculateNestingDepth(node ast.Node, currentDepth int) int {
	maxDepth := currentDepth
	
	ast.Inspect(node, func(n ast.Node) bool {
		switch n.(type) {
		case *ast.IfStmt, *ast.ForStmt, *ast.RangeStmt, *ast.SwitchStmt, *ast.TypeSwitchStmt:
			depth := r.calculateNestingDepth(n, currentDepth+1)
			if depth > maxDepth {
				maxDepth = depth
			}
			return false // Ne pas continuer l'inspection dans ce sous-arbre
		}
		return true
	})
	
	return maxDepth
}

// NamingConventionRule vérifie les conventions de nommage
type NamingConventionRule struct{}

func (r *NamingConventionRule) Name() string        { return "naming_convention" }
func (r *NamingConventionRule) Description() string { return "Check Go naming conventions" }
func (r *NamingConventionRule) Category() IssueCategory { return CategoryStyle }
func (r *NamingConventionRule) Severity() IssueSeverity { return SeverityInfo }

func (r *NamingConventionRule) Check(file *ast.File, fset *token.FileSet, info *types.Info) []StaticIssue {
	issues := make([]StaticIssue, 0)
	
	ast.Inspect(file, func(node ast.Node) bool {
		switch n := node.(type) {
		case *ast.FuncDecl:
			if n.Name != nil && !r.isValidFunctionName(n.Name.Name) {
				pos := fset.Position(n.Pos())
				issues = append(issues, StaticIssue{
					Type:     IssueTypeStyle,
					Severity: r.Severity(),
					Message:  fmt.Sprintf("Function name '%s' doesn't follow Go naming conventions", n.Name.Name),
					Line:     pos.Line,
					Column:   pos.Column,
					Rule:     r.Name(),
					Category: r.Category(),
					Context: map[string]interface{}{
						"function_name": n.Name.Name,
						"convention":    "camelCase or PascalCase",
					},
				})
			}
		case *ast.TypeSpec:
			if !r.isValidTypeName(n.Name.Name) {
				pos := fset.Position(n.Pos())
				issues = append(issues, StaticIssue{
					Type:     IssueTypeStyle,
					Severity: r.Severity(),
					Message:  fmt.Sprintf("Type name '%s' doesn't follow Go naming conventions", n.Name.Name),
					Line:     pos.Line,
					Column:   pos.Column,
					Rule:     r.Name(),
					Category: r.Category(),
					Context: map[string]interface{}{
						"type_name":  n.Name.Name,
						"convention": "PascalCase",
					},
				})
			}
		case *ast.GenDecl:
			if n.Tok == token.VAR {
				for _, spec := range n.Specs {
					if valueSpec, ok := spec.(*ast.ValueSpec); ok {
						for _, name := range valueSpec.Names {
							if !r.isValidVariableName(name.Name) {
								pos := fset.Position(name.Pos())
								issues = append(issues, StaticIssue{
									Type:     IssueTypeStyle,
									Severity: r.Severity(),
									Message:  fmt.Sprintf("Variable name '%s' doesn't follow Go naming conventions", name.Name),
									Line:     pos.Line,
									Column:   pos.Column,
									Rule:     r.Name(),
									Category: r.Category(),
									Context: map[string]interface{}{
										"variable_name": name.Name,
										"convention":    "camelCase",
									},
								})
							}
						}
					}
				}
			}
		}
		return true
	})
	
	return issues
}

func (r *NamingConventionRule) isValidFunctionName(name string) bool {
	if len(name) == 0 {
		return false
	}
	
	// Vérifier que le nom commence par une lettre
	if !((name[0] >= 'a' && name[0] <= 'z') || (name[0] >= 'A' && name[0] <= 'Z')) {
		return false
	}
	
	// Vérifier l'absence d'underscores (sauf pour les fonctions de test)
	if strings.Contains(name, "_") && !strings.HasPrefix(name, "Test") && !strings.HasPrefix(name, "Benchmark") {
		return false
	}
	
	return true
}

func (r *NamingConventionRule) isValidTypeName(name string) bool {
	if len(name) == 0 {
		return false
	}
	
	// Les types doivent commencer par une majuscule pour être exportés
	return name[0] >= 'A' && name[0] <= 'Z'
}

func (r *NamingConventionRule) isValidVariableName(name string) bool {
	if len(name) == 0 {
		return false
	}
	
	// Vérifier que le nom commence par une lettre minuscule ou majuscule
	if !((name[0] >= 'a' && name[0] <= 'z') || (name[0] >= 'A' && name[0] <= 'Z')) {
		return false
	}
	
	// Éviter les underscores dans les noms de variables
	return !strings.Contains(name, "_")
}

// ErrorHandlingRule vérifie la gestion des erreurs
type ErrorHandlingRule struct{}

func (r *ErrorHandlingRule) Name() string        { return "error_handling" }
func (r *ErrorHandlingRule) Description() string { return "Check error handling patterns" }
func (r *ErrorHandlingRule) Category() IssueCategory { return CategoryBugRisk }
func (r *ErrorHandlingRule) Severity() IssueSeverity { return SeverityError }

func (r *ErrorHandlingRule) Check(file *ast.File, fset *token.FileSet, info *types.Info) []StaticIssue {
	issues := make([]StaticIssue, 0)
	
	ast.Inspect(file, func(node ast.Node) bool {
		switch n := node.(type) {
		case *ast.AssignStmt:
			// Vérifier les erreurs ignorées
			if r.hasIgnoredError(n) {
				pos := fset.Position(n.Pos())
				issues = append(issues, StaticIssue{
					Type:     IssueTypeSecurity,
					Severity: r.Severity(),
					Message:  "Error is ignored with blank identifier. Consider proper error handling.",
					Line:     pos.Line,
					Column:   pos.Column,
					Rule:     r.Name(),
					Category: r.Category(),
					Context: map[string]interface{}{
						"pattern": "ignored_error",
					},
				})
			}
		case *ast.CallExpr:
			// Vérifier les appels de fonction sans gestion d'erreur
			if r.returnsError(n, info) && !r.isErrorHandled(n, node) {
				pos := fset.Position(n.Pos())
				issues = append(issues, StaticIssue{
					Type:     IssueTypeSecurity,
					Severity: SeverityWarning,
					Message:  "Function call that returns error is not properly handled.",
					Line:     pos.Line,
					Column:   pos.Column,
					Rule:     r.Name(),
					Category: r.Category(),
					Context: map[string]interface{}{
						"pattern": "unhandled_error",
					},
				})
			}
		}
		return true
	})
	
	return issues
}

func (r *ErrorHandlingRule) hasIgnoredError(assign *ast.AssignStmt) bool {
	for _, lhs := range assign.Lhs {
		if ident, ok := lhs.(*ast.Ident); ok && ident.Name == "_" {
			return true
		}
	}
	return false
}

func (r *ErrorHandlingRule) returnsError(call *ast.CallExpr, info *types.Info) bool {
	// Cette fonction nécessiterait une analyse plus approfondie des types
	// Pour simplifier, on peut chercher des patterns communs
	if fun, ok := call.Fun.(*ast.Ident); ok {
		// Fonctions courantes qui retournent des erreurs
		errorFunctions := []string{"Open", "Create", "Marshal", "Unmarshal", "Parse", "Read", "Write"}
		for _, errFunc := range errorFunctions {
			if strings.Contains(fun.Name, errFunc) {
				return true
			}
		}
	}
	return false
}

func (r *ErrorHandlingRule) isErrorHandled(call *ast.CallExpr, context ast.Node) bool {
	// Vérifier si l'erreur est assignée à une variable
	// Cette implémentation est simplifiée
	return false
}

// PerformanceRule détecte les problèmes de performance potentiels
type PerformanceRule struct{}

func (r *PerformanceRule) Name() string        { return "performance" }
func (r *PerformanceRule) Description() string { return "Detect potential performance issues" }
func (r *PerformanceRule) Category() IssueCategory { return CategoryPerformance }
func (r *PerformanceRule) Severity() IssueSeverity { return SeverityInfo }

func (r *PerformanceRule) Check(file *ast.File, fset *token.FileSet, info *types.Info) []StaticIssue {
	issues := make([]StaticIssue, 0)
	
	ast.Inspect(file, func(node ast.Node) bool {
		switch n := node.(type) {
		case *ast.RangeStmt:
			// Détecter l'allocation de slice dans une boucle
			if r.hasSliceAllocationInLoop(n) {
				pos := fset.Position(n.Pos())
				issues = append(issues, StaticIssue{
					Type:     IssueTypePerformance,
					Severity: r.Severity(),
					Message:  "Slice allocation inside loop may cause performance issues. Consider pre-allocating.",
					Line:     pos.Line,
					Column:   pos.Column,
					Rule:     r.Name(),
					Category: r.Category(),
					Context: map[string]interface{}{
						"pattern": "slice_allocation_in_loop",
					},
				})
			}
		case *ast.CallExpr:
			// Détecter les concaténations de strings répétées
			if r.isStringConcatenation(n) {
				pos := fset.Position(n.Pos())
				issues = append(issues, StaticIssue{
					Type:     IssueTypePerformance,
					Severity: r.Severity(),
					Message:  "Consider using strings.Builder for multiple string concatenations.",
					Line:     pos.Line,
					Column:   pos.Column,
					Rule:     r.Name(),
					Category: r.Category(),
					Context: map[string]interface{}{
						"pattern": "string_concatenation",
					},
				})
			}
		}
		return true
	})
	
	return issues
}

func (r *PerformanceRule) hasSliceAllocationInLoop(rangeStmt *ast.RangeStmt) bool {
	found := false
	ast.Inspect(rangeStmt.Body, func(node ast.Node) bool {
		if call, ok := node.(*ast.CallExpr); ok {
			if ident, ok := call.Fun.(*ast.Ident); ok {
				if ident.Name == "make" || ident.Name == "append" {
					found = true
					return false
				}
			}
		}
		return true
	})
	return found
}

func (r *PerformanceRule) isStringConcatenation(call *ast.CallExpr) bool {
	// Vérifier si c'est un appel à une fonction de concaténation
	if ident, ok := call.Fun.(*ast.Ident); ok {
		return ident.Name == "Join" || ident.Name == "Sprintf"
	}
	return false
}

// SecurityRule détecte les problèmes de sécurité potentiels
type SecurityRule struct{}

func (r *SecurityRule) Name() string        { return "security" }
func (r *SecurityRule) Description() string { return "Detect potential security issues" }
func (r *SecurityRule) Category() IssueCategory { return CategorySecurity }
func (r *SecurityRule) Severity() IssueSeverity { return SeverityError }

func (r *SecurityRule) Check(file *ast.File, fset *token.FileSet, info *types.Info) []StaticIssue {
	issues := make([]StaticIssue, 0)
	
	ast.Inspect(file, func(node ast.Node) bool {
		switch n := node.(type) {
		case *ast.CallExpr:
			if r.isUnsafeFunction(n) {
				pos := fset.Position(n.Pos())
				issues = append(issues, StaticIssue{
					Type:     IssueTypeSecurity,
					Severity: r.Severity(),
					Message:  "Usage of potentially unsafe function detected.",
					Line:     pos.Line,
					Column:   pos.Column,
					Rule:     r.Name(),
					Category: r.Category(),
					Context: map[string]interface{}{
						"pattern": "unsafe_function",
					},
				})
			}
		case *ast.BasicLit:
			// Détecter les mots de passe hardcodés
			if r.isHardcodedSecret(n) {
				pos := fset.Position(n.Pos())
				issues = append(issues, StaticIssue{
					Type:     IssueTypeSecurity,
					Severity: r.Severity(),
					Message:  "Potential hardcoded secret detected.",
					Line:     pos.Line,
					Column:   pos.Column,
					Rule:     r.Name(),
					Category: r.Category(),
					Context: map[string]interface{}{
						"pattern": "hardcoded_secret",
					},
				})
			}
		}
		return true
	})
	
	return issues
}

func (r *SecurityRule) isUnsafeFunction(call *ast.CallExpr) bool {
	if sel, ok := call.Fun.(*ast.SelectorExpr); ok {
		if ident, ok := sel.X.(*ast.Ident); ok {
			return ident.Name == "unsafe"
		}
	}
	return false
}

func (r *SecurityRule) isHardcodedSecret(lit *ast.BasicLit) bool {
	if lit.Kind == token.STRING {
		value := strings.ToLower(lit.Value)
		secrets := []string{"password", "secret", "key", "token", "auth"}
		for _, secret := range secrets {
			if strings.Contains(value, secret) && len(lit.Value) > 10 {
				return true
			}
		}
	}
	return false
}

// MaintainabilityRule vérifie la maintenabilité du code
type MaintainabilityRule struct{}

func (r *MaintainabilityRule) Name() string        { return "maintainability" }
func (r *MaintainabilityRule) Description() string { return "Check code maintainability" }
func (r *MaintainabilityRule) Category() IssueCategory { return CategoryMaintenance }
func (r *MaintainabilityRule) Severity() IssueSeverity { return SeverityInfo }

func (r *MaintainabilityRule) Check(file *ast.File, fset *token.FileSet, info *types.Info) []StaticIssue {
	issues := make([]StaticIssue, 0)
	
	ast.Inspect(file, func(node ast.Node) bool {
		switch n := node.(type) {
		case *ast.FuncDecl:
			if n.Doc == nil && n.Name.IsExported() {
				pos := fset.Position(n.Pos())
				issues = append(issues, StaticIssue{
					Type:     IssueTypeStyle,
					Severity: r.Severity(),
					Message:  fmt.Sprintf("Exported function '%s' lacks documentation.", n.Name.Name),
					Line:     pos.Line,
					Column:   pos.Column,
					Rule:     r.Name(),
					Category: r.Category(),
					Context: map[string]interface{}{
						"function_name": n.Name.Name,
						"pattern":       "missing_documentation",
					},
				})
			}
		case *ast.TypeSpec:
			if n.Doc == nil && n.Name.IsExported() {
				pos := fset.Position(n.Pos())
				issues = append(issues, StaticIssue{
					Type:     IssueTypeStyle,
					Severity: r.Severity(),
					Message:  fmt.Sprintf("Exported type '%s' lacks documentation.", n.Name.Name),
					Line:     pos.Line,
					Column:   pos.Column,
					Rule:     r.Name(),
					Category: r.Category(),
					Context: map[string]interface{}{
						"type_name": n.Name.Name,
						"pattern":   "missing_documentation",
					},
				})
			}
		}
		return true
	})
	
	return issues
}

// TestabilityRule vérifie la testabilité du code
type TestabilityRule struct{}

func (r *TestabilityRule) Name() string        { return "testability" }
func (r *TestabilityRule) Description() string { return "Check code testability" }
func (r *TestabilityRule) Category() IssueCategory { return CategoryMaintenance }
func (r *TestabilityRule) Severity() IssueSeverity { return SeverityInfo }

func (r *TestabilityRule) Check(file *ast.File, fset *token.FileSet, info *types.Info) []StaticIssue {
	issues := make([]StaticIssue, 0)
	
	ast.Inspect(file, func(node ast.Node) bool {
		switch n := node.(type) {
		case *ast.FuncDecl:
			if n.Body != nil && r.hasGlobalDependency(n) {
				pos := fset.Position(n.Pos())
				issues = append(issues, StaticIssue{
					Type:     IssueTypeStyle,
					Severity: r.Severity(),
					Message:  fmt.Sprintf("Function '%s' has global dependencies, making it harder to test.", n.Name.Name),
					Line:     pos.Line,
					Column:   pos.Column,
					Rule:     r.Name(),
					Category: r.Category(),
					Context: map[string]interface{}{
						"function_name": n.Name.Name,
						"pattern":       "global_dependency",
					},
				})
			}
		}
		return true
	})
	
	return issues
}

func (r *TestabilityRule) hasGlobalDependency(fn *ast.FuncDecl) bool {
	found := false
	ast.Inspect(fn, func(node ast.Node) bool {
		if ident, ok := node.(*ast.Ident); ok {
			// Détecter l'usage de variables globales (simplification)
			if ident.Obj == nil && ident.Name != "nil" && ident.Name != "true" && ident.Name != "false" {
				// Vérifier si c'est une variable globale
				if len(ident.Name) > 0 && ident.Name[0] >= 'A' && ident.Name[0] <= 'Z' {
					found = true
					return false
				}
			}
		}
		return true
	})
	return found
}
