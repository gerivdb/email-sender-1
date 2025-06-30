package audit_modules

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// GoModInfo stores information about a go.mod file
type GoModInfo struct {
	Path         string   `json:"path"`
	ModuleName   string   `json:"moduleName,omitempty"`
	GoVersion    string   `json:"goVersion,omitempty"`
	Dependencies []string `json:"dependencies,omitempty"`
}

// AuditReport stores the overall audit results
type AuditReport struct {
	Timestamp            string      `json:"timestamp"`
	GoModFiles           []GoModInfo `json:"goModFiles"`
	GoSumFiles           []string    `json:"goSumFiles"`
	Summary              string      `json:"summary"`
	NonConformantModules []string    `json:"nonConformantModules,omitempty"`
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
		fmt.Println("Usage: go run audit_modules.go --output-json <path_to_json> --output-md <path_to_md>")
		os.Exit(1)
	}

	err := RunAudit(outputJSONPath, outputMDPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error during audit: %v\n", err)
		os.Exit(1)
	}
}

// RunAudit performs the audit and generates reports.
func RunAudit(outputJSONPath, outputMDPath string) error {
	report := AuditReport{
		Timestamp: time.Now().Format("2006-01-02_15-04-05"),
	}

	rootPath, err := os.Getwd()
	if err != nil {
		return fmt.Errorf("error getting current working directory: %w", err)
	}

	err = filepath.Walk(rootPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() && (strings.HasPrefix(info.Name(), ".") || strings.HasPrefix(info.Name(), "vendor")) && path != rootPath {
			return filepath.SkipDir
		}

		if info.Name() == "go.mod" {
			relPath, _ := filepath.Rel(rootPath, path)
			goMod := GoModInfo{Path: relPath}
			content, err := ioutil.ReadFile(path)
			if err == nil {
				lines := strings.Split(string(content), "\n")
				for _, line := range lines {
					if strings.HasPrefix(line, "module ") {
						goMod.ModuleName = strings.TrimSpace(strings.TrimPrefix(line, "module "))
					} else if strings.HasPrefix(line, "go ") {
						goMod.GoVersion = strings.TrimSpace(strings.TrimPrefix(line, "go "))
					} else if strings.HasPrefix(line, "require ") {
						parts := strings.Fields(line)
						if len(parts) >= 2 {
							goMod.Dependencies = append(goMod.Dependencies, parts[1])
						}
					}
				}
			}
			report.GoModFiles = append(report.GoModFiles, goMod)
		} else if info.Name() == "go.sum" {
			relPath, _ := filepath.Rel(rootPath, path)
			report.GoSumFiles = append(report.GoSumFiles, relPath)
		}
		return nil
	})
	if err != nil {
		return fmt.Errorf("error walking the path %q: %w", rootPath, err)
	}

	// Identify non-conformant modules (not email_sender/core/...)
	for _, gm := range report.GoModFiles {
		if gm.ModuleName != "" && !strings.HasPrefix(gm.ModuleName, "email_sender/core/") && gm.Path != "go.mod" {
			report.NonConformantModules = append(report.NonConformantModules, gm.ModuleName)
		}
	}

	report.Summary = fmt.Sprintf("Audit completed. Found %d go.mod files and %d go.sum files.",
		len(report.GoModFiles), len(report.GoSumFiles))

	// Ensure output directories exist
	os.MkdirAll(filepath.Dir(outputJSONPath), 0o755)
	os.MkdirAll(filepath.Dir(outputMDPath), 0o755)

	// Write JSON report
	jsonData, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return fmt.Errorf("error marshalling JSON: %w", err)
	}
	err = ioutil.WriteFile(outputJSONPath, jsonData, 0o644)
	if err != nil {
		return fmt.Errorf("error writing JSON report: %w", err)
	}
	fmt.Printf("JSON report written to %s\n", outputJSONPath)

	// Write Markdown report
	mdContent := generateMarkdownReport(report)
	err = ioutil.WriteFile(outputMDPath, []byte(mdContent), 0o644)
	if err != nil {
		return fmt.Errorf("error writing Markdown report: %w", err)
	}
	fmt.Printf("Markdown report written to %s\n", outputMDPath)
	return nil
}

func generateMarkdownReport(report AuditReport) string {
	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("# Audit Report - %s\n\n", report.Timestamp))
	sb.WriteString(fmt.Sprintf("## Summary\n\n%s\n\n", report.Summary))

	if len(report.GoModFiles) > 0 {
		sb.WriteString("## go.mod Files Found\n\n")
		for _, gm := range report.GoModFiles {
			sb.WriteString(fmt.Sprintf("- **Path**: `%s`\n", gm.Path))
			if gm.ModuleName != "" {
				sb.WriteString(fmt.Sprintf("  - **Module Name**: `%s`\n", gm.ModuleName))
			}
			if gm.GoVersion != "" {
				sb.WriteString(fmt.Sprintf("  - **Go Version**: `%s`\n", gm.GoVersion))
			}
			if len(gm.Dependencies) > 0 {
				sb.WriteString("  - **Dependencies (first few)**:\n")
				for i, dep := range gm.Dependencies {
					if i >= 3 { // Limit to first 3 dependencies for brevity in MD
						break
					}
					sb.WriteString(fmt.Sprintf("    - `%s`\n", dep))
				}
				if len(gm.Dependencies) > 3 {
					sb.WriteString("    - ...\n")
				}
			}
			sb.WriteString("\n")
		}
	}

	if len(report.GoSumFiles) > 0 {
		sb.WriteString("## go.sum Files Found\n\n")
		for _, gs := range report.GoSumFiles {
			sb.WriteString(fmt.Sprintf("- `%s`\n", gs))
		}
		sb.WriteString("\n")
	}

	if len(report.NonConformantModules) > 0 {
		sb.WriteString("## Non-Conformant Modules (expected 'email_sender/core/...' or root go.mod)\n\n")
		for _, ncm := range report.NonConformantModules {
			sb.WriteString(fmt.Sprintf("- `%s`\n", ncm))
		}
		sb.WriteString("\n")
	}

	return sb.String()
}
