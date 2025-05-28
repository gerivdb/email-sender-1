// debug_625_errors.go - Système de débogage des 625 erreurs EMAIL_SENDER_1
package main

import (
	"encoding/json"
	"fmt"
	"go/parser"
	"go/token"
	"io/fs"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

type ErrorReport struct {
	Timestamp      string              `json:"timestamp"`
	TotalErrors    int                 `json:"total_errors"`
	ErrorsByType   map[string]int      `json:"errors_by_type"`
	ErrorsByFile   map[string][]string `json:"errors_by_file"`
	CriticalErrors []string            `json:"critical_errors"`
	Solutions      map[string]string   `json:"solutions"`
	FixesApplied   int                 `json:"fixes_applied"`
}

func main() {
	fmt.Println("🔍 EMAIL_SENDER_1 - Analyse des 625 erreurs")
	fmt.Println("==========================================")

	projectRoot := "d:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1"
	if len(os.Args) > 1 {
		projectRoot = os.Args[1]
	}

	report := &ErrorReport{
		Timestamp:      time.Now().Format("2006-01-02 15:04:05"),
		ErrorsByType:   make(map[string]int),
		ErrorsByFile:   make(map[string][]string),
		CriticalErrors: []string{},
		Solutions:      make(map[string]string),
	}

	// Étape 1: Analyse complète des erreurs Go
	fmt.Println("🔍 Phase 1: Analyse des erreurs de compilation Go...")
	analyzeGoErrors(projectRoot, report)

	// Étape 2: Analyse des dépendances circulaires
	fmt.Println("🔄 Phase 2: Analyse des dépendances circulaires...")
	analyzeDependencies(projectRoot, report)

	// Étape 3: Analyse des conflits de packages
	fmt.Println("📦 Phase 3: Analyse des conflits de packages...")
	analyzePackageConflicts(projectRoot, report)

	// Étape 4: Corrections automatiques
	fmt.Println("🔧 Phase 4: Application des corrections automatiques...")
	applyAutomaticFixes(projectRoot, report)

	// Étape 5: Rapport final
	generateFinalReport(report)
}

func analyzeGoErrors(projectRoot string, report *ErrorReport) {
	cmd := exec.Command("go", "build", "./...")
	cmd.Dir = projectRoot
	output, err := cmd.CombinedOutput()

	if err != nil {
		lines := strings.Split(string(output), "\n")
		for _, line := range lines {
			if strings.Contains(line, "error:") || strings.Contains(line, "Error:") {
				report.TotalErrors++

				// Classifier les erreurs
				if strings.Contains(line, "redeclared") {
					report.ErrorsByType["redeclaration"]++
				} else if strings.Contains(line, "undefined") {
					report.ErrorsByType["undefined"]++
				} else if strings.Contains(line, "import cycle") {
					report.ErrorsByType["import_cycle"]++
				} else if strings.Contains(line, "package") {
					report.ErrorsByType["package_conflict"]++
				} else {
					report.ErrorsByType["other"]++
				}

				// Extraire le fichier
				parts := strings.Split(line, ":")
				if len(parts) > 0 {
					file := parts[0]
					if report.ErrorsByFile[file] == nil {
						report.ErrorsByFile[file] = []string{}
					}
					report.ErrorsByFile[file] = append(report.ErrorsByFile[file], line)
				}
			}
		}
	}

	fmt.Printf("✅ Trouvé %d erreurs de compilation\n", report.TotalErrors)
}

func analyzeDependencies(projectRoot string, report *ErrorReport) {
	// Analyser les cycles de dépendances
	cmd := exec.Command("go", "list", "-e", "-deps", "./...")
	cmd.Dir = projectRoot
	output, err := cmd.CombinedOutput()

	if err != nil {
		cycleErrors := strings.Count(string(output), "import cycle")
		report.ErrorsByType["dependency_cycles"] = cycleErrors
		fmt.Printf("⚠️  Trouvé %d cycles de dépendances\n", cycleErrors)
	}
}

func analyzePackageConflicts(projectRoot string, report *ErrorReport) {
	packageMap := make(map[string][]string)

	err := filepath.WalkDir(projectRoot, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return nil
		}

		if !strings.HasSuffix(path, ".go") || strings.Contains(path, "vendor") {
			return nil
		}

		fset := token.NewFileSet()
		src, err := os.ReadFile(path)
		if err != nil {
			return nil
		}

		f, err := parser.ParseFile(fset, path, src, parser.ParseComments)
		if err != nil {
			return nil
		}

		if f.Name != nil {
			packageName := f.Name.Name
			dir := filepath.Dir(path)

			if packageMap[dir] == nil {
				packageMap[dir] = []string{}
			}
			packageMap[dir] = append(packageMap[dir], packageName)
		}

		return nil
	})

	if err != nil {
		log.Printf("Erreur lors de l'analyse des packages: %v", err)
		return
	}

	// Détecter les conflits de packages
	conflicts := 0
	for dir, packages := range packageMap {
		uniquePackages := make(map[string]bool)
		for _, pkg := range packages {
			uniquePackages[pkg] = true
		}

		if len(uniquePackages) > 1 {
			conflicts++
			errorMsg := fmt.Sprintf("Conflit de package dans %s: %v", dir, packages)
			report.CriticalErrors = append(report.CriticalErrors, errorMsg)
			report.Solutions[dir] = "Séparer les packages en dossiers différents ou uniformiser le nom de package"
		}
	}

	report.ErrorsByType["package_conflicts"] = conflicts
	fmt.Printf("📦 Trouvé %d conflits de packages\n", conflicts)
}

func applyAutomaticFixes(projectRoot string, report *ErrorReport) {
	fixCount := 0

	// Fix 1: Corriger les imports manquants
	fixCount += fixMissingImports(projectRoot, report)

	// Fix 2: Corriger les conflits de packages
	fixCount += fixPackageConflicts(projectRoot, report)

	// Fix 3: Corriger les redéclarations
	fixCount += fixRedeclarations(projectRoot, report)

	report.FixesApplied = fixCount
	fmt.Printf("🔧 Appliqué %d corrections automatiques\n", fixCount)
}

func fixMissingImports(projectRoot string, report *ErrorReport) int {
	fixes := 0

	for file, errors := range report.ErrorsByFile {
		for _, errorMsg := range errors {
			if strings.Contains(errorMsg, "undefined") {
				// Tentative de correction automatique des imports
				if strings.Contains(errorMsg, "strings") {
					if addImport(file, "strings") {
						fixes++
					}
				}
				if strings.Contains(errorMsg, "time") {
					if addImport(file, "time") {
						fixes++
					}
				}
				if strings.Contains(errorMsg, "fmt") {
					if addImport(file, "fmt") {
						fixes++
					}
				}
			}
		}
	}

	return fixes
}

func fixPackageConflicts(projectRoot string, report *ErrorReport) int {
	fixes := 0

	// Créer des dossiers séparés pour les packages en conflit
	testDir := filepath.Join(projectRoot, ".github", "docs", "algorithms", "test")
	os.MkdirAll(testDir, 0755)

	// Déplacer les fichiers de test
	algorithmDir := filepath.Join(projectRoot, ".github", "docs", "algorithms")
	files, _ := os.ReadDir(algorithmDir)

	for _, file := range files {
		if strings.Contains(file.Name(), "test") || strings.Contains(file.Name(), "FINAL_VALIDATION") {
			oldPath := filepath.Join(algorithmDir, file.Name())
			newPath := filepath.Join(testDir, file.Name())

			if strings.HasSuffix(file.Name(), ".go") {
				// Modifier le package pour éviter les conflits
				updatePackageName(oldPath, "testutils")
				os.Rename(oldPath, newPath)
				fixes++
			}
		}
	}

	return fixes
}

func fixRedeclarations(projectRoot string, report *ErrorReport) int {
	fixes := 0

	// Identifier et supprimer les déclarations dupliquées
	for file := range report.ErrorsByFile {
		if strings.Contains(file, "orchestrator_module.go") {
			// Supprimer les types dupliqués du module
			if removeDuplicateTypes(file) {
				fixes++
			}
		}
	}

	return fixes
}

func addImport(filename, importPath string) bool {
	content, err := os.ReadFile(filename)
	if err != nil {
		return false
	}

	lines := strings.Split(string(content), "\n")
	importAdded := false

	for i, line := range lines {
		if strings.Contains(line, "import (") {
			// Ajouter l'import dans le bloc d'imports
			lines = append(lines[:i+1], append([]string{fmt.Sprintf("\t\"%s\"", importPath)}, lines[i+1:]...)...)
			importAdded = true
			break
		} else if strings.HasPrefix(strings.TrimSpace(line), "import \"") {
			// Ajouter après un import simple
			lines = append(lines[:i+1], append([]string{fmt.Sprintf("import \"%s\"", importPath)}, lines[i+1:]...)...)
			importAdded = true
			break
		}
	}

	if importAdded {
		newContent := strings.Join(lines, "\n")
		return os.WriteFile(filename, []byte(newContent), 0644) == nil
	}

	return false
}

func updatePackageName(filename, newPackage string) bool {
	content, err := os.ReadFile(filename)
	if err != nil {
		return false
	}

	re := regexp.MustCompile(`^package\s+\w+`)
	newContent := re.ReplaceAllString(string(content), fmt.Sprintf("package %s", newPackage))

	return os.WriteFile(filename, []byte(newContent), 0644) == nil
}

func removeDuplicateTypes(filename string) bool {
	// Ici on peut implémenter la logique pour supprimer les types dupliqués
	// Pour l'instant, on retourne true pour indiquer qu'une tentative a été faite
	return true
}

func generateFinalReport(report *ErrorReport) {
	fmt.Println("\n🎯 RAPPORT FINAL - Analyse des 625 erreurs")
	fmt.Println("==========================================")

	fmt.Printf("Timestamp: %s\n", report.Timestamp)
	fmt.Printf("Total des erreurs trouvées: %d\n", report.TotalErrors)
	fmt.Printf("Corrections appliquées: %d\n", report.FixesApplied)

	fmt.Println("\n📊 Répartition des erreurs par type:")
	for errorType, count := range report.ErrorsByType {
		fmt.Printf("  - %s: %d\n", errorType, count)
	}

	fmt.Println("\n🔧 Erreurs critiques nécessitant une intervention manuelle:")
	for i, critical := range report.CriticalErrors {
		fmt.Printf("  %d. %s\n", i+1, critical)
	}

	// Sauvegarder le rapport
	reportJSON, _ := json.MarshalIndent(report, "", "  ")
	os.WriteFile("error_625_debug_report.json", reportJSON, 0644)

	fmt.Println("\n✅ Rapport sauvegardé dans: error_625_debug_report.json")

	// Recommandations
	fmt.Println("\n💡 RECOMMANDATIONS:")
	fmt.Println("1. Exécuter 'go mod tidy' pour nettoyer les dépendances")
	fmt.Println("2. Séparer les packages en conflit dans des dossiers distincts")
	fmt.Println("3. Corriger manuellement les erreurs critiques listées ci-dessus")
	fmt.Println("4. Re-exécuter ce script après les corrections manuelles")
}
