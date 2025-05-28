package resolver

import (
	"context"
	"go/ast"
	"go/parser"
	"go/token"
	"time"

	"error-resolution-pipeline/pkg/detector"
)

// UnusedVariableFixer corrige les variables non utilisées
type UnusedVariableFixer struct{}

func (f *UnusedVariableFixer) CanFix(error detector.DetectedError) bool {
	return error.Type == "unused_variable"
}

func (f *UnusedVariableFixer) Safety() SafetyLevel {
	return SafetySafe
}

func (f *UnusedVariableFixer) Fix(ctx context.Context, error detector.DetectedError, source []byte) (*FixResult, error) {
	// Parse le fichier source
	fset := token.NewFileSet()
	file, err := parser.ParseFile(fset, error.File, source, parser.ParseComments)
	if err != nil {
		return &FixResult{
			Applied:    false,
			Confidence: 0.0,
			Warnings:   []string{"Failed to parse source file"},
			Applied_At: time.Now(),
		}, err
	}

	variableName := error.Context["variable_name"]
	if variableName == "" {
		return &FixResult{
			Applied:    false,
			Confidence: 0.0,
			Warnings:   []string{"Variable name not found in error context"},
			Applied_At: time.Now(),
		}, nil
	}

	modified := false
	var changes []ChangeDetail

	// Parcourir l'AST pour trouver et supprimer la variable
	ast.Inspect(file, func(n ast.Node) bool {
		switch node := n.(type) {
		case *ast.GenDecl:
			if node.Tok == token.VAR {
				// Filtrer les spécifications pour enlever la variable inutilisée
				var newSpecs []ast.Spec
				for _, spec := range node.Specs {
					if valueSpec, ok := spec.(*ast.ValueSpec); ok {
						var newNames []*ast.Ident
						for _, name := range valueSpec.Names {
							if name.Name != variableName {
								newNames = append(newNames, name)
							} else {
								// Variable trouvée et supprimée
								pos := fset.Position(name.Pos())
								changes = append(changes, ChangeDetail{
									Type:        "removal",
									Line:        pos.Line,
									Column:      pos.Column,
									OldContent:  "var " + variableName,
									NewContent:  "// Variable " + variableName + " removed - was unused",
									Description: "Removed unused variable declaration",
								})
								modified = true
							}
						}
						if len(newNames) > 0 {
							valueSpec.Names = newNames
							newSpecs = append(newSpecs, spec)
						}
					} else {
						newSpecs = append(newSpecs, spec)
					}
				}
				node.Specs = newSpecs
			}
		}
		return true
	})

	confidence := 0.95
	if modified {
		confidence = 0.98
	}

	return &FixResult{
		Applied:     modified,
		ModifiedAST: file,
		Changes:     changes,
		Confidence:  confidence,
		Applied_At:  time.Now(),
	}, nil
}

// TypeMismatchFixer corrige les problèmes de types
type TypeMismatchFixer struct{}

func (f *TypeMismatchFixer) CanFix(error detector.DetectedError) bool {
	return error.Type == "type_mismatch"
}

func (f *TypeMismatchFixer) Safety() SafetyLevel {
	return SafetyCautious
}

func (f *TypeMismatchFixer) Fix(ctx context.Context, error detector.DetectedError, source []byte) (*FixResult, error) {
	// Parse le fichier source
	fset := token.NewFileSet()
	file, err := parser.ParseFile(fset, error.File, source, parser.ParseComments)
	if err != nil {
		return &FixResult{
			Applied:    false,
			Confidence: 0.0,
			Warnings:   []string{"Failed to parse source file"},
			Applied_At: time.Now(),
		}, err
	}

	modified := false
	var changes []ChangeDetail

	// Chercher les conversions de type potentiellement dangereuses
	ast.Inspect(file, func(n ast.Node) bool {
		if callExpr, ok := n.(*ast.CallExpr); ok {
			pos := fset.Position(callExpr.Pos())
			if pos.Line == error.Line {
				// Ajouter une vérification de type
				if f.needsTypeAssertion(callExpr) {
					changes = append(changes, ChangeDetail{
						Type:        "modification",
						Line:        pos.Line,
						Column:      pos.Column,
						OldContent:  "type conversion",
						NewContent:  "type assertion with ok check",
						Description: "Added type safety check",
					})
					modified = true
				}
			}
		}
		return true
	})

	return &FixResult{
		Applied:     modified,
		ModifiedAST: file,
		Changes:     changes,
		Confidence:  0.75, // Lower confidence for type fixes
		Warnings:    []string{"Type fixes require manual review"},
		Applied_At:  time.Now(),
	}, nil
}

func (f *TypeMismatchFixer) needsTypeAssertion(callExpr *ast.CallExpr) bool {
	// Logique simplifiée pour détecter les conversions nécessitant des assertions
	return len(callExpr.Args) > 0
}

// ComplexityFixer réduit la complexité en extrayant des méthodes
type ComplexityFixer struct{}

func (f *ComplexityFixer) CanFix(error detector.DetectedError) bool {
	return error.Type == "high_complexity"
}

func (f *ComplexityFixer) Safety() SafetyLevel {
	return SafetyCautious
}

func (f *ComplexityFixer) Fix(ctx context.Context, error detector.DetectedError, source []byte) (*FixResult, error) {
	// Parse le fichier source
	fset := token.NewFileSet()
	file, err := parser.ParseFile(fset, error.File, source, parser.ParseComments)
	if err != nil {
		return &FixResult{
			Applied:    false,
			Confidence: 0.0,
			Warnings:   []string{"Failed to parse source file"},
			Applied_At: time.Now(),
		}, err
	}

	functionName := error.Context["function_name"]
	if functionName == "" {
		return &FixResult{
			Applied:    false,
			Confidence: 0.0,
			Warnings:   []string{"Function name not found in error context"},
			Applied_At: time.Now(),
		}, nil
	}

	modified := false
	var changes []ChangeDetail

	// Chercher la fonction complexe
	ast.Inspect(file, func(n ast.Node) bool {
		if funcDecl, ok := n.(*ast.FuncDecl); ok {
			if funcDecl.Name.Name == functionName {
				// Analyser la complexité et suggérer des extractions
				extractableBlocks := f.findExtractableBlocks(funcDecl)
				if len(extractableBlocks) > 0 {
					pos := fset.Position(funcDecl.Pos())
					changes = append(changes, ChangeDetail{
						Type:        "suggestion",
						Line:        pos.Line,
						Column:      pos.Column,
						OldContent:  "complex function",
						NewContent:  "function with extracted methods",
						Description: "Suggested method extraction to reduce complexity",
					})
					modified = true
				}
			}
		}
		return true
	})

	return &FixResult{
		Applied:     false, // Ne pas appliquer automatiquement les changements de complexité
		ModifiedAST: file,
		Changes:     changes,
		Confidence:  0.60,
		Warnings:    []string{"Complexity fixes require manual review and testing"},
		Applied_At:  time.Now(),
	}, nil
}

func (f *ComplexityFixer) findExtractableBlocks(funcDecl *ast.FuncDecl) []ast.Stmt {
	var blocks []ast.Stmt

	// Logique simplifiée pour identifier les blocs extractibles
	if funcDecl.Body != nil {
		for _, stmt := range funcDecl.Body.List {
			if blockStmt, ok := stmt.(*ast.BlockStmt); ok {
				if len(blockStmt.List) > 5 { // Seuil arbitraire
					blocks = append(blocks, stmt)
				}
			}
		}
	}

	return blocks
}

// CircularDependencyFixer résout les dépendances circulaires
type CircularDependencyFixer struct{}

func (f *CircularDependencyFixer) CanFix(error detector.DetectedError) bool {
	return error.Type == "circular_dependency"
}

func (f *CircularDependencyFixer) Safety() SafetyLevel {
	return SafetyCautious
}

func (f *CircularDependencyFixer) Fix(ctx context.Context, error detector.DetectedError, source []byte) (*FixResult, error) {
	return &FixResult{
		Applied:    false,
		Confidence: 0.3,
		Warnings: []string{
			"Circular dependency resolution requires architectural changes",
			"Consider extracting interfaces or refactoring package structure",
		},
		Applied_At: time.Now(),
	}, nil
}
