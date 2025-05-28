// File: .github/docs/algorithms/auto-fix/email_sender_auto_fixer.go
// EMAIL_SENDER_1 Auto-Fix Pattern Matching Algorithm Implementation
// Algorithm 5 of 8 - Automatic error correction for repetitive issues

package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"regexp"
	"strings"
	"time"
)

// EmailSenderComponent represents different components of the EMAIL_SENDER_1 system
type EmailSenderComponent int

const (
	RAGEngine EmailSenderComponent = iota
	N8NWorkflow
	NotionAPI
	GmailProcessing
	PowerShellScript
	ConfigFiles
	All
)

func (c EmailSenderComponent) String() string {
	names := []string{"RAGEngine", "N8NWorkflow", "NotionAPI", "GmailProcessing", "PowerShellScript", "ConfigFiles", "All"}
	if int(c) < len(names) {
		return names[c]
	}
	return "Unknown"
}

// EmailSenderFixRule represents a pattern-matching fix rule
type EmailSenderFixRule struct {
	Pattern     *regexp.Regexp
	Replacement string
	Description string
	Safe        bool
	Component   EmailSenderComponent
	Language    string
	Priority    int // 1 = critical, 5 = low priority
}

// EmailSenderAutoFixer manages pattern-based error correction
type EmailSenderAutoFixer struct {
	Rules   []EmailSenderFixRule
	DryRun  bool
	Verbose bool
	Stats   AutoFixStats
}

// AutoFixStats tracks correction statistics
type AutoFixStats struct {
	FilesProcessed   int
	TotalFixes       int
	FixesByRule      map[string]int
	FixesByComponent map[EmailSenderComponent]int
	FixesByLanguage  map[string]int
	CriticalFixes    int
	SafeFixes        int
}

// NewEmailSenderAutoFixer creates a new auto-fixer instance
func NewEmailSenderAutoFixer(dryRun, verbose bool) *EmailSenderAutoFixer {
	return &EmailSenderAutoFixer{
		Rules:   initializeEmailSenderFixRules(),
		DryRun:  dryRun,
		Verbose: verbose,
		Stats: AutoFixStats{
			FixesByRule:      make(map[string]int),
			FixesByComponent: make(map[EmailSenderComponent]int),
			FixesByLanguage:  make(map[string]int),
		},
	}
}

// initializeEmailSenderFixRules defines all pattern-matching rules for EMAIL_SENDER_1
func initializeEmailSenderFixRules() []EmailSenderFixRule {
	return []EmailSenderFixRule{
		// RAG Engine - Go fixes (Priority 1-2)
		{
			Pattern:     regexp.MustCompile(`(\w+) declared and not used`),
			Replacement: "_ = $1 // EMAIL_SENDER_1 auto-fixed: unused variable",
			Description: "Fix unused variables in RAG Engine Go code",
			Safe:        true,
			Component:   RAGEngine,
			Language:    "go",
			Priority:    2,
		},
		{
			Pattern:     regexp.MustCompile(`missing import: "(.+)"`),
			Replacement: `import "$1" // EMAIL_SENDER_1 auto-added missing import`,
			Description: "Add missing imports for RAG Engine",
			Safe:        true,
			Component:   RAGEngine,
			Language:    "go",
			Priority:    1,
		},
		{
			Pattern:     regexp.MustCompile(`undefined: qdrant\.(\w+)`),
			Replacement: "qdrant.$1 // EMAIL_SENDER_1 Qdrant reference (needs manual review)",
			Description: "Mark undefined Qdrant references for manual review",
			Safe:        false,
			Component:   RAGEngine,
			Language:    "go",
			Priority:    1,
		},
		{
			Pattern:     regexp.MustCompile(`log\.Print\(([^)]+)\)`),
			Replacement: `log.Printf("EMAIL_SENDER_1: %v", $1)`,
			Description: "Standardize RAG Engine logging format",
			Safe:        true,
			Component:   RAGEngine,
			Language:    "go",
			Priority:    3,
		},

		// n8n Workflows - JSON fixes (Priority 1-2)
		{
			Pattern:     regexp.MustCompile(`"id":\s*""`),
			Replacement: `"id": "` + generateRandomNodeId() + `"`,
			Description: "Fix empty node IDs in n8n workflows",
			Safe:        true,
			Component:   N8NWorkflow,
			Language:    "json",
			Priority:    1,
		},
		{
			Pattern:     regexp.MustCompile(`"connections":\s*{}`),
			Replacement: `"connections": {"main": []}`,
			Description: "Fix empty connections in EMAIL_SENDER_1 workflows",
			Safe:        true,
			Component:   N8NWorkflow,
			Language:    "json",
			Priority:    1,
		},
		{
			Pattern:     regexp.MustCompile(`"parameters":\s*{}`),
			Replacement: `"parameters": {"email_sender_context": true}`,
			Description: "Add EMAIL_SENDER_1 context to n8n node parameters",
			Safe:        true,
			Component:   N8NWorkflow,
			Language:    "json",
			Priority:    2,
		},
		{
			Pattern:     regexp.MustCompile(`"executeOnce":\s*true`),
			Replacement: `"executeOnce": false`,
			Description: "Fix executeOnce setting for EMAIL_SENDER_1 workflows",
			Safe:        true,
			Component:   N8NWorkflow,
			Language:    "json",
			Priority:    2,
		},

		// PowerShell Scripts - PowerShell fixes (Priority 1-3)
		{
			Pattern:     regexp.MustCompile(`\$(\w+)\s*=\s*\$null;\s*\$\1\s*=`),
			Replacement: `$1 = `,
			Description: "Remove redundant null initialization in PowerShell",
			Safe:        true,
			Component:   PowerShellScript,
			Language:    "powershell",
			Priority:    3,
		},
		{
			Pattern:     regexp.MustCompile(`Write-Host\s+"(.+)"\s+-ForegroundColor\s+(\w+)`),
			Replacement: `Write-Host "$1" -ForegroundColor $2 # EMAIL_SENDER_1 standardized`,
			Description: "Standardize Write-Host formatting",
			Safe:        true,
			Component:   PowerShellScript,
			Language:    "powershell",
			Priority:    3,
		},
		{
			Pattern:     regexp.MustCompile(`Invoke-RestMethod\s+-Uri\s+"([^"]+)"\s+-Method\s+GET\s*$`),
			Replacement: `Invoke-RestMethod -Uri "$1" -Method GET -TimeoutSec 30 # EMAIL_SENDER_1 timeout added`,
			Description: "Add timeout to Invoke-RestMethod calls",
			Safe:        true,
			Component:   PowerShellScript,
			Language:    "powershell",
			Priority:    2,
		},
		{
			Pattern:     regexp.MustCompile(`catch\s*{\s*}\s*$`),
			Replacement: `catch { Write-Error "EMAIL_SENDER_1 error: $_"; throw }`,
			Description: "Fix empty catch blocks in PowerShell",
			Safe:        true,
			Component:   PowerShellScript,
			Language:    "powershell",
			Priority:    1,
		},

		// Notion API - JSON/Go fixes (Priority 1-2)
		{
			Pattern:     regexp.MustCompile(`"notion_api_key":\s*""`),
			Replacement: `"notion_api_key": "${NOTION_API_KEY}" // EMAIL_SENDER_1 env var`,
			Description: "Fix empty Notion API key with environment variable",
			Safe:        true,
			Component:   NotionAPI,
			Language:    "json",
			Priority:    1,
		},
		{
			Pattern:     regexp.MustCompile(`PageSize:\s*0`),
			Replacement: `PageSize: 100 // EMAIL_SENDER_1 default page size`,
			Description: "Fix zero page size in Notion queries",
			Safe:        true,
			Component:   NotionAPI,
			Language:    "go",
			Priority:    2,
		},

		// Gmail Processing - Go/JSON fixes (Priority 1-2)
		{
			Pattern:     regexp.MustCompile(`"credentials_path":\s*""`),
			Replacement: `"credentials_path": "./configs/gmail/credentials.json" // EMAIL_SENDER_1 default`,
			Description: "Fix empty Gmail credentials path",
			Safe:        true,
			Component:   GmailProcessing,
			Language:    "json",
			Priority:    1,
		},
		{
			Pattern:     regexp.MustCompile(`MaxResults:\s*0`),
			Replacement: `MaxResults: 50 // EMAIL_SENDER_1 default batch size`,
			Description: "Fix zero MaxResults in Gmail queries",
			Safe:        true,
			Component:   GmailProcessing,
			Language:    "go",
			Priority:    2,
		},

		// Configuration Files - YAML/JSON fixes (Priority 1-3)
		{
			Pattern:     regexp.MustCompile(`(\s+)version:\s*"?3"?`),
			Replacement: `$1version: "3.8" # EMAIL_SENDER_1 docker-compose version`,
			Description: "Fix docker-compose version specification",
			Safe:        true,
			Component:   ConfigFiles,
			Language:    "yaml",
			Priority:    2,
		},
		{
			Pattern:     regexp.MustCompile(`(\s+)ports:\s*\n\s+-\s+"(\d+)"`),
			Replacement: `$1ports:\n$1  - "$2:$2" # EMAIL_SENDER_1 port mapping`,
			Description: "Fix incomplete port mapping format",
			Safe:        true,
			Component:   ConfigFiles,
			Language:    "yaml",
			Priority:    1,
		},
		{
			Pattern:     regexp.MustCompile(`"timeout":\s*0`),
			Replacement: `"timeout": 30000`,
			Description: "Fix zero timeout values in config",
			Safe:        true,
			Component:   ConfigFiles,
			Language:    "json",
			Priority:    2,
		},
		{
			Pattern:     regexp.MustCompile(`"retries":\s*0`),
			Replacement: `"retries": 3`,
			Description: "Fix zero retry count in config",
			Safe:        true,
			Component:   ConfigFiles,
			Language:    "json",
			Priority:    2,
		},
	}
}

// generateRandomNodeId generates a random ID for n8n nodes
func generateRandomNodeId() string {
	return fmt.Sprintf("email-sender-node-%d", time.Now().UnixNano()%100000)
}

// determineLanguage determines the programming language from file extension
func determineLanguage(filename string) string {
	switch {
	case strings.HasSuffix(filename, ".go"):
		return "go"
	case strings.HasSuffix(filename, ".ps1"):
		return "powershell"
	case strings.HasSuffix(filename, ".json"):
		return "json"
	case strings.HasSuffix(filename, ".yml") || strings.HasSuffix(filename, ".yaml"):
		return "yaml"
	case strings.HasSuffix(filename, ".md"):
		return "markdown"
	default:
		return "unknown"
	}
}

// AutoFixFile applies pattern-matching fixes to a specific file
func (fixer *EmailSenderAutoFixer) AutoFixFile(filename string, component EmailSenderComponent) (int, error) {
	if fixer.Verbose {
		fmt.Printf("📝 Processing: %s (component: %s)\n", filename, component.String())
	}

	content, err := ioutil.ReadFile(filename)
	if err != nil {
		return 0, fmt.Errorf("failed to read file %s: %w", filename, err)
	}

	language := determineLanguage(filename)
	originalContent := string(content)
	newContent := originalContent
	fixCount := 0

	// Apply matching rules
	for _, rule := range fixer.Rules {
		// Filter rules by component and language
		if (rule.Component != component && component != All && rule.Component != All) ||
			(rule.Language != language && rule.Language != "all") {
			continue
		}

		// Apply only safe rules in production
		if !rule.Safe && !fixer.DryRun {
			if fixer.Verbose {
				fmt.Printf("  ⚠️ Skipping unsafe rule: %s\n", rule.Description)
			}
			continue
		}

		matches := rule.Pattern.FindAllStringSubmatch(newContent, -1)
		matchIndices := rule.Pattern.FindAllStringSubmatchIndex(newContent, -1)

		for i := len(matches) - 1; i >= 0; i-- { // Process from end to avoid index shift
			match := matches[i]
			indices := matchIndices[i]

			if len(match) > 0 {
				oldText := match[0]
				newText := rule.Pattern.ReplaceAllString(oldText, rule.Replacement)

				// Apply the replacement
				start := indices[0]
				end := indices[1]
				newContent = newContent[:start] + newText + newContent[end:]

				fixCount++
				fixer.Stats.TotalFixes++
				fixer.Stats.FixesByRule[rule.Description]++
				fixer.Stats.FixesByComponent[component]++
				fixer.Stats.FixesByLanguage[language]++

				if rule.Priority <= 2 {
					fixer.Stats.CriticalFixes++
				}
				if rule.Safe {
					fixer.Stats.SafeFixes++
				}

				if fixer.Verbose {
					fmt.Printf("  🔧 Applied: %s\n", rule.Description)
					fmt.Printf("    Old: %s\n", strings.TrimSpace(oldText))
					fmt.Printf("    New: %s\n", strings.TrimSpace(newText))
				}
			}
		}
	}

	// Write changes if not in dry-run mode
	if fixCount > 0 && !fixer.DryRun {
		err = ioutil.WriteFile(filename, []byte(newContent), 0644)
		if err != nil {
			return 0, fmt.Errorf("failed to write fixed file %s: %w", filename, err)
		}
	}

	fixer.Stats.FilesProcessed++
	return fixCount, nil
}

// GenerateReport creates a comprehensive fix report
func (fixer *EmailSenderAutoFixer) GenerateReport() {
	fmt.Printf("\n📊 EMAIL_SENDER_1 AUTO-FIX REPORT\n")
	fmt.Printf("================================\n")
	fmt.Printf("Files processed: %d\n", fixer.Stats.FilesProcessed)
	fmt.Printf("Total fixes applied: %d\n", fixer.Stats.TotalFixes)
	fmt.Printf("Critical fixes: %d\n", fixer.Stats.CriticalFixes)
	fmt.Printf("Safe fixes: %d\n", fixer.Stats.SafeFixes)

	if len(fixer.Stats.FixesByComponent) > 0 {
		fmt.Printf("\n🔧 FIXES BY COMPONENT:\n")
		for component, count := range fixer.Stats.FixesByComponent {
			fmt.Printf("  %s: %d fixes\n", component.String(), count)
		}
	}

	if len(fixer.Stats.FixesByLanguage) > 0 {
		fmt.Printf("\n💻 FIXES BY LANGUAGE:\n")
		for language, count := range fixer.Stats.FixesByLanguage {
			fmt.Printf("  %s: %d fixes\n", language, count)
		}
	}

	if len(fixer.Stats.FixesByRule) > 0 {
		fmt.Printf("\n📋 TOP APPLIED RULES:\n")
		// Sort by count and show top 10
		type ruleCount struct {
			rule  string
			count int
		}
		var rules []ruleCount
		for rule, count := range fixer.Stats.FixesByRule {
			rules = append(rules, ruleCount{rule, count})
		}

		// Simple bubble sort for demonstration
		for i := 0; i < len(rules)-1; i++ {
			for j := 0; j < len(rules)-i-1; j++ {
				if rules[j].count < rules[j+1].count {
					rules[j], rules[j+1] = rules[j+1], rules[j]
				}
			}
		}

		maxDisplay := 10
		if len(rules) < maxDisplay {
			maxDisplay = len(rules)
		}

		for i := 0; i < maxDisplay; i++ {
			fmt.Printf("  %d. %s (%d times)\n", i+1, rules[i].rule, rules[i].count)
		}
	}
}

// main function for CLI usage
func main() {
	var filename string
	var componentStr string
	var dryRun bool
	var verbose bool

	// Simple argument parsing
	args := os.Args[1:]
	for i, arg := range args {
		switch arg {
		case "-file":
			if i+1 < len(args) {
				filename = args[i+1]
			}
		case "-component":
			if i+1 < len(args) {
				componentStr = args[i+1]
			}
		case "-dry-run":
			dryRun = true
		case "-verbose":
			verbose = true
		}
	}

	if filename == "" {
		fmt.Println("Usage: email_sender_auto_fixer -file <path> [-component <name>] [-dry-run] [-verbose]")
		fmt.Println("Components: RAGEngine, N8NWorkflow, NotionAPI, GmailProcessing, PowerShellScript, ConfigFiles, All")
		os.Exit(1)
	}

	// Parse component
	component := All
	switch strings.ToLower(componentStr) {
	case "ragengine":
		component = RAGEngine
	case "n8nworkflow":
		component = N8NWorkflow
	case "notionapi":
		component = NotionAPI
	case "gmailprocessing":
		component = GmailProcessing
	case "powershellscript":
		component = PowerShellScript
	case "configfiles":
		component = ConfigFiles
	case "all", "":
		component = All
	}

	// Create auto-fixer
	fixer := NewEmailSenderAutoFixer(dryRun, verbose)

	// Process file
	fmt.Printf("🤖 EMAIL_SENDER_1 Auto-Fixer (Component: %s, DryRun: %t)\n", component.String(), dryRun)

	fixCount, err := fixer.AutoFixFile(filename, component)
	if err != nil {
		log.Fatalf("Error processing file: %v", err)
	}

	fmt.Printf("✅ Applied %d fixes to %s\n", fixCount, filename)

	if verbose {
		fixer.GenerateReport()
	}

	// Return fix count for PowerShell integration
	fmt.Printf("%d", fixCount)
}
