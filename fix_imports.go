// fix_imports.go - Correcteur automatique pour les imports non utilisés
package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"path/filepath"
	"regexp"
	"strings"
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

func main() {
	fmt.Println("🔧 EMAIL_SENDER_1 - Correcteur d'imports non utilisés")
	fmt.Println("===================================================")

	projectRoot := "d:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1"
	errorFile := filepath.Join(projectRoot, "2025-05-28-errors.md")

	// Lire le fichier d'erreurs
	errors, err := parseErrorFile(errorFile)
	if err != nil {
		log.Fatalf("❌ Erreur lecture fichier: %v", err)
	}

	// Filtrer uniquement les erreurs "imported and not used"
	unusedImportErrors := filterUnusedImports(errors)
	fmt.Printf("📊 Trouvé %d erreurs d'imports non utilisés\n", len(unusedImportErrors))

	// Organiser les erreurs par fichier
	fileErrors := groupByFile(unusedImportErrors)

	// Corriger chaque fichier
	fixedFiles := 0
	for filePath, errs := range fileErrors {
		fixed := fixUnusedImports(filePath, errs)
		if fixed {
			fixedFiles++
		}
	}

	fmt.Printf("✅ Correction terminée: %d/%d fichiers corrigés\n", fixedFiles, len(fileErrors))
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

func filterUnusedImports(errors []VSCodeError) []VSCodeError {
	var unusedImports []VSCodeError
	for _, err := range errors {
		if strings.Contains(err.Message, "imported and not used") {
			unusedImports = append(unusedImports, err)
		}
	}
	return unusedImports
}

func groupByFile(errors []VSCodeError) map[string][]VSCodeError {
	fileErrors := make(map[string][]VSCodeError)
	for _, err := range errors {
		// Convertir le chemin en chemin Windows absolu
		filePath := strings.ReplaceAll(err.Resource, "/d:/", "d:\\")
		filePath = strings.ReplaceAll(filePath, "/D:/", "d:\\")
		filePath = strings.ReplaceAll(filePath, "/", "\\")

		if _, exists := fileErrors[filePath]; !exists {
			fileErrors[filePath] = []VSCodeError{}
		}
		fileErrors[filePath] = append(fileErrors[filePath], err)
	}
	return fileErrors
}

func fixUnusedImports(filePath string, errors []VSCodeError) bool {
	fmt.Printf("🔧 Correction de %s (%d erreurs)\n", filePath, len(errors))

	content, err := ioutil.ReadFile(filePath)
	if err != nil {
		fmt.Printf("❌ Erreur lecture fichier: %v\n", err)
		return false
	}

	lines := strings.Split(string(content), "\n")

	// Identifier la zone d'imports
	importStartLine := -1
	importEndLine := -1
	for i, line := range lines {
		if strings.TrimSpace(line) == "import (" {
			importStartLine = i
		}
		if importStartLine != -1 && strings.TrimSpace(line) == ")" {
			importEndLine = i
			break
		}
	}

	if importStartLine == -1 || importEndLine == -1 {
		fmt.Printf("❌ Zone d'imports non trouvée\n")
		return false
	}

	// Collecter les imports à supprimer
	importsToFix := make(map[string]bool)
	for _, err := range errors {
		// Extraire le nom du package
		re := regexp.MustCompile(`"([^"]+)" imported and not used`)
		match := re.FindStringSubmatch(err.Message)
		if len(match) > 1 {
			importsToFix[match[1]] = true
		}
	}

	// Modifier les imports
	newImports := []string{lines[importStartLine]}
	for i := importStartLine + 1; i < importEndLine; i++ {
		line := strings.TrimSpace(lines[i])
		
		// Skip empty lines
		if line == "" {
			newImports = append(newImports, lines[i])
			continue
		}

		// Check if this is an import we need to fix
		re := regexp.MustCompile(`"([^"]+)"`)
		match := re.FindStringSubmatch(line)
		if len(match) > 1 {
			pkg := match[1]
			if importsToFix[pkg] {
				// Comment out the unused import
				newImports = append(newImports, strings.Replace(lines[i], fmt.Sprintf("\"%s\"", pkg), fmt.Sprintf("\"%s\" // Unused import", pkg), 1))
				fmt.Printf("    ✅ Commenté import: %s\n", pkg)
			} else {
				newImports = append(newImports, lines[i])
			}
		} else {
			newImports = append(newImports, lines[i])
		}
	}
	newImports = append(newImports, lines[importEndLine])

	// Reconstruire le contenu du fichier
	newContent := append(
		lines[:importStartLine],
		append(newImports, lines[importEndLine+1:]...)...,
	)

	// Écrire le fichier modifié
	err = ioutil.WriteFile(filePath, []byte(strings.Join(newContent, "\n")), 0644)
	if err != nil {
		fmt.Printf("❌ Erreur écriture fichier: %v\n", err)
		return false
	}

	return true
}
