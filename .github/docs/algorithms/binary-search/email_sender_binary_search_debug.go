// File: email_sender_binary_search_debug.go
// EMAIL_SENDER_1 Binary Search Debug Algorithm
// Systematically isolates failing components using binary search approach

package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

type EmailSenderComponent int

const (
	RAGEngine EmailSenderComponent = iota
	N8NWorkflow
	NotionAPI
	GmailProcessing
	PowerShellScript
	ConfigFiles
)

func (c EmailSenderComponent) String() string {
	return [...]string{
		"RAGEngine",
		"N8NWorkflow",
		"NotionAPI",
		"GmailProcessing",
		"PowerShellScript",
		"ConfigFiles",
	}[c]
}

type IsolationResult struct {
	Component       EmailSenderComponent `json:"component"`
	FailingPackages []string             `json:"failingPackages"`
	WorkingPackages []string             `json:"workingPackages"`
	ErrorCount      int                  `json:"errorCount"`
	HealthScore     float64              `json:"healthScore"`
	Priority        int                  `json:"priority"`
}

type ComponentPackages struct {
	Component EmailSenderComponent
	Packages  []string
	Priority  int
}

func getEmailSenderPackages() []ComponentPackages {
	return []ComponentPackages{
		{
			Component: RAGEngine,
			Packages:  []string{"./src/rag", "./internal/engine", "./src/indexing", "./src/cache", "./src/types"},
			Priority:  1,
		},
		{
			Component: ConfigFiles,
			Packages:  []string{"./configs", "./docker-compose.yml", "./.github/workflows", "./package.json", "./go.mod"},
			Priority:  1,
		},
		{
			Component: N8NWorkflow,
			Packages:  []string{"./workflows", "./src/automation"},
			Priority:  2,
		},
		{
			Component: NotionAPI,
			Packages:  []string{"./src/notion", "./src/database"},
			Priority:  2,
		},
		{
			Component: GmailProcessing,
			Packages:  []string{"./src/gmail", "./src/email"},
			Priority:  3,
		},
		{
			Component: PowerShellScript,
			Packages:  []string{"./scripts", "./automation"},
			Priority:  4,
		},
	}
}

func hasEmailSenderCompilationErrors(packages []string, component EmailSenderComponent) (bool, int) {
	errorCount := 0
	hasErrors := false

	for _, pkg := range packages {
		var cmd *exec.Cmd

		// Check if package/file exists
		if _, err := os.Stat(pkg); os.IsNotExist(err) {
			continue
		}

		// Validation specialized by EMAIL_SENDER_1 component
		switch component {
		case RAGEngine:
			cmd = exec.Command("go", "build", pkg)
		case N8NWorkflow:
			if strings.HasSuffix(pkg, ".json") {
				// Validate JSON workflow files
				cmd = exec.Command("node", "-e", fmt.Sprintf("JSON.parse(require('fs').readFileSync('%s', 'utf8'))", pkg))
			} else {
				// Try to build Go automation code
				cmd = exec.Command("go", "build", pkg)
			}
		case PowerShellScript:
			if strings.HasSuffix(pkg, ".ps1") {
				// Basic PowerShell syntax check
				cmd = exec.Command("pwsh", "-Command", fmt.Sprintf("Get-Content '%s' | Out-Null", pkg))
			} else {
				// Directory check
				cmd = exec.Command("pwsh", "-Command", fmt.Sprintf("Get-ChildItem '%s' -Filter '*.ps1' | Out-Null", pkg))
			}
		case ConfigFiles:
			if strings.Contains(pkg, ".yml") || strings.Contains(pkg, ".yaml") {
				// YAML validation
				cmd = exec.Command("python", "-c", fmt.Sprintf("import yaml; yaml.safe_load(open('%s'))", pkg))
			} else if strings.Contains(pkg, ".json") {
				// JSON validation
				cmd = exec.Command("python", "-c", fmt.Sprintf("import json; json.load(open('%s'))", pkg))
			} else if strings.Contains(pkg, "go.mod") {
				// Go module validation
				cmd = exec.Command("go", "mod", "verify")
				cmd.Dir = filepath.Dir(pkg)
			} else {
				// Directory or other files
				cmd = exec.Command("test", "-e", pkg)
			}
		case NotionAPI, GmailProcessing:
			cmd = exec.Command("go", "build", pkg)
		default:
			cmd = exec.Command("go", "build", pkg)
		}

		if cmd != nil {
			output, err := cmd.CombinedOutput()
			if err != nil {
				hasErrors = true
				// Count lines of error output as rough error count
				errorLines := strings.Split(string(output), "\n")
				for _, line := range errorLines {
					if strings.TrimSpace(line) != "" {
						errorCount++
					}
				}
			}
		}
	}

	return hasErrors, errorCount
}

func isolateFailingEmailSenderPackages(projectRoot string) []IsolationResult {
	emailSenderPackages := getEmailSenderPackages()
	var results []IsolationResult

	for _, componentPkg := range emailSenderPackages {
		fmt.Printf("🔧 Analyzing EMAIL_SENDER_1 Component: %s\n", componentPkg.Component)

		packages := componentPkg.Packages
		var componentFailing []string
		var componentWorking []string
		totalErrors := 0

		// Check each package individually first
		for _, pkg := range packages {
			hasErrors, errorCount := hasEmailSenderCompilationErrors([]string{pkg}, componentPkg.Component)
			if hasErrors {
				componentFailing = append(componentFailing, pkg)
				totalErrors += errorCount
				fmt.Printf("  ❌ %s: %d errors\n", pkg, errorCount)
			} else {
				componentWorking = append(componentWorking, pkg)
				fmt.Printf("  ✅ %s: OK\n", pkg)
			}
		}

		// Binary search approach for packages with errors
		if len(componentFailing) > 1 {
			fmt.Printf("  🔍 Binary search analysis for %d failing packages...\n", len(componentFailing))
			componentFailing = binarySearchFailingPackages(componentFailing, componentPkg.Component)
		}

		// Calculate health score
		totalPackages := len(componentFailing) + len(componentWorking)
		var healthScore float64 = 100
		if totalPackages > 0 {
			healthScore = float64(len(componentWorking)) / float64(totalPackages) * 100
		}

		result := IsolationResult{
			Component:       componentPkg.Component,
			FailingPackages: componentFailing,
			WorkingPackages: componentWorking,
			ErrorCount:      totalErrors,
			HealthScore:     healthScore,
			Priority:        componentPkg.Priority,
		}

		results = append(results, result)
	}

	return results
}

func binarySearchFailingPackages(packages []string, component EmailSenderComponent) []string {
	if len(packages) <= 1 {
		return packages
	}

	var finalFailing []string
	remaining := packages

	for len(remaining) > 1 {
		mid := len(remaining) / 2
		leftHalf := remaining[:mid]
		rightHalf := remaining[mid:]

		// Test left half
		leftHasErrors, _ := hasEmailSenderCompilationErrors(leftHalf, component)
		rightHasErrors, _ := hasEmailSenderCompilationErrors(rightHalf, component)

		if leftHasErrors && !rightHasErrors {
			remaining = leftHalf
		} else if !leftHasErrors && rightHasErrors {
			remaining = rightHalf
		} else if leftHasErrors && rightHasErrors {
			// Both halves have errors, need to process both
			finalFailing = append(finalFailing, binarySearchFailingPackages(leftHalf, component)...)
			remaining = rightHalf
		} else {
			// No errors in isolation - might be inter-package dependency issue
			finalFailing = append(finalFailing, remaining...)
			break
		}

		if len(remaining) == 1 {
			finalFailing = append(finalFailing, remaining[0])
			break
		}
	}

	return finalFailing
}

func main() {
	projectRoot := "."
	if len(os.Args) > 1 {
		projectRoot = os.Args[1]
	}

	fmt.Println("🎯 EMAIL_SENDER_1 Binary Search Debug - Isolating Failing Components")
	fmt.Printf("📂 Project: %s\n\n", projectRoot)

	results := isolateFailingEmailSenderPackages(projectRoot)

	// Output JSON for PowerShell consumption
	jsonOutput, err := json.MarshalIndent(results, "", "  ")
	if err != nil {
		log.Fatalf("Error marshaling JSON: %v", err)
	}

	fmt.Println(string(jsonOutput))
}
