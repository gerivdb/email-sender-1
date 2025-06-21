// internal/ast/analyzer.go
package ast

import (
	"context"
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/contextual-memory-manager/interfaces"
)

type astAnalysisManagerImpl struct {
	storageManager    interfaces.StorageManager
	errorManager      interfaces.ErrorManager
	configManager     interfaces.ConfigManager
	monitoringManager interfaces.MonitoringManager

	cache       *ASTCache
	fileSet     *token.FileSet
	workerPool  *WorkerPool
	initialized bool
	mu          sync.RWMutex
}

// NewASTAnalysisManager crée une nouvelle instance
func NewASTAnalysisManager(
	storageManager interfaces.StorageManager,
	errorManager interfaces.ErrorManager,
	configManager interfaces.ConfigManager,
	monitoringManager interfaces.MonitoringManager,
) (interfaces.ASTAnalysisManager, error) {
	return &astAnalysisManagerImpl{
		storageManager:    storageManager,
		errorManager:      errorManager,
		configManager:     configManager,
		monitoringManager: monitoringManager,
		cache:             NewASTCache(1000, 5*time.Minute),
		fileSet:           token.NewFileSet(),
		workerPool:        NewWorkerPool(4),
	}, nil
}

func (asm *astAnalysisManagerImpl) Initialize(ctx context.Context) error {
	asm.mu.Lock()
	defer asm.mu.Unlock()

	if asm.initialized {
		return nil
	}

	// Initialiser le worker pool
	if err := asm.workerPool.Start(ctx); err != nil {
		return fmt.Errorf("failed to start worker pool: %w", err)
	}

	// Initialiser le cache
	asm.cache.Start(ctx)

	asm.initialized = true
	return nil
}

func (asm *astAnalysisManagerImpl) Shutdown(ctx context.Context) error {
	asm.mu.Lock()
	defer asm.mu.Unlock()

	if !asm.initialized {
		return nil
	}

	// Arrêter le worker pool
	if err := asm.workerPool.Stop(ctx); err != nil {
		asm.errorManager.LogError(ctx, "ast_analyzer", "Failed to stop worker pool", err)
	}

	// Arrêter le cache
	asm.cache.Stop()

	asm.initialized = false
	return nil
}

func (asm *astAnalysisManagerImpl) GetStatus(ctx context.Context) interfaces.ManagerStatus {
	asm.mu.RLock()
	defer asm.mu.RUnlock()

	status := interfaces.ManagerStatus{
		Name:        "ASTAnalysisManager",
		Initialized: asm.initialized,
		LastUpdate:  time.Now(),
	}

	if asm.initialized {
		status.Status = "healthy"
		status.Metadata = map[string]interface{}{
			"cache_entries":    asm.cache.Size(),
			"worker_pool_size": asm.workerPool.Size(),
		}
	} else {
		status.Status = "not_initialized"
	}

	return status
}

func (asm *astAnalysisManagerImpl) AnalyzeFile(ctx context.Context, filePath string) (*interfaces.ASTAnalysisResult, error) {
	asm.mu.RLock()
	defer asm.mu.RUnlock()

	if !asm.initialized {
		return nil, fmt.Errorf("AST analysis manager not initialized")
	}

	start := time.Now()

	// Vérifier le cache d'abord
	if cached, found := asm.cache.Get(filePath); found {
		if err := asm.monitoringManager.RecordCacheHit(ctx, true); err != nil {
			asm.errorManager.LogError(ctx, "ast_analyzer", "Failed to record cache hit", err)
		}
		return cached, nil
	}

	// Cache miss - analyser le fichier
	if err := asm.monitoringManager.RecordCacheHit(ctx, false); err != nil {
		asm.errorManager.LogError(ctx, "ast_analyzer", "Failed to record cache miss", err)
	}

	// Parser le fichier Go
	src, err := asm.readFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read file %s: %w", filePath, err)
	}

	file, err := parser.ParseFile(asm.fileSet, filePath, src, parser.ParseComments)
	if err != nil {
		return nil, fmt.Errorf("failed to parse file %s: %w", filePath, err)
	}

	// Analyser l'AST
	result := &interfaces.ASTAnalysisResult{
		FilePath:         filePath,
		Package:          file.Name.Name,
		Imports:          asm.extractImports(file),
		Functions:        asm.extractFunctions(file),
		Types:            asm.extractTypes(file),
		Variables:        asm.extractVariables(file),
		Constants:        asm.extractConstants(file),
		Dependencies:     asm.extractDependencies(file),
		Complexity:       asm.calculateComplexity(file),
		Context:          asm.buildContext(file),
		Timestamp:        time.Now(),
		AnalysisDuration: time.Since(start),
	}

	// Mettre en cache
	asm.cache.Set(filePath, result)

	// Enregistrer les métriques
	if err := asm.monitoringManager.RecordOperation(ctx, "ast_file_analysis", time.Since(start), nil); err != nil {
		asm.errorManager.LogError(ctx, "ast_analyzer", "Failed to record analysis metrics", err)
	}

	return result, nil
}

func (asm *astAnalysisManagerImpl) AnalyzeWorkspace(ctx context.Context, workspacePath string) (*interfaces.WorkspaceAnalysis, error) {
	start := time.Now()

	analysis := &interfaces.WorkspaceAnalysis{
		RootPath: workspacePath,
		Files:    make([]interfaces.ASTAnalysisResult, 0),
		PackageStructure: interfaces.PackageStructure{
			Packages: make(map[string]*interfaces.PackageInfo),
		},
	}

	// Traverser le workspace et analyser les fichiers Go
	err := filepath.Walk(workspacePath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if !info.IsDir() && strings.HasSuffix(path, ".go") {
			fileResult, err := asm.AnalyzeFile(ctx, path)
			if err != nil {
				asm.errorManager.LogError(ctx, "ast_analyzer", fmt.Sprintf("Failed to analyze file %s", path), err)
				return nil // Continue avec les autres fichiers
			}

			analysis.Files = append(analysis.Files, *fileResult)

			// Mettre à jour la structure des packages
			if packageInfo, exists := analysis.PackageStructure.Packages[fileResult.Package]; exists {
				packageInfo.Files = append(packageInfo.Files, path)
			} else {
				analysis.PackageStructure.Packages[fileResult.Package] = &interfaces.PackageInfo{
					Name:  fileResult.Package,
					Path:  filepath.Dir(path),
					Files: []string{path},
				}
			}
		}

		return nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to traverse workspace: %w", err)
	}

	// Calculer les métriques globales
	analysis.Metrics = asm.calculateWorkspaceMetrics(analysis.Files)
	analysis.BuildTime = time.Since(start)

	return analysis, nil
}

func (asm *astAnalysisManagerImpl) EnrichContextWithAST(ctx context.Context, action interfaces.Action) (*interfaces.EnrichedAction, error) {
	enriched := &interfaces.EnrichedAction{
		OriginalAction: action,
		ASTContext:     make(map[string]interface{}),
		Timestamp:      time.Now(),
	}

	// Si l'action concerne un fichier Go, l'analyser
	if action.FilePath != "" && filepath.Ext(action.FilePath) == ".go" {
		astResult, err := asm.AnalyzeFile(ctx, action.FilePath)
		if err != nil {
			asm.errorManager.LogError(ctx, "ast_analyzer", "Failed to analyze file for context enrichment", err)
			return enriched, nil // Ne pas faire échouer pour une erreur AST
		}

		enriched.ASTResult = astResult

		// Extraire le contexte structurel pour la ligne spécifique
		if action.LineNumber > 0 {
			structuralContext, err := asm.GetStructuralContext(ctx, action.FilePath, action.LineNumber)
			if err == nil {
				enriched.StructuralContext = structuralContext
			}
		}

		// Enrichir avec les informations contextuelles
		enriched.ASTContext["package"] = astResult.Package
		enriched.ASTContext["function_count"] = len(astResult.Functions)
		enriched.ASTContext["type_count"] = len(astResult.Types)
		enriched.ASTContext["complexity"] = astResult.Complexity
		enriched.ASTContext["dependencies"] = len(astResult.Dependencies)
	}

	return enriched, nil
}

func (asm *astAnalysisManagerImpl) GetStructuralContext(ctx context.Context, filePath string, lineNumber int) (*interfaces.StructuralContext, error) {
	// Analyser le fichier pour obtenir l'AST
	astResult, err := asm.AnalyzeFile(ctx, filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to analyze file: %w", err)
	}

	context := &interfaces.StructuralContext{
		LocalVariables:  make([]interfaces.VariableInfo, 0),
		RelatedElements: make([]interface{}, 0),
	}

	// Trouver la fonction contenant cette ligne
	for _, function := range astResult.Functions {
		if lineNumber >= function.LineStart && lineNumber <= function.LineEnd {
			context.CurrentFunction = &function
			context.Scope = "function"
			break
		}
	}

	// Trouver le type contenant cette ligne
	for _, typeInfo := range astResult.Types {
		if lineNumber >= typeInfo.LineStart && lineNumber <= typeInfo.LineEnd {
			context.CurrentType = &typeInfo
			if context.Scope == "" {
				context.Scope = "type"
			}
			break
		}
	}

	// Si aucun scope spécifique trouvé, c'est au niveau package
	if context.Scope == "" {
		context.Scope = "package"
	}

	return context, nil
}

// Méthodes d'extraction des éléments AST
func (asm *astAnalysisManagerImpl) extractImports(file *ast.File) []interfaces.ImportInfo {
	imports := make([]interfaces.ImportInfo, 0, len(file.Imports))

	for _, imp := range file.Imports {
		importInfo := interfaces.ImportInfo{
			Path:       strings.Trim(imp.Path.Value, `"`),
			LineNumber: asm.fileSet.Position(imp.Pos()).Line,
		}

		if imp.Name != nil {
			importInfo.Alias = imp.Name.Name
		}

		// Déterminer si c'est un import standard
		importInfo.IsStandard = asm.isStandardPackage(importInfo.Path)

		imports = append(imports, importInfo)
	}

	return imports
}

func (asm *astAnalysisManagerImpl) extractFunctions(file *ast.File) []interfaces.FunctionInfo {
	functions := make([]interfaces.FunctionInfo, 0)

	ast.Inspect(file, func(n ast.Node) bool {
		switch node := n.(type) {
		case *ast.FuncDecl:
			if node.Name != nil {
				function := interfaces.FunctionInfo{
					Name:        node.Name.Name,
					Package:     file.Name.Name,
					LineStart:   asm.fileSet.Position(node.Pos()).Line,
					LineEnd:     asm.fileSet.Position(node.End()).Line,
					IsExported:  node.Name.IsExported(),
					Parameters:  asm.extractParameters(node.Type.Params),
					ReturnTypes: asm.extractReturnTypes(node.Type.Results),
					Complexity:  asm.calculateFunctionComplexity(node),
				}

				if node.Doc != nil {
					function.Documentation = node.Doc.Text()
				}

				function.Signature = asm.buildFunctionSignature(function)
				functions = append(functions, function)
			}
		}
		return true
	})

	return functions
}

func (asm *astAnalysisManagerImpl) extractTypes(file *ast.File) []interfaces.TypeInfo {
	types := make([]interfaces.TypeInfo, 0)

	ast.Inspect(file, func(n ast.Node) bool {
		switch node := n.(type) {
		case *ast.TypeSpec:
			if node.Name != nil {
				typeInfo := interfaces.TypeInfo{
					Name:       node.Name.Name,
					Package:    file.Name.Name,
					LineStart:  asm.fileSet.Position(node.Pos()).Line,
					LineEnd:    asm.fileSet.Position(node.End()).Line,
					IsExported: node.Name.IsExported(),
				}

				// Déterminer le type
				switch t := node.Type.(type) {
				case *ast.StructType:
					typeInfo.Kind = "struct"
					typeInfo.Fields = asm.extractFields(t.Fields)
				case *ast.InterfaceType:
					typeInfo.Kind = "interface"
					typeInfo.Methods = asm.extractInterfaceMethods(t.Methods)
				default:
					typeInfo.Kind = "type_alias"
				}

				types = append(types, typeInfo)
			}
		}
		return true
	})

	return types
}

func (asm *astAnalysisManagerImpl) extractVariables(file *ast.File) []interfaces.VariableInfo {
	variables := make([]interfaces.VariableInfo, 0)

	ast.Inspect(file, func(n ast.Node) bool {
		switch node := n.(type) {
		case *ast.GenDecl:
			if node.Tok == token.VAR {
				for _, spec := range node.Specs {
					if valueSpec, ok := spec.(*ast.ValueSpec); ok {
						for _, name := range valueSpec.Names {
							variable := interfaces.VariableInfo{
								Name:       name.Name,
								Package:    file.Name.Name,
								LineNumber: asm.fileSet.Position(name.Pos()).Line,
								IsExported: name.IsExported(),
							}

							if valueSpec.Type != nil {
								variable.Type = asm.typeToString(valueSpec.Type)
							}

							variables = append(variables, variable)
						}
					}
				}
			}
		}
		return true
	})

	return variables
}

func (asm *astAnalysisManagerImpl) extractConstants(file *ast.File) []interfaces.ConstantInfo {
	constants := make([]interfaces.ConstantInfo, 0)

	ast.Inspect(file, func(n ast.Node) bool {
		switch node := n.(type) {
		case *ast.GenDecl:
			if node.Tok == token.CONST {
				for _, spec := range node.Specs {
					if valueSpec, ok := spec.(*ast.ValueSpec); ok {
						for i, name := range valueSpec.Names {
							constant := interfaces.ConstantInfo{
								Name:       name.Name,
								Package:    file.Name.Name,
								LineNumber: asm.fileSet.Position(name.Pos()).Line,
								IsExported: name.IsExported(),
							}

							if valueSpec.Type != nil {
								constant.Type = asm.typeToString(valueSpec.Type)
							}

							if i < len(valueSpec.Values) && valueSpec.Values[i] != nil {
								constant.Value = asm.exprToString(valueSpec.Values[i])
							}

							constants = append(constants, constant)
						}
					}
				}
			}
		}
		return true
	})

	return constants
}

// Méthodes utilitaires
func (asm *astAnalysisManagerImpl) readFile(filePath string) ([]byte, error) {
	return os.ReadFile(filePath)
}

func (asm *astAnalysisManagerImpl) isStandardPackage(path string) bool {
	// Liste simplifiée des packages standard Go
	standardPackages := []string{
		"bufio", "bytes", "context", "crypto", "database", "encoding",
		"errors", "fmt", "go", "hash", "html", "image", "io", "log",
		"math", "net", "os", "path", "reflect", "regexp", "runtime",
		"sort", "strconv", "strings", "sync", "syscall", "testing",
		"text", "time", "unicode", "unsafe",
	}

	for _, pkg := range standardPackages {
		if strings.HasPrefix(path, pkg) {
			return true
		}
	}

	return false
}

// Méthodes non encore implémentées (placeholders)
func (asm *astAnalysisManagerImpl) TraverseFileSystem(ctx context.Context, rootPath string, filters interfaces.TraversalFilters) (*interfaces.FileSystemGraph, error) {
	return nil, fmt.Errorf("not implemented yet")
}

func (asm *astAnalysisManagerImpl) MapDependencies(ctx context.Context, filePath string) (*interfaces.DependencyGraph, error) {
	return nil, fmt.Errorf("not implemented yet")
}

func (asm *astAnalysisManagerImpl) SearchByStructure(ctx context.Context, query interfaces.StructuralQuery) ([]interfaces.StructuralResult, error) {
	return nil, fmt.Errorf("not implemented yet")
}

func (asm *astAnalysisManagerImpl) GetSimilarStructures(ctx context.Context, referenceFile string, limit int) ([]interfaces.StructuralMatch, error) {
	return nil, fmt.Errorf("not implemented yet")
}

func (asm *astAnalysisManagerImpl) GetCacheStats(ctx context.Context) (*interfaces.ASTCacheStats, error) {
	return asm.cache.GetStats(), nil
}

func (asm *astAnalysisManagerImpl) ClearCache(ctx context.Context) error {
	asm.cache.Clear()
	return nil
}

// Méthodes d'extraction détaillées (placeholders pour simplifier)
func (asm *astAnalysisManagerImpl) extractParameters(params *ast.FieldList) []interfaces.ParameterInfo {
	if params == nil {
		return nil
	}

	parameters := make([]interfaces.ParameterInfo, 0)
	for _, param := range params.List {
		paramType := asm.typeToString(param.Type)

		if len(param.Names) == 0 {
			// Paramètre anonyme
			parameters = append(parameters, interfaces.ParameterInfo{
				Type: paramType,
			})
		} else {
			for _, name := range param.Names {
				parameters = append(parameters, interfaces.ParameterInfo{
					Name: name.Name,
					Type: paramType,
				})
			}
		}
	}

	return parameters
}

func (asm *astAnalysisManagerImpl) extractReturnTypes(results *ast.FieldList) []string {
	if results == nil {
		return nil
	}

	returnTypes := make([]string, 0)
	for _, result := range results.List {
		returnTypes = append(returnTypes, asm.typeToString(result.Type))
	}

	return returnTypes
}

func (asm *astAnalysisManagerImpl) extractFields(fields *ast.FieldList) []interfaces.FieldInfo {
	if fields == nil {
		return nil
	}

	fieldInfos := make([]interfaces.FieldInfo, 0)
	for _, field := range fields.List {
		fieldType := asm.typeToString(field.Type)

		if len(field.Names) == 0 {
			// Champ embeddé
			fieldInfos = append(fieldInfos, interfaces.FieldInfo{
				Type:       fieldType,
				IsEmbedded: true,
				IsExported: true, // Les champs embeddés sont généralement exportés
			})
		} else {
			for _, name := range field.Names {
				fieldInfo := interfaces.FieldInfo{
					Name:       name.Name,
					Type:       fieldType,
					IsExported: name.IsExported(),
				}

				if field.Tag != nil {
					fieldInfo.Tag = field.Tag.Value
				}

				fieldInfos = append(fieldInfos, fieldInfo)
			}
		}
	}

	return fieldInfos
}

func (asm *astAnalysisManagerImpl) extractInterfaceMethods(methods *ast.FieldList) []interfaces.FunctionInfo {
	if methods == nil {
		return nil
	}

	methodInfos := make([]interfaces.FunctionInfo, 0)
	for _, method := range methods.List {
		if len(method.Names) > 0 {
			for _, name := range method.Names {
				if funcType, ok := method.Type.(*ast.FuncType); ok {
					methodInfo := interfaces.FunctionInfo{
						Name:        name.Name,
						IsExported:  name.IsExported(),
						Parameters:  asm.extractParameters(funcType.Params),
						ReturnTypes: asm.extractReturnTypes(funcType.Results),
					}
					methodInfo.Signature = asm.buildFunctionSignature(methodInfo)
					methodInfos = append(methodInfos, methodInfo)
				}
			}
		}
	}

	return methodInfos
}

func (asm *astAnalysisManagerImpl) extractDependencies(file *ast.File) []interfaces.DependencyRelation {
	// Placeholder - implémentation simplifiée
	deps := make([]interfaces.DependencyRelation, 0)

	for _, imp := range file.Imports {
		dep := interfaces.DependencyRelation{
			From:       file.Name.Name,
			To:         strings.Trim(imp.Path.Value, `"`),
			Type:       "import",
			LineNumber: asm.fileSet.Position(imp.Pos()).Line,
		}
		deps = append(deps, dep)
	}

	return deps
}

func (asm *astAnalysisManagerImpl) calculateComplexity(file *ast.File) interfaces.ComplexityMetrics {
	complexity := interfaces.ComplexityMetrics{
		LinesOfCode:     asm.fileSet.Position(file.End()).Line,
		FunctionCount:   len(asm.extractFunctions(file)),
		TypeCount:       len(asm.extractTypes(file)),
		DependencyCount: len(file.Imports),
	}

	// Calculer la complexité cyclomatique
	ast.Inspect(file, func(n ast.Node) bool {
		switch n.(type) {
		case *ast.IfStmt, *ast.ForStmt, *ast.RangeStmt, *ast.SwitchStmt, *ast.TypeSwitchStmt:
			complexity.CyclomaticComplexity++
		}
		return true
	})

	return complexity
}

func (asm *astAnalysisManagerImpl) calculateFunctionComplexity(funcDecl *ast.FuncDecl) int {
	complexity := 1 // Complexité de base

	ast.Inspect(funcDecl, func(n ast.Node) bool {
		switch n.(type) {
		case *ast.IfStmt, *ast.ForStmt, *ast.RangeStmt, *ast.SwitchStmt, *ast.TypeSwitchStmt:
			complexity++
		}
		return true
	})

	return complexity
}

func (asm *astAnalysisManagerImpl) buildContext(file *ast.File) map[string]interface{} {
	context := make(map[string]interface{})

	context["package"] = file.Name.Name
	context["import_count"] = len(file.Imports)
	context["has_main"] = asm.hasMainFunction(file)
	context["is_test"] = strings.HasSuffix(file.Name.Name, "_test")

	return context
}

func (asm *astAnalysisManagerImpl) calculateWorkspaceMetrics(files []interfaces.ASTAnalysisResult) interfaces.WorkspaceMetrics {
	metrics := interfaces.WorkspaceMetrics{
		TotalFiles: len(files),
	}

	totalComplexity := 0
	packages := make(map[string]bool)

	for _, file := range files {
		metrics.TotalLines += file.Complexity.LinesOfCode
		metrics.TotalFunctions += file.Complexity.FunctionCount
		metrics.TotalTypes += file.Complexity.TypeCount
		totalComplexity += file.Complexity.CyclomaticComplexity
		packages[file.Package] = true
	}

	metrics.PackageCount = len(packages)
	if metrics.TotalFunctions > 0 {
		metrics.AverageComplexity = float64(totalComplexity) / float64(metrics.TotalFunctions)
	}

	return metrics
}

func (asm *astAnalysisManagerImpl) buildFunctionSignature(function interfaces.FunctionInfo) string {
	signature := function.Name + "("

	for i, param := range function.Parameters {
		if i > 0 {
			signature += ", "
		}
		if param.Name != "" {
			signature += param.Name + " "
		}
		signature += param.Type
	}

	signature += ")"

	if len(function.ReturnTypes) > 0 {
		signature += " "
		if len(function.ReturnTypes) > 1 {
			signature += "("
		}
		for i, returnType := range function.ReturnTypes {
			if i > 0 {
				signature += ", "
			}
			signature += returnType
		}
		if len(function.ReturnTypes) > 1 {
			signature += ")"
		}
	}

	return signature
}

func (asm *astAnalysisManagerImpl) hasMainFunction(file *ast.File) bool {
	for _, decl := range file.Decls {
		if funcDecl, ok := decl.(*ast.FuncDecl); ok {
			if funcDecl.Name != nil && funcDecl.Name.Name == "main" {
				return true
			}
		}
	}
	return false
}

func (asm *astAnalysisManagerImpl) typeToString(expr ast.Expr) string {
	switch t := expr.(type) {
	case *ast.Ident:
		return t.Name
	case *ast.StarExpr:
		return "*" + asm.typeToString(t.X)
	case *ast.ArrayType:
		return "[]" + asm.typeToString(t.Elt)
	case *ast.SelectorExpr:
		return asm.typeToString(t.X) + "." + t.Sel.Name
	case *ast.MapType:
		return "map[" + asm.typeToString(t.Key) + "]" + asm.typeToString(t.Value)
	case *ast.ChanType:
		return "chan " + asm.typeToString(t.Value)
	case *ast.InterfaceType:
		return "interface{}"
	case *ast.StructType:
		return "struct{}"
	case *ast.FuncType:
		return "func"
	default:
		return "unknown"
	}
}

func (asm *astAnalysisManagerImpl) exprToString(expr ast.Expr) string {
	switch e := expr.(type) {
	case *ast.BasicLit:
		return e.Value
	case *ast.Ident:
		return e.Name
	default:
		return "complex_expression"
	}
}
