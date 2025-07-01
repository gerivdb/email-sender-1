// File: email_sender_error_classifier.go
// EMAIL_SENDER_1 Error Triage & Classification Algorithm
// Automatically classifies 400+ errors into 5-10 root causes

package error_triage

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"regexp"
	"strings"
)

type EmailSenderComponent int

const (
	RAGEngine	EmailSenderComponent	= iota
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

type EmailSenderErrorClass struct {
	Type		string			`json:"type"`
	Pattern		string			`json:"pattern"`
	Severity	int			`json:"severity"`	// 1=critical, 2=high, 3=medium, 4=low
	AutoFix		bool			`json:"autoFix"`
	Component	EmailSenderComponent	`json:"component"`
	regex		*regexp.Regexp
}

type ClassificationResult struct {
	Component	EmailSenderComponent	`json:"component"`
	ErrorTypes	[]ErrorTypeResult	`json:"errorTypes"`
	Priority	int			`json:"priority"`
	TotalCount	int			`json:"totalCount"`
}

type ErrorTypeResult struct {
	Type	string		`json:"type"`
	Errors	[]string	`json:"errors"`
	AutoFix	bool		`json:"autoFix"`
	Count	int		`json:"count"`
}

var EmailSenderErrorClasses = []EmailSenderErrorClass{
	// Critical RAG Engine errors (Priority 1)
	{Type: "RAG_IMPORT_MISSING", Pattern: `cannot find package.*qdrant|vector|embedding`, Severity: 1, AutoFix: true, Component: RAGEngine},
	{Type: "RAG_TYPE_ERROR", Pattern: `cannot use .* as .* in.*vector|embedding`, Severity: 1, AutoFix: false, Component: RAGEngine},
	{Type: "RAG_UNDEFINED_VAR", Pattern: `undefined:.*vector|qdrant|embedding`, Severity: 2, AutoFix: false, Component: RAGEngine},

	// Critical Configuration errors (Priority 1)
	{Type: "CONFIG_MISSING", Pattern: `config.*missing|yaml.*syntax|json.*syntax`, Severity: 1, AutoFix: true, Component: ConfigFiles},
	{Type: "ENV_VAR_MISSING", Pattern: `environment variable.*not set|NOTION_API_KEY|GMAIL_CREDENTIALS`, Severity: 1, AutoFix: false, Component: ConfigFiles},

	// High Priority N8N Workflow errors (Priority 2)
	{Type: "N8N_WORKFLOW_ERROR", Pattern: `workflow.*undefined|missing node|n8n.*error`, Severity: 1, AutoFix: false, Component: N8NWorkflow},
	{Type: "N8N_NODE_ERROR", Pattern: `node.*not found|invalid node type`, Severity: 2, AutoFix: false, Component: N8NWorkflow},

	// High Priority API errors (Priority 2)
	{Type: "NOTION_API_ERROR", Pattern: `notion.*unauthorized|api.*error|notion.*invalid`, Severity: 2, AutoFix: false, Component: NotionAPI},
	{Type: "GMAIL_API_ERROR", Pattern: `gmail.*oauth|credential.*error|gmail.*unauthorized`, Severity: 2, AutoFix: false, Component: GmailProcessing},

	// Medium Priority PowerShell errors (Priority 3)
	{Type: "POWERSHELL_SYNTAX_ERROR", Pattern: `powershell.*syntax|PowerShell.*error`, Severity: 3, AutoFix: true, Component: PowerShellScript},
	{Type: "POWERSHELL_UNDEFINED_VAR", Pattern: `undefined variable.*powershell|variable.*not defined`, Severity: 3, AutoFix: true, Component: PowerShellScript},

	// General Go errors
	{Type: "GO_UNDEFINED_VAR", Pattern: `undefined:`, Severity: 2, AutoFix: false, Component: RAGEngine},
	{Type: "GO_TYPE_MISMATCH", Pattern: `cannot use .* as .* in`, Severity: 2, AutoFix: false, Component: RAGEngine},
	{Type: "GO_UNUSED_VAR", Pattern: `declared and not used`, Severity: 4, AutoFix: true, Component: RAGEngine},
	{Type: "GO_IMPORT_ERROR", Pattern: `cannot find package`, Severity: 1, AutoFix: true, Component: RAGEngine},
}

func init() {
	// Compile regex patterns
	for i := range EmailSenderErrorClasses {
		EmailSenderErrorClasses[i].regex = regexp.MustCompile(EmailSenderErrorClasses[i].Pattern)
	}
}

func ClassifyEmailSenderErrors(buildOutput string) []ClassificationResult {
	classified := make(map[EmailSenderComponent]map[string][]string)

	lines := strings.Split(buildOutput, "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}

		for _, class := range EmailSenderErrorClasses {
			if class.regex.MatchString(line) {
				if classified[class.Component] == nil {
					classified[class.Component] = make(map[string][]string)
				}
				classified[class.Component][class.Type] = append(classified[class.Component][class.Type], line)
				break
			}
		}
	}

	// Convert to structured result
	var results []ClassificationResult
	componentPriorities := map[EmailSenderComponent]int{
		RAGEngine:		1,	// Core - Fixes often 100+ errors at once
		ConfigFiles:		1,	// Infrastructure - Blocks everything
		N8NWorkflow:		2,	// Critical orchestration
		NotionAPI:		2,	// Data persistence
		GmailProcessing:	3,	// Email handling
		PowerShellScript:	4,	// Automation - non-blocking
	}

	for component, errorMap := range classified {
		var errorTypes []ErrorTypeResult
		totalCount := 0

		for errorType, errors := range errorMap {
			// Find corresponding error class for autoFix info
			var autoFix bool
			for _, class := range EmailSenderErrorClasses {
				if class.Type == errorType {
					autoFix = class.AutoFix
					break
				}
			}

			errorTypes = append(errorTypes, ErrorTypeResult{
				Type:		errorType,
				Errors:		errors,
				AutoFix:	autoFix,
				Count:		len(errors),
			})
			totalCount += len(errors)
		}

		results = append(results, ClassificationResult{
			Component:	component,
			ErrorTypes:	errorTypes,
			Priority:	componentPriorities[component],
			TotalCount:	totalCount,
		})
	}

	return results
}

func main() {
	if len(os.Args) < 2 {
		log.Fatal("Usage: go run email_sender_error_classifier.go <build_output_file>")
	}

	inputFile := os.Args[1]
	var buildOutput string

	if inputFile == "-" {
		// Read from stdin
		scanner := bufio.NewScanner(os.Stdin)
		var lines []string
		for scanner.Scan() {
			lines = append(lines, scanner.Text())
		}
		buildOutput = strings.Join(lines, "\n")
	} else {
		// Read from file
		content, err := os.ReadFile(inputFile)
		if err != nil {
			log.Fatalf("Error reading file: %v", err)
		}
		buildOutput = string(content)
	}

	results := ClassifyEmailSenderErrors(buildOutput)

	// Output JSON for PowerShell consumption
	jsonOutput, err := json.MarshalIndent(results, "", "  ")
	if err != nil {
		log.Fatalf("Error marshaling JSON: %v", err)
	}

	fmt.Println(string(jsonOutput))
}
