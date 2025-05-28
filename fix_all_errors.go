// fix_all_errors.go - Master script to fix all errors
package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

type VSCodeError struct {
	Resource        string      `json:"resource"`
	Owner           string      `json:"owner"`
	Code            interface{} `json:"code"`
	Severity        int         `json:"severity"`
	Message         string      `json:"message"`
	Source          string      `json:"source"`
	StartLineNumber int         `json:"startLineNumber"`
	StartColumn     int         `json:"startColumn"`
	EndLineNumber   int         `json:"endLineNumber"`
	EndColumn       int         `json:"endColumn"`
}

type FixReport struct {
	TotalErrors    int            `json:"total_errors"`
	ErrorsFixed    int            `json:"errors_fixed"`
	ErrorsSkipped  int            `json:"errors_skipped"`
	FixesByType    map[string]int `json:"fixes_by_type"`
	FixesByFile    map[string]int `json:"fixes_by_file"`
	ProcessingTime string         `json:"processing_time"`
}

func main() {
	fmt.Println("🔧 EMAIL_SENDER_1 - Correcteur automatique de toutes les erreurs")
	fmt.Println("===========================================================")

	start := time.Now()

	projectRoot := "d:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1"
	errorFile := filepath.Join(projectRoot, "2025-05-28-errors.md")

	// Lire le fichier d'erreurs
	errors, err := parseErrorFile(errorFile)
	if err != nil {
		log.Fatalf("❌ Erreur lecture fichier: %v", err)
	}

	fmt.Printf("📊 Analysé %d erreurs dans le fichier\n", len(errors))

	report := &FixReport{
		TotalErrors: len(errors),
		FixesByType: make(map[string]int),
		FixesByFile: make(map[string]int),
	}

	// Fix PowerShell syntax errors (replace Generate- verbs with New-)
	fmt.Println("\n🔧 Phase 1: Correction des erreurs de syntaxe PowerShell...")
	fixPowerShellSyntaxErrors()

	// Fix package conflicts
	fmt.Println("\n🔧 Phase 2: Correction des conflits de packages...")
	fixPackageConflicts()

	// Fix unused imports
	fmt.Println("\n🔧 Phase 3: Correction des imports non utilisés...")
	fixUnusedImports(errors, report)

	// Fix string type issues
	fmt.Println("\n🔧 Phase 4: Correction des problèmes de type de chaînes...")
	fixStringTypeMismatch(errors, report)

	// Fix unused variables
	fmt.Println("\n🔧 Phase 5: Correction des variables non utilisées...")
	fixUnusedVariables(errors, report)

	// Run go mod tidy to clean up dependencies
	fmt.Println("\n🔧 Phase 6: Nettoyage des dépendances avec 'go mod tidy'...")
	cmd := exec.Command("go", "mod", "tidy")
	cmd.Dir = projectRoot
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Run()

	// Generate report
	report.ProcessingTime = time.Since(start).String()
	generateReport(report, projectRoot)

	fmt.Printf("\n✅ Traitement terminé en %s\n", report.ProcessingTime)
	fmt.Printf("🔧 Erreurs corrigées: %d/%d (%.1f%%)\n",
		report.ErrorsFixed, report.TotalErrors,
		float64(report.ErrorsFixed)/float64(report.TotalErrors)*100)
}

func parseErrorFile(filename string) ([]VSCodeError, error) {
	content, err := ioutil.ReadFile(filename)
	if err != nil {
		return nil, err
	}

	// Extraire le JSON des erreurs du fichier markdown
	jsonStart := strings.Index(string(content), "[{")
	jsonEnd := strings.LastIndex(string(content), "}]")

	if jsonStart == -1 || jsonEnd == -1 {
		return nil, fmt.Errorf("format JSON non trouvé dans le fichier")
	}

	jsonData := string(content)[jsonStart : jsonEnd+2]

	var errors []VSCodeError
	err = json.Unmarshal([]byte(jsonData), &errors)
	if err != nil {
		return nil, fmt.Errorf("erreur parsing JSON: %v", err)
	}

	return errors, nil
}

func fixPowerShellSyntaxErrors() {
	// Replace Generate- verbs with New-
	fixCommands := []struct {
		oldVerb string
		newVerb string
	}{
		{"Generate-ComponentRecommendations", "New-ComponentRecommendations"},
		{"Generate-FixActions", "New-FixActions"},
		{"Generate-DependencyReport", "New-DependencyReport"},
		{"Analyze-CircularDependencies", "Test-CircularDependencies"},
	}

	psFilePath := "d:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\.github\\docs\\algorithms\\dependency-analysis\\Find-EmailSenderCircularDependencies.ps1"
	
	for _, cmd := range fixCommands {
		content, err := ioutil.ReadFile(psFilePath)
		if err != nil {
			fmt.Printf("❌ Erreur lecture fichier PowerShell: %v\n", err)
			continue
		}

		newContent := strings.ReplaceAll(string(content), cmd.oldVerb, cmd.newVerb)
		
		err = ioutil.WriteFile(psFilePath, []byte(newContent), 0644)
		if err != nil {
			fmt.Printf("❌ Erreur écriture fichier PowerShell: %v\n", err)
			continue
		}
		
		fmt.Printf("✅ Remplacé %s par %s\n", cmd.oldVerb, cmd.newVerb)
	}
}

func fixPackageConflicts() {
	// Move files from test_main.go to package test
	testDir := "d:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\.github\\docs\\algorithms\\test"
	
	// Ensure test directory exists
	os.MkdirAll(testDir, 0755)
	
	// Update package names in test directory
	files, _ := ioutil.ReadDir(testDir)
	for _, file := range files {
		if strings.HasSuffix(file.Name(), ".go") {
			filePath := filepath.Join(testDir, file.Name())
			content, err := ioutil.ReadFile(filePath)
			if err != nil {
				continue
			}
			
			// Replace package declaration
			lines := strings.Split(string(content), "\n")
			for i, line := range lines {
				if strings.HasPrefix(line, "package ") {
					lines[i] = "package test"
					break
				}
			}
			
			newContent := strings.Join(lines, "\n")
			ioutil.WriteFile(filePath, []byte(newContent), 0644)
			fmt.Printf("✅ Mis à jour %s pour utiliser 'package test'\n", file.Name())
		}
	}
	
	// Fix debug_cache_test.go
	cacheTestPath := "d:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\debug_cache_test.go"
	if _, err := os.Stat(cacheTestPath); err == nil {
		content, _ := ioutil.ReadFile(cacheTestPath)
		newContent := strings.Replace(string(content), 
			"func main() {", 
			"func RunCacheDebugTest() {", 1)
		ioutil.WriteFile(cacheTestPath, []byte(newContent), 0644)
		fmt.Printf("✅ Renommé main() en RunCacheDebugTest() dans debug_cache_test.go\n")
	}
}

func fixUnusedImports(errors []VSCodeError, report *FixReport) {
	// Filter only unused import errors
	unusedImportErrors := []VSCodeError{}
	for _, err := range errors {
		if strings.Contains(err.Message, "imported and not used") {
			unusedImportErrors = append(unusedImportErrors, err)
		}
	}
	
	fmt.Printf("📊 Trouvé %d erreurs d'imports non utilisés\n", len(unusedImportErrors))
	
	// Group errors by file
	fileErrors := make(map[string][]VSCodeError)
	for _, err := range unusedImportErrors {
		filePath := normalizePath(err.Resource)
		if _, exists := fileErrors[filePath]; !exists {
			fileErrors[filePath] = []VSCodeError{}
		}
		fileErrors[filePath] = append(fileErrors[filePath], err)
	}
	
	// Fix each file
	fixedFiles := 0
	for filePath, errs := range fileErrors {
		fixed := handleUnusedImports(filePath, errs, report)
		if fixed {
			fixedFiles++
		}
	}
	
	fmt.Printf("✅ Imports corrigés: %d/%d fichiers\n", fixedFiles, len(fileErrors))
}

func fixStringTypeMismatch(errors []VSCodeError, report *FixReport) {
	// Filter string type errors
	stringErrors := []VSCodeError{}
	for _, err := range errors {
		if strings.Contains(err.Message, "mismatched types") &&
		   strings.Contains(err.Message, "string") {
			stringErrors = append(stringErrors, err)
		}
	}
	
	fmt.Printf("📊 Trouvé %d erreurs de types de chaînes\n", len(stringErrors))
	
	// Group errors by file
	fileErrors := make(map[string][]VSCodeError)
	for _, err := range stringErrors {
		filePath := normalizePath(err.Resource)
		if _, exists := fileErrors[filePath]; !exists {
			fileErrors[filePath] = []VSCodeError{}
		}
		fileErrors[filePath] = append(fileErrors[filePath], err)
	}
	
	// Fix each file
	fixedFiles := 0
	for filePath, errs := range fileErrors {
		for _, err := range errs {
			fixed := handleStringTypeMismatch(filePath, err, report)
			if fixed {
				fixedFiles++
			}
		}
	}
	
	fmt.Printf("✅ Problèmes de type corrigés: %d/%d\n", fixedFiles, len(stringErrors))
}

func fixUnusedVariables(errors []VSCodeError, report *FixReport) {
	// Filter unused variable errors
	unusedVarErrors := []VSCodeError{}
	for _, err := range errors {
		if strings.Contains(err.Message, "declared and not used") ||
		   strings.Contains(err.Message, "unused parameter") {
			unusedVarErrors = append(unusedVarErrors, err)
		}
	}
	
	fmt.Printf("📊 Trouvé %d erreurs de variables non utilisées\n", len(unusedVarErrors))
	
	// Group errors by file
	fileErrors := make(map[string][]VSCodeError)
	for _, err := range unusedVarErrors {
		filePath := normalizePath(err.Resource)
		if _, exists := fileErrors[filePath]; !exists {
			fileErrors[filePath] = []VSCodeError{}
		}
		fileErrors[filePath] = append(fileErrors[filePath], err)
	}
	
	// Fix each file
	fixedFiles := 0
	for filePath, errs := range fileErrors {
		for _, err := range errs {
			fixed := handleUnusedVariable(filePath, err, report)
			if fixed {
				fixedFiles++
			}
		}
	}
	
	fmt.Printf("✅ Variables inutilisées corrigées: %d/%d\n", fixedFiles, len(unusedVarErrors))
}

func handleUnusedImports(filePath string, errors []VSCodeError, report *FixReport) bool {
	fmt.Printf("🔧 Correction imports dans %s (%d erreurs)\n", filePath, len(errors))
	
	content, err := ioutil.ReadFile(filePath)
	if err != nil {
		fmt.Printf("❌ Erreur lecture fichier: %v\n", err)
		return false
	}
	
	lines := strings.Split(string(content), "\n")
	
	// Extract import names from error messages
	importsToComment := make(map[string]bool)
	for _, err := range errors {
		re := regexp.MustCompile(`"([^"]+)" imported and not used`)
		match := re.FindStringSubmatch(err.Message)
		if len(match) > 1 {
			importsToComment[match[1]] = true
		}
	}
	
	// Look for import block or single import statements
	inImportBlock := false
	for i, line := range lines {
		trimmedLine := strings.TrimSpace(line)
		
		// Start of import block
		if trimmedLine == "import (" {
			inImportBlock = true
			continue
		}
		
		// End of import block
		if inImportBlock && trimmedLine == ")" {
			inImportBlock = false
			continue
		}
		
		// Check single import line
		if strings.HasPrefix(trimmedLine, "import \"") {
			re := regexp.MustCompile(`import "([^"]+)"`)
			match := re.FindStringSubmatch(trimmedLine)
			if len(match) > 1 && importsToComment[match[1]] {
				lines[i] = "// " + line + " // Auto-fix: unused import"
				report.ErrorsFixed++
				report.FixesByType["unused_import"]++
				report.FixesByFile[filePath]++
			}
			continue
		}
		
		// Check imports in block
		if inImportBlock && trimmedLine != "" && !strings.HasPrefix(trimmedLine, "//") {
			re := regexp.MustCompile(`"([^"]+)"`)
			match := re.FindStringSubmatch(trimmedLine)
			if len(match) > 1 && importsToComment[match[1]] {
				// Comment out this import
				lines[i] = "\t// " + trimmedLine + " // Auto-fix: unused import"
				report.ErrorsFixed++
				report.FixesByType["unused_import"]++
				report.FixesByFile[filePath]++
			}
		}
	}
	
	// Write the modified content back
	err = ioutil.WriteFile(filePath, []byte(strings.Join(lines, "\n")), 0644)
	if err != nil {
		fmt.Printf("❌ Erreur écriture fichier: %v\n", err)
		return false
	}
	
	return true
}

func handleStringTypeMismatch(filePath string, err VSCodeError, report *FixReport) bool {
	content, readErr := ioutil.ReadFile(filePath)
	if readErr != nil {
		return false
	}
	
	lines := strings.Split(string(content), "\n")
	if err.StartLineNumber > len(lines) || err.StartLineNumber <= 0 {
		return false
	}
	
	lineIdx := err.StartLineNumber - 1
	line := lines[lineIdx]
	
	// Check for common string multiplication patterns
	patterns := []struct {
		regex   *regexp.Regexp
		replace string
	}{
		{regexp.MustCompile(`"=" \* (\d+)`), `strings.Repeat("=", $1)`},
		{regexp.MustCompile(`"-" \* (\d+)`), `strings.Repeat("-", $1)`},
		{regexp.MustCompile(`"\*" \* (\d+)`), `strings.Repeat("*", $1)`},
		{regexp.MustCompile(`" " \* (\d+)`), `strings.Repeat(" ", $1)`},
	}
	
	modified := false
	for _, pattern := range patterns {
		if pattern.regex.MatchString(line) {
			lines[lineIdx] = pattern.regex.ReplaceAllString(line, pattern.replace)
			modified = true
			
			// Add strings import if needed
			if !strings.Contains(string(content), `"strings"`) && 
			   strings.Contains(string(content), "package") {
				// Find package statement
				for i, pkgLine := range lines {
					if strings.HasPrefix(strings.TrimSpace(pkgLine), "package ") {
						// Find import statements
						for j := i + 1; j < len(lines); j++ {
							if strings.Contains(lines[j], "import (") {
								// Already has import block, add to it
								for k := j + 1; k < len(lines); k++ {
									if strings.Contains(lines[k], ")") {
										lines = append(lines[:k], 
												append([]string{"\t\"strings\""},
													lines[k:]...)...)
										break
									}
								}
								break
							} else if strings.HasPrefix(strings.TrimSpace(lines[j]), "import ") {
								// Has single import, replace with block
								importLine := lines[j]
								lines[j] = "import ("
								lines = append(lines[:j+1], 
										append([]string{importLine, "\t\"strings\"", ")"},
											lines[j+1:]...)...)
								break
							} else if !strings.HasPrefix(strings.TrimSpace(lines[j]), "//") && 
									  strings.TrimSpace(lines[j]) != "" {
								// No import yet, add one
								lines = append(lines[:j], 
										append([]string{"import (", "\t\"strings\"", ")"}, 
											lines[j:]...)...)
								break
							}
						}
						break
					}
				}
			}
			break
		}
	}
	
	if modified {
		writeErr := ioutil.WriteFile(filePath, []byte(strings.Join(lines, "\n")), 0644)
		if writeErr == nil {
			report.ErrorsFixed++
			report.FixesByType["string_type_mismatch"]++
			report.FixesByFile[filePath]++
			return true
		}
	}
	
	return false
}

func handleUnusedVariable(filePath string, err VSCodeError, report *FixReport) bool {
	content, readErr := ioutil.ReadFile(filePath)
	if readErr != nil {
		return false
	}
	
	lines := strings.Split(string(content), "\n")
	if err.StartLineNumber > len(lines) || err.StartLineNumber <= 0 {
		return false
	}
	
	lineIdx := err.StartLineNumber - 1
	line := lines[lineIdx]
	
	if strings.Contains(err.Message, "declared and not used") {
		// Extract variable name
		re := regexp.MustCompile(`declared and not used: (\w+)`)
		match := re.FindStringSubmatch(err.Message)
		if len(match) > 1 {
			varName := match[1]
			
			if strings.Contains(line, ":=") {
				// Add _ = varName after declaration
				lines = append(lines[:lineIdx+1], 
						append([]string{fmt.Sprintf("\t_ = %s // Auto-fix: unused variable", varName)}, 
							lines[lineIdx+1:]...)...)
			} else {
				// Comment out the line
				lines[lineIdx] = "// " + line + " // Auto-fix: unused variable"
			}
			
			writeErr := ioutil.WriteFile(filePath, []byte(strings.Join(lines, "\n")), 0644)
			if writeErr == nil {
				report.ErrorsFixed++
				report.FixesByType["unused_variable"]++
				report.FixesByFile[filePath]++
				return true
			}
		}
	} else if strings.Contains(err.Message, "unused parameter") {
		// Extract parameter name
		re := regexp.MustCompile(`unused parameter: (\w+)`)
		match := re.FindStringSubmatch(err.Message)
		if len(match) > 1 {
			paramName := match[1]
			
			// Replace parameter with _
			newLine := strings.Replace(line, paramName, "_", -1)
			lines[lineIdx] = newLine
			
			writeErr := ioutil.WriteFile(filePath, []byte(strings.Join(lines, "\n")), 0644)
			if writeErr == nil {
				report.ErrorsFixed++
				report.FixesByType["unused_parameter"]++
				report.FixesByFile[filePath]++
				return true
			}
		}
	}
	
	return false
}

func normalizePath(path string) string {
	// Convert URI path to Windows path
	path = strings.ReplaceAll(path, "/d:/", "d:\\")
	path = strings.ReplaceAll(path, "/D:/", "d:\\")
	path = strings.ReplaceAll(path, "/", "\\")
	return path
}

func generateReport(report *FixReport, projectRoot string) {
	reportFile := filepath.Join(projectRoot, "all_errors_fix_report.json")

	data, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		log.Printf("❌ Erreur génération rapport: %v", err)
		return
	}

	err = ioutil.WriteFile(reportFile, data, 0644)
	if err != nil {
		log.Printf("❌ Erreur écriture rapport: %v", err)
		return
	}

	fmt.Printf("📋 Rapport généré: %s\n", reportFile)
}
