package main

import (
	"bufio"
	"flag"
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

// ManagerInfo structure pour stocker les infos d'un manager
type ManagerInfo struct {
	Name    string
	Methods []MethodInfo
}

type MethodInfo struct {
	Name    string
	Params  []string
	Results []string
}

// Parse les fichiers Go pour extraire les méthodes publiques d'une struct
func extractManagerMethods(filePath, structName string) ([]MethodInfo, error) {
	fset := token.NewFileSet()
	file, err := parser.ParseFile(fset, filePath, nil, parser.AllErrors)
	if err != nil {
		return nil, err
	}
	var methods []MethodInfo
	for _, decl := range file.Decls {
		if fn, ok := decl.(*ast.FuncDecl); ok && fn.Recv != nil && fn.Name.IsExported() {
			recv := fn.Recv.List[0].Type
			starExpr, isStar := recv.(*ast.StarExpr)
			var recvName string
			if isStar {
				if ident, ok := starExpr.X.(*ast.Ident); ok {
					recvName = ident.Name
				}
			} else if ident, ok := recv.(*ast.Ident); ok {
				recvName = ident.Name
			}
			if recvName == structName {
				params := []string{}
				for _, p := range fn.Type.Params.List {
					for _, n := range p.Names {
						typeStr := exprToString(p.Type)
						params = append(params, fmt.Sprintf("%s %s", n.Name, typeStr))
					}
				}
				results := []string{}
				if fn.Type.Results != nil {
					for _, r := range fn.Type.Results.List {
						typeStr := exprToString(r.Type)
						if len(r.Names) > 0 {
							for _, n := range r.Names {
								results = append(results, fmt.Sprintf("%s %s", n.Name, typeStr))
							}
						} else {
							results = append(results, typeStr)
						}
					}
				}
				methods = append(methods, MethodInfo{
					Name:    fn.Name.Name,
					Params:  params,
					Results: results,
				})
			}
		}
	}
	return methods, nil
}

func exprToString(expr ast.Expr) string {
	switch t := expr.(type) {
	case *ast.Ident:
		return t.Name
	case *ast.StarExpr:
		return "*" + exprToString(t.X)
	case *ast.SelectorExpr:
		return exprToString(t.X) + "." + t.Sel.Name
	case *ast.ArrayType:
		return "[]" + exprToString(t.Elt)
	case *ast.MapType:
		return fmt.Sprintf("map[%s]%s", exprToString(t.Key), exprToString(t.Value))
	case *ast.InterfaceType:
		return "interface{}"
	case *ast.FuncType:
		return "func"
	case *ast.ChanType:
		return "chan " + exprToString(t.Value)
	default:
		return "unknown"
	}
}

// Extrait la liste brute des managers depuis AGENTS.md
func extractManagerListFromMarkdown(mdPath string) ([]string, error) {
	file, err := os.Open(mdPath)
	if err != nil {
		return nil, err
	}
	defer file.Close()
	var managers []string
	scanner := bufio.NewScanner(file)
	inList := false
	re := regexp.MustCompile(`^[-*] +([A-Za-z0-9_]+Manager)\b`)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.Contains(line, "Liste brute des managers") {
			inList = true
			continue
		}
		if inList {
			if strings.TrimSpace(line) == "" || strings.HasPrefix(line, "#") || strings.HasPrefix(line, "---") {
				break
			}
			if m := re.FindStringSubmatch(line); m != nil {
				managers = append(managers, m[1])
			}
		}
	}
	return managers, nil
}

// Recherche tous les fichiers Go contenant un type struct ou interface dont le nom contient le nom du manager
func findAllManagerTypeFiles(root, managerName string) ([]struct {
	FilePath string
	TypeName string
	TypeKind string // "struct" ou "interface"
}, error,
) {
	var found []struct {
		FilePath string
		TypeName string
		TypeKind string
	}
	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil || info.IsDir() || !strings.HasSuffix(path, ".go") {
			return nil
		}
		fset := token.NewFileSet()
		file, err := parser.ParseFile(fset, path, nil, parser.AllErrors)
		if err != nil {
			return nil
		}
		for _, decl := range file.Decls {
			if gen, ok := decl.(*ast.GenDecl); ok && gen.Tok == token.TYPE {
				for _, spec := range gen.Specs {
					if ts, ok := spec.(*ast.TypeSpec); ok {
						typeName := ts.Name.Name
						if strings.Contains(typeName, managerName) {
							switch ts.Type.(type) {
							case *ast.StructType:
								found = append(found, struct {
									FilePath string
									TypeName string
									TypeKind string
								}{path, typeName, "struct"})
							case *ast.InterfaceType:
								found = append(found, struct {
									FilePath string
									TypeName string
									TypeKind string
								}{path, typeName, "interface"})
							}
						}
					}
				}
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return found, nil
}

// Extrait les méthodes publiques d'une interface
func extractManagerInterfaceMethods(filePath, interfaceName string) ([]MethodInfo, error) {
	fset := token.NewFileSet()
	file, err := parser.ParseFile(fset, filePath, nil, parser.AllErrors)
	if err != nil {
		return nil, err
	}
	var methods []MethodInfo
	for _, decl := range file.Decls {
		if gen, ok := decl.(*ast.GenDecl); ok && gen.Tok == token.TYPE {
			for _, spec := range gen.Specs {
				if ts, ok := spec.(*ast.TypeSpec); ok && ts.Name.Name == interfaceName {
					if iface, ok := ts.Type.(*ast.InterfaceType); ok {
						for _, m := range iface.Methods.List {
							if len(m.Names) == 0 {
								continue
							}
							name := m.Names[0].Name
							if !ast.IsExported(name) {
								continue
							}
							params := []string{}
							results := []string{}
							if ft, ok := m.Type.(*ast.FuncType); ok {
								if ft.Params != nil {
									for _, p := range ft.Params.List {
										typeStr := exprToString(p.Type)
										for _, n := range p.Names {
											params = append(params, fmt.Sprintf("%s %s", n.Name, typeStr))
										}
										if len(p.Names) == 0 {
											params = append(params, typeStr)
										}
									}
								}
								if ft.Results != nil {
									for _, r := range ft.Results.List {
										typeStr := exprToString(r.Type)
										if len(r.Names) > 0 {
											for _, n := range r.Names {
												results = append(results, fmt.Sprintf("%s %s", n.Name, typeStr))
											}
										} else {
											results = append(results, typeStr)
										}
									}
								}
							}
							methods = append(methods, MethodInfo{
								Name:    name,
								Params:  params,
								Results: results,
							})
						}
					}
				}
			}
		}
	}
	return methods, nil
}

func main() {
	var dryRun bool
	var agentsPathFlag string
	flag.BoolVar(&dryRun, "dry-run", false, "Générer la documentation dans un fichier temporaire sans modifier AGENTS.md")
	flag.StringVar(&agentsPathFlag, "agents-path", "", "Chemin personnalisé vers AGENTS.md")
	flag.Parse()

	var agentsPath string
	if agentsPathFlag != "" {
		agentsPath = agentsPathFlag
	} else {
		agentsPath = filepath.Join("..", "..", "..", "AGENTS.md")
	}
	fmt.Printf("[INFO] Chemin AGENTS.md utilisé : %s\n", agentsPath)

	root := filepath.Dir(agentsPath)
	managers, err := extractManagerListFromMarkdown(agentsPath)
	if err != nil {
		fmt.Println("Erreur lecture AGENTS.md:", err)
		return
	}

	// Génère la map managerName -> ioSummaryString
	ioSummaries := make(map[string]string)
	for _, name := range managers {
		allTypes, findErr := findAllManagerTypeFiles(root, name)
		if findErr != nil || len(allTypes) == 0 {
			ioSummaries[name] = "_Non trouvé dans le code source_"
			continue
		}
		methodSet := make(map[string]MethodInfo)
		for _, t := range allTypes {
			var methods []MethodInfo
			var extractErr error
			switch t.TypeKind {
			case "struct":
				methods, extractErr = extractManagerMethods(t.FilePath, t.TypeName)
			case "interface":
				methods, extractErr = extractManagerInterfaceMethods(t.FilePath, t.TypeName)
			}
			if extractErr != nil {
				continue
			}
			for _, m := range methods {
				methodSet[m.Name+strings.Join(m.Params, ",")+strings.Join(m.Results, ",")] = m
			}
		}
		if len(methodSet) == 0 {
			ioSummaries[name] = "_Aucune méthode publique trouvée_"
			continue
		}
		var b strings.Builder
		b.WriteString("\n")
		for _, m := range methodSet {
			b.WriteString(fmt.Sprintf("- `%s(%s)`", m.Name, strings.Join(m.Params, ", ")))
			if len(m.Results) > 0 {
				b.WriteString(fmt.Sprintf(" → (%s)", strings.Join(m.Results, ", ")))
			}
			b.WriteString("\n")
		}
		ioSummaries[name] = b.String()
	}

	// Lecture et réécriture ligne à ligne
	input, err := os.Open(agentsPath)
	if err != nil {
		fmt.Println("Erreur lecture AGENTS.md:", err)
		return
	}
	defer input.Close()

	var outputLines []string
	scanner := bufio.NewScanner(input)
	var currentManager string
	reManager := regexp.MustCompile(`^### +([A-Za-z0-9_]+Manager)`)
	for scanner.Scan() {
		line := scanner.Text()
		if m := reManager.FindStringSubmatch(line); m != nil {
			currentManager = m[1]
			outputLines = append(outputLines, line)
			continue
		}
		if strings.HasPrefix(line, "**Entrée/Sortie :**") && currentManager != "" {
			// Remplacement ciblé
			if summary, ok := ioSummaries[currentManager]; ok {
				outputLines = append(outputLines, "**Entrée/Sortie :**"+summary)
			} else {
				outputLines = append(outputLines, line)
			}
			continue
		}
		outputLines = append(outputLines, line)
	}
	err = scanner.Err()
	if err != nil {
		fmt.Println("Erreur lecture AGENTS.md:", err)
		return
	}

	// Backup
	backupPath := agentsPath + ".bak"
	err = os.WriteFile(backupPath, []byte(strings.Join(outputLines, "\n")), 0o644)
	if err != nil {
		fmt.Println("Erreur backup AGENTS.md.bak:", err)
		return
	}

	// Write result
	if dryRun {
		dryPath := filepath.Join(filepath.Dir(agentsPath), "dryrun_agents_doc.md")
		err = os.WriteFile(dryPath, []byte(strings.Join(outputLines, "\n")), 0o644)
		if err != nil {
			fmt.Println("Erreur écriture dryrun_agents_doc.md:", err)
			return
		}
		fmt.Println("[DRY-RUN] Documentation générée dans dryrun_agents_doc.md (aucune modification de AGENTS.md)")
		return
	}
	err = os.WriteFile(agentsPath, []byte(strings.Join(outputLines, "\n")), 0o644)
	if err != nil {
		fmt.Println("Erreur écriture AGENTS.md:", err)
		return
	}
	fmt.Println("Documentation Entrée/Sortie mise à jour dans AGENTS.md ! (backup: AGENTS.md.bak)")
}
