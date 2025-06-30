package scan_non_compliant_imports

import (
	"encoding/json"
	"fmt"
	"go/parser"
	"go/token"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// NonCompliantImport represents a non-compliant import found in a Go file.
type NonCompliantImport struct {
	FilePath    string `json:"filePath"`
	ImportPath  string `json:"importPath"`
	Line        int    `json:"line"`
	Column      int    `json:"column"`
	Explanation string `json:"explanation"`
}

// ScanReport stores the results of the non-compliant imports scan.
type ScanReport struct {
	Timestamp           string               `json:"timestamp"`
	NonCompliantImports []NonCompliantImport `json:"nonCompliantImports"`
	Summary             string               `json:"summary"`
}

func main() {
	outputJSONPath := ""
	outputMDPath := ""

	args := os.Args[1:]
	for i := 0; i < len(args); i++ {
		if args[i] == "--output-json" && i+1 < len(args) {
			outputJSONPath = args[i+1]
			i++
		} else if args[i] == "--output-md" && i+1 < len(args) {
			outputMDPath = args[i+1]
			i++
		}
	}

	if outputJSONPath == "" || outputMDPath == "" {
		fmt.Println("Usage: go run scan_non_compliant_imports.go --output-json <path_to_json> --output-md <path_to_md>")
		os.Exit(1)
	}

	report, err := RunScan(outputJSONPath, outputMDPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error during scan: %v\n", err)
		os.Exit(1)
	}

	// Write JSON report
	jsonData, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error marshalling JSON: %v\n", err)
		os.Exit(1)
	}
	os.MkdirAll(filepath.Dir(outputJSONPath), 0o755)
	err = ioutil.WriteFile(outputJSONPath, jsonData, 0o644)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error writing JSON report: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("JSON report written to %s\n", outputJSONPath)

	// Write Markdown report
	mdContent := generateMarkdownReport(report)
	os.MkdirAll(filepath.Dir(outputMDPath), 0o755)
	err = ioutil.WriteFile(outputMDPath, []byte(mdContent), 0o644)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error writing Markdown report: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("Markdown report written to %s\n", outputMDPath)
}

// RunScan performs the scan for non-compliant imports.
func RunScan(outputJSONPath, outputMDPath string) (ScanReport, error) {
	report := ScanReport{
		Timestamp: time.Now().Format("2006-01-02_15-04-05"),
	}

	rootPath, err := os.Getwd()
	if err != nil {
		return report, fmt.Errorf("error getting current working directory: %w", err)
	}

	fset := token.NewFileSet()
	err = filepath.Walk(rootPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() && (strings.HasPrefix(info.Name(), ".") || strings.HasPrefix(info.Name(), "vendor")) && path != rootPath {
			return filepath.SkipDir
		}
		if !info.IsDir() && strings.HasSuffix(info.Name(), ".go") {
			content, err := ioutil.ReadFile(path)
			if err != nil {
				return err
			}
			node, err := parser.ParseFile(fset, path, content, parser.ImportsOnly)
			if err != nil {
				return err
			}

			for _, imp := range node.Imports {
				importPath := strings.Trim(imp.Path.Value, `"`)
				// Check for non-compliant internal imports
				// Convention: email_sender/core/... for internal modules
				// We assume email_sender is the root module name.
				isInternal := strings.HasPrefix(importPath, "email_sender/")
				isCoreInternal := strings.HasPrefix(importPath, "email_sender/core/")

				// A non-compliant internal import is one that starts with "email_sender/" but NOT "email_sender/core/"
				// Or any relative import (e.g., "./", "../")
				if (isInternal && !isCoreInternal) || strings.HasPrefix(importPath, "./") || strings.HasPrefix(importPath, "../") {
					position := fset.Position(imp.Pos())
					report.NonCompliantImports = append(report.NonCompliantImports, NonCompliantImport{
						FilePath:    filepath.ToSlash(filepath.Clean(path)),
						ImportPath:  importPath,
						Line:        position.Line,
						Column:      position.Column,
						Explanation: "Internal import does not follow 'email_sender/core/...' convention or is a relative import.",
					})
				}
			}
		}
		return nil
	})
	if err != nil {
		return report, fmt.Errorf("error walking the path %q: %w", rootPath, err)
	}

	report.Summary = fmt.Sprintf("Scan completed. Found %d non-compliant imports.", len(report.NonCompliantImports))
	return report, nil
}

func generateMarkdownReport(report ScanReport) string {
	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("# Non-Compliant Imports Scan Report - %s\n\n", report.Timestamp))
	sb.WriteString(fmt.Sprintf("## Summary\n\n%s\n\n", report.Summary))

	if len(report.NonCompliantImports) > 0 {
		sb.WriteString("## Details of Non-Compliant Imports\n\n")
		for _, imp := range report.NonCompliantImports {
			sb.WriteString(fmt.Sprintf("- **File**: `%s`\n", imp.FilePath))
			sb.WriteString(fmt.Sprintf("  - **Import**: `%s`\n", imp.ImportPath))
			sb.WriteString(fmt.Sprintf("  - **Location**: Line %d, Column %d\n", imp.Line, imp.Column))
			sb.WriteString(fmt.Sprintf("  - **Explanation**: %s\n", imp.Explanation))
			sb.WriteString("\n")
		}
	} else {
		sb.WriteString("No non-compliant imports found. Great job!\n\n")
	}

	return sb.String()
}
