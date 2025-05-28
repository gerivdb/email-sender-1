// error_fixer_625.go - Correcteur automatique des 625 erreurs EMAIL_SENDER_1
package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
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
	CriticalFixes  []string       `json:"critical_fixes"`
	ManualRequired []string       `json:"manual_required"`
	ProcessingTime string         `json:"processing_time"`
}

func main() {
	fmt.Println("🔧 EMAIL_SENDER_1 - Correcteur automatique des 625 erreurs")
	fmt.Println("==========================================================")

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
		TotalErrors:    len(errors),
		FixesByType:    make(map[string]int),
		FixesByFile:    make(map[string]int),
		CriticalFixes:  []string{},
		ManualRequired: []string{},
	}

	// Classification et correction des erreurs
	for _, err := range errors {
		fixed := processError(err, projectRoot, report)
		if fixed {
			report.ErrorsFixed++
		} else {
			report.ErrorsSkipped++
		}
	}

	report.ProcessingTime = time.Since(start).String()

	// Générer le rapport
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

func processError(err VSCodeError, projectRoot string, report *FixReport) bool {
	// Convertir le chemin en chemin Windows absolu
	filePath := strings.ReplaceAll(err.Resource, "/d:/", "d:\\")
	filePath = strings.ReplaceAll(filePath, "/D:/", "d:\\")
	filePath = strings.ReplaceAll(filePath, "/", "\\")

	errorType := getErrorType(err)
	report.FixesByType[errorType]++

	// Skip les erreurs PowerShell pour l'instant (focus sur Go)
	if strings.HasSuffix(filePath, ".ps1") {
		return false
	}

	switch {
	case strings.Contains(err.Message, "mismatched types untyped string and untyped int"):
		return fixStringMultiplication(filePath, err, report)

	case strings.Contains(err.Message, "declared and not used"):
		return fixUnusedVariable(filePath, err, report)

	case strings.Contains(err.Message, "unused parameter"):
		return fixUnusedParameter(filePath, err, report)

	case strings.Contains(err.Message, "found packages"):
		report.ManualRequired = append(report.ManualRequired,
			fmt.Sprintf("Package conflict in %s: %s", filePath, err.Message))
		return false

	default:
		return false
	}
}

func fixStringMultiplication(filePath string, err VSCodeError, report *FixReport) bool {
	content, readErr := ioutil.ReadFile(filePath)
	if readErr != nil {
		return false
	}

	lines := strings.Split(string(content), "\n")
	if err.StartLineNumber > len(lines) {
		return false
	}

	line := lines[err.StartLineNumber-1]

	// Rechercher les patterns de multiplication de string
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
			lines[err.StartLineNumber-1] = pattern.regex.ReplaceAllString(line, pattern.replace)
			modified = true
			break
		}
	}

	if modified {
		// Ajouter l'import strings si nécessaire
		content = strings.Join(lines, "\n")
		if !strings.Contains(content, `"strings"`) && strings.Contains(content, "package main") {
			content = addStringsImport(content)
		}

		writeErr := ioutil.WriteFile(filePath, []byte(content), 0644)
		if writeErr == nil {
			report.CriticalFixes = append(report.CriticalFixes,
				fmt.Sprintf("Fixed string multiplication in %s", filePath))
			report.FixesByFile[filePath]++
			return true
		}
	}

	return false
}

func fixUnusedVariable(filePath string, err VSCodeError, report *FixReport) bool {
	content, readErr := ioutil.ReadFile(filePath)
	if readErr != nil {
		return false
	}

	lines := strings.Split(string(content), "\n")
	if err.StartLineNumber > len(lines) {
		return false
	}

	line := lines[err.StartLineNumber-1]

	// Extraire le nom de variable du message d'erreur
	varName := extractVariableName(err.Message)
	if varName == "" {
		return false
	}

	// Commenter la ligne ou utiliser _ = varName
	if strings.Contains(line, ":=") {
		// Ajouter _ = varName après la déclaration
		lines[err.StartLineNumber-1] = line
		lines = append(lines[:err.StartLineNumber],
			append([]string{fmt.Sprintf("\t_ = %s // Auto-fix: unused variable", varName)},
				lines[err.StartLineNumber:]...)...)
	} else {
		lines[err.StartLineNumber-1] = "// " + line + " // Auto-fix: unused variable"
	}

	writeErr := ioutil.WriteFile(filePath, []byte(strings.Join(lines, "\n")), 0644)
	if writeErr == nil {
		report.FixesByFile[filePath]++
		return true
	}

	return false
}

func fixUnusedParameter(filePath string, err VSCodeError, report *FixReport) bool {
	content, readErr := ioutil.ReadFile(filePath)
	if readErr != nil {
		return false
	}

	lines := strings.Split(string(content), "\n")
	if err.StartLineNumber > len(lines) {
		return false
	}

	line := lines[err.StartLineNumber-1]

	// Extraire le nom du paramètre du message d'erreur
	paramName := extractParameterName(err.Message)
	if paramName == "" {
		return false
	}

	// Remplacer le nom du paramètre par _
	updatedLine := strings.ReplaceAll(line, paramName, "_")
	lines[err.StartLineNumber-1] = updatedLine

	writeErr := ioutil.WriteFile(filePath, []byte(strings.Join(lines, "\n")), 0644)
	if writeErr == nil {
		report.FixesByFile[filePath]++
		return true
	}

	return false
}

func getErrorType(err VSCodeError) string {
	switch {
	case strings.Contains(err.Message, "mismatched types"):
		return "type_mismatch"
	case strings.Contains(err.Message, "declared and not used"):
		return "unused_variable"
	case strings.Contains(err.Message, "unused parameter"):
		return "unused_parameter"
	case strings.Contains(err.Message, "found packages"):
		return "package_conflict"
	case err.Source == "PowerShell":
		return "powershell_syntax"
	default:
		return "other"
	}
}

func extractVariableName(message string) string {
	re := regexp.MustCompile(`declared and not used: (\w+)`)
	matches := re.FindStringSubmatch(message)
	if len(matches) > 1 {
		return matches[1]
	}
	return ""
}

func extractParameterName(message string) string {
	re := regexp.MustCompile(`unused parameter: (\w+)`)
	matches := re.FindStringSubmatch(message)
	if len(matches) > 1 {
		return matches[1]
	}
	return ""
}

func addStringsImport(content string) string {
	// Ajouter l'import strings si pas déjà présent
	importIndex := strings.Index(content, "import (")
	if importIndex != -1 {
		beforeImport := content[:importIndex]
		afterImport := content[importIndex:]

		// Chercher la fin du bloc import
		closeIndex := strings.Index(afterImport, ")")
		if closeIndex != -1 {
			imports := afterImport[:closeIndex]
			rest := afterImport[closeIndex:]

			if !strings.Contains(imports, `"strings"`) {
				imports += "\t\"strings\"\n"
			}

			return beforeImport + "import (" + imports + rest
		}
	}
	return content
}

func generateReport(report *FixReport, projectRoot string) {
	reportFile := filepath.Join(projectRoot, "error_fix_report_625.json")

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
