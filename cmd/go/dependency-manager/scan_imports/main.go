// scan_imports.go
//
// Scanne tous les fichiers .go du monorepo pour recenser les imports internes (hors stdlib et externes).
// Génère un rapport JSON et un rapport Markdown listant les fichiers et leurs imports internes.

package scan_imports

import (
	"encoding/json"
	"flag"
	"fmt"
	"go/parser"
	"go/token"
	"io/ioutil"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

// FileImports represents the imports found in a single Go file.
type FileImports struct {
	File    string   `json:"file"`
	Imports []string `json:"imports"`
}

// ScanReport summarizes the imports found across files.
type ScanReport struct {
	Timestamp   string                 `json:"timestamp"`
	FileImports map[string]FileImports `json:"file_imports"`
	Summary     string                 `json:"summary"`
}

var internalPattern = regexp.MustCompile(`^email_sender/core/`)

func main() {
	outputJSON := flag.String("output-json", "list_internal_imports.json", "Chemin du rapport JSON")
	outputMD := flag.String("output-md", "report_internal_imports.md", "Chemin du rapport Markdown")
	rootDir := flag.String("root", ".", "Racine du monorepo à scanner")
	flag.Parse()

	if *outputJSON == "" || *outputMD == "" {
		fmt.Fprintln(os.Stderr, "Usage: --output-json <file> --output-md <file>")
		os.Exit(1)
	}

	report, err := RunScan(*rootDir, *outputJSON, *outputMD)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error during scan: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Scan terminé. Rapports générés: %s, %s\n", *outputJSON, *outputMD)
	fmt.Println(report.Summary)
}

// RunScan scans Go files for internal imports and generates reports.
func RunScan(rootDir, outputJSONPath, outputMDPath string) (ScanReport, error) {
	report := ScanReport{
		Timestamp:   time.Now().Format("2006-01-02_15-04-05"),
		FileImports: make(map[string]FileImports),
	}

	// Use provided rootDir or current working directory if not provided
	scanRoot := rootDir
	if scanRoot == "" || scanRoot == "." {
		var err error
		scanRoot, err = os.Getwd()
		if err != nil {
			return report, fmt.Errorf("error getting current working directory: %w", err)
		}
	}

	fset := token.NewFileSet()
	err := filepath.Walk(scanRoot, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() && (strings.HasPrefix(info.Name(), ".") || strings.HasPrefix(info.Name(), "vendor")) && path != scanRoot {
			return filepath.SkipDir
		}
		if !info.IsDir() && strings.HasSuffix(info.Name(), ".go") {
			imports, err := scanFile(path, fset)
			if err != nil {
				return fmt.Errorf("error scanning file %s: %w", path, err)
			}
			if len(imports) > 0 {
				relPath, _ := filepath.Rel(scanRoot, path)
				report.FileImports[filepath.ToSlash(filepath.Clean(relPath))] = FileImports{File: filepath.ToSlash(filepath.Clean(relPath)), Imports: imports}
			}
		}
		return nil
	})
	if err != nil {
		return report, fmt.Errorf("error walking files in %q: %w", scanRoot, err)
	}

	report.Summary = fmt.Sprintf("Scan completed. Found imports in %d files.", len(report.FileImports))

	// Ensure output directories exist
	os.MkdirAll(filepath.Dir(outputJSONPath), 0o755)
	os.MkdirAll(filepath.Dir(outputMDPath), 0o755)

	// Write JSON report
	jsonData, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return report, fmt.Errorf("error marshalling JSON: %w", err)
	}
	err = ioutil.WriteFile(outputJSONPath, jsonData, 0o644)
	if err != nil {
		return report, fmt.Errorf("error writing JSON report: %w", err)
	}

	// Write Markdown report
	mdContent := generateMarkdownReport(report)
	err = ioutil.WriteFile(outputMDPath, []byte(mdContent), 0o644)
	if err != nil {
		return report, fmt.Errorf("error writing Markdown report: %w", err)
	}

	return report, nil
}

func scanFile(path string, fset *token.FileSet) ([]string, error) {
	var imports []string
	node, err := parser.ParseFile(fset, path, nil, parser.ImportsOnly)
	if err != nil {
		return imports, err
	}
	for _, imp := range node.Imports {
		val := strings.Trim(imp.Path.Value, `"`)
		if isInternal(val) {
			imports = append(imports, val)
		}
	}
	return imports, nil
}

// isInternal returns true if the import is internal to the project (excluding stdlib and external).
func isInternal(pkg string) bool {
	// Add more complex logic here if needed to filter out stdlib or known external packages.
	// For now, it checks if it matches "email_sender/core/" pattern.
	return internalPattern.MatchString(pkg)
}

func generateMarkdownReport(report ScanReport) string {
	var sb strings.Builder
	sb.WriteString("# Imports internes Go détectés\n\n")
	if len(report.FileImports) == 0 {
		sb.WriteString("Aucun import interne détecté.\n")
	} else {
		for _, fi := range report.FileImports {
			sb.WriteString(fmt.Sprintf("## %s\n", fi.File))
			for _, imp := range fi.Imports {
				sb.WriteString(fmt.Sprintf("- `%s`\n", imp))
			}
			sb.WriteString("\n")
		}
	}
	return sb.String()
}
