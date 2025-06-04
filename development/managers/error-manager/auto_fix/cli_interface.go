package auto_fix

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
	"encoding/json"
	"io/ioutil"
	"path/filepath"
)

// CLIInterface provides a command-line interface for reviewing and applying fixes
type CLIInterface struct {
	suggestionEngine *SuggestionEngine
	validationSystem *ValidationSystem
	config           CLIConfig
	history          []CLIAction
}

// CLIConfig contains configuration for the CLI
type CLIConfig struct {
	AutoApplyThreshold float64       `json:"auto_apply_threshold"`
	InteractiveMode    bool          `json:"interactive_mode"`
	ShowDiffs          bool          `json:"show_diffs"`
	BackupFiles        bool          `json:"backup_files"`
	LogActions         bool          `json:"log_actions"`
	OutputFormat       string        `json:"output_format"` // "text", "json", "colored"
	MaxSuggestions     int           `json:"max_suggestions"`
	Timeout            time.Duration `json:"timeout"`
}

// CLIAction represents an action taken through the CLI
type CLIAction struct {
	Timestamp   time.Time       `json:"timestamp"`
	Action      string          `json:"action"` // "applied", "rejected", "skipped"
	Suggestion  *FixSuggestion  `json:"suggestion"`
	Validation  *ValidationResult `json:"validation,omitempty"`
	UserInput   string          `json:"user_input,omitempty"`
	FilePath    string          `json:"file_path"`
}

// ReviewSession represents a fix review session
type ReviewSession struct {
	ID          string          `json:"id"`
	StartTime   time.Time       `json:"start_time"`
	EndTime     time.Time       `json:"end_time"`
	FilesAnalyzed int           `json:"files_analyzed"`
	SuggestionsTotal int        `json:"suggestions_total"`
	SuggestionsApplied int      `json:"suggestions_applied"`
	SuggestionsRejected int     `json:"suggestions_rejected"`
	Actions     []CLIAction     `json:"actions"`
}

// DiffInfo contains information about a code diff
type DiffInfo struct {
	OriginalLines []string `json:"original_lines"`
	ModifiedLines []string `json:"modified_lines"`
	LineNumbers   []int    `json:"line_numbers"`
	Context       int      `json:"context"`
}

// NewCLIInterface creates a new CLI interface
func NewCLIInterface(engine *SuggestionEngine, validation *ValidationSystem, config CLIConfig) *CLIInterface {
	if config.AutoApplyThreshold == 0 {
		config.AutoApplyThreshold = 0.9
	}
	if config.MaxSuggestions == 0 {
		config.MaxSuggestions = 50
	}
	if config.Timeout == 0 {
		config.Timeout = 30 * time.Minute
	}
	if config.OutputFormat == "" {
		config.OutputFormat = "colored"
	}

	return &CLIInterface{
		suggestionEngine: engine,
		validationSystem: validation,
		config:           config,
		history:          make([]CLIAction, 0),
	}
}

// StartReviewSession starts an interactive review session
func (cli *CLIInterface) StartReviewSession(ctx context.Context, projectPath string) (*ReviewSession, error) {
	session := &ReviewSession{
		ID:        fmt.Sprintf("session_%d", time.Now().Unix()),
		StartTime: time.Now(),
		Actions:   make([]CLIAction, 0),
	}

	cli.printHeader("AutoFix Review Session")
	fmt.Printf("Project: %s\n", projectPath)
	fmt.Printf("Session ID: %s\n", session.ID)
	fmt.Println()

	// Analyze project and get suggestions
	suggestions, err := cli.analyzeProject(ctx, projectPath)
	if err != nil {
		return session, fmt.Errorf("failed to analyze project: %w", err)
	}

	session.SuggestionsTotal = len(suggestions)
	cli.printf("Found %d potential fixes\n", len(suggestions))

	if len(suggestions) == 0 {
		cli.printSuccess("No fixes needed - code looks good!")
		session.EndTime = time.Now()
		return session, nil
	}

	// Filter and prioritize suggestions
	suggestions = cli.filterSuggestions(suggestions)
	
	// Process each suggestion
	for i, suggestion := range suggestions {
		if cli.config.MaxSuggestions > 0 && i >= cli.config.MaxSuggestions {
			break
		}

		action, err := cli.reviewSuggestion(suggestion, i+1, len(suggestions))
		if err != nil {
			cli.printError("Error processing suggestion: %v", err)
			continue
		}

		session.Actions = append(session.Actions, action)
		
		switch action.Action {
		case "applied":
			session.SuggestionsApplied++
		case "rejected":
			session.SuggestionsRejected++
		}

		// Check if user wants to quit
		if action.UserInput == "quit" || action.UserInput == "q" {
			break
		}
	}

	session.EndTime = time.Now()
	cli.printSessionSummary(session)

	return session, nil
}

// analyzeProject analyzes a project and returns suggestions
func (cli *CLIInterface) analyzeProject(ctx context.Context, projectPath string) ([]*FixSuggestion, error) {
	cli.printInfo("Analyzing project...")

	// Find Go files
	goFiles, err := cli.findGoFiles(projectPath)
	if err != nil {
		return nil, fmt.Errorf("failed to find Go files: %w", err)
	}

	cli.printf("Found %d Go files\n", len(goFiles))

	var allSuggestions []*FixSuggestion
	
	for _, filePath := range goFiles {
		_, err := ioutil.ReadFile(filePath)
		if err != nil {
			cli.printWarning("Failed to read %s: %v", filePath, err)
			continue
		}

		suggestions, err := cli.suggestionEngine.AnalyzeCode(ctx, filePath)
		if err != nil {
			fmt.Printf("Error analyzing file %s: %v\n", filePath, err)
			continue
		}
		allSuggestions = append(allSuggestions, suggestions...)
	}

	return allSuggestions, nil
}

// reviewSuggestion handles the review of a single suggestion
func (cli *CLIInterface) reviewSuggestion(suggestion *FixSuggestion, current, total int) (CLIAction, error) {
	action := CLIAction{
		Timestamp:  time.Now(),
		Suggestion: suggestion,
		FilePath:   suggestion.FilePath,
	}

	cli.printSeparator()
	cli.printf("Fix %d/%d\n", current, total)
	cli.printSuggestionHeader(suggestion)

	// Validate the fix
	originalCode, err := cli.readFile(suggestion.FilePath)
	if err != nil {
		action.Action = "skipped"
		return action, fmt.Errorf("failed to read file: %w", err)
	}

	validation, err := cli.validationSystem.ValidateProposedFix(suggestion, originalCode)
	if err != nil {
		cli.printError("Validation failed: %v", err)
		action.Action = "skipped"
		return action, err
	}

	action.Validation = validation
	cli.printValidationResults(validation)

	// Show diff if requested
	if cli.config.ShowDiffs {
		if err := cli.showDiff(suggestion, originalCode); err != nil {
			cli.printWarning("Failed to generate diff: %v", err)
		}
	}

	// Auto-apply if confidence is high enough
	if validation.ConfidenceScore >= cli.config.AutoApplyThreshold && validation.SafetyLevel == SafetyLevelHigh {
		cli.printSuccess("Auto-applying fix (confidence: %.2f)", validation.ConfidenceScore)
		if err := cli.applyFix(suggestion, originalCode); err != nil {
			cli.printError("Failed to apply fix: %v", err)
			action.Action = "skipped"
		} else {
			action.Action = "applied"
		}
		return action, nil
	}

	// Interactive mode
	if cli.config.InteractiveMode {
		userChoice, err := cli.promptUser(suggestion, validation)
		if err != nil {
			action.Action = "skipped"
			return action, err
		}

		action.UserInput = userChoice

		switch userChoice {
		case "apply", "a", "yes", "y":
			if err := cli.applyFix(suggestion, originalCode); err != nil {
				cli.printError("Failed to apply fix: %v", err)
				action.Action = "skipped"
			} else {
				cli.printSuccess("Fix applied")
				action.Action = "applied"
			}
		case "reject", "r", "no", "n":
			cli.printInfo("Fix rejected")
			action.Action = "rejected"
		case "skip", "s":
			cli.printInfo("Fix skipped")
			action.Action = "skipped"
		case "quit", "q":
			cli.printInfo("Exiting review session")
			action.Action = "skipped"
		default:
			cli.printWarning("Unknown choice, skipping")
			action.Action = "skipped"
		}
	} else {
		// Non-interactive mode - only apply safe fixes
		if validation.SafetyLevel >= SafetyLevelMedium && validation.ConfidenceScore >= 0.7 {
			if err := cli.applyFix(suggestion, originalCode); err != nil {
				cli.printError("Failed to apply fix: %v", err)
				action.Action = "skipped"
			} else {
				action.Action = "applied"
			}
		} else {
			action.Action = "skipped"
		}
	}

	return action, nil
}

// promptUser prompts the user for input
func (cli *CLIInterface) promptUser(suggestion *FixSuggestion, validation *ValidationResult) (string, error) {
	fmt.Println()
	fmt.Println("Options:")
	fmt.Println("  [a]pply   - Apply this fix")
	fmt.Println("  [r]eject  - Reject this fix")
	fmt.Println("  [s]kip    - Skip this fix")
	fmt.Println("  [d]iff    - Show detailed diff")
	fmt.Println("  [i]nfo    - Show more information")
	fmt.Println("  [q]uit    - Exit review session")
	fmt.Print("\nChoice: ")

	reader := bufio.NewReader(os.Stdin)
	input, err := reader.ReadString('\n')
	if err != nil {
		return "", err
	}

	choice := strings.TrimSpace(strings.ToLower(input))

	// Handle special commands
	switch choice {
	case "d", "diff":
		cli.showDetailedDiff(suggestion)
		return cli.promptUser(suggestion, validation) // Re-prompt
	case "i", "info":
		cli.showDetailedInfo(suggestion, validation)
		return cli.promptUser(suggestion, validation) // Re-prompt
	}

	return choice, nil
}

// applyFix applies a fix to the file
func (cli *CLIInterface) applyFix(suggestion *FixSuggestion, originalCode string) error {
	// Create backup if requested
	if cli.config.BackupFiles {
		if err := cli.createBackup(suggestion.FilePath); err != nil {
			cli.printWarning("Failed to create backup: %v", err)
		}
	}

	// Apply the fix
	modifiedCode, err := cli.applySuggestionToCode(originalCode, suggestion)
	if err != nil {
		return fmt.Errorf("failed to apply suggestion: %w", err)
	}

	// Write modified code back to file
	if err := ioutil.WriteFile(suggestion.FilePath, []byte(modifiedCode), 0644); err != nil {
		return fmt.Errorf("failed to write file: %w", err)
	}

	return nil
}

// Helper functions for display

// printHeader prints a section header
func (cli *CLIInterface) printHeader(title string) {
	if cli.config.OutputFormat == "colored" {
		fmt.Printf("\033[1;36m=== %s ===\033[0m\n", title)
	} else {
		fmt.Printf("=== %s ===\n", title)
	}
}

// printSeparator prints a separator line
func (cli *CLIInterface) printSeparator() {
	if cli.config.OutputFormat == "colored" {
		fmt.Println("\033[90m" + strings.Repeat("-", 60) + "\033[0m")
	} else {
		fmt.Println(strings.Repeat("-", 60))
	}
}

// printSuccess prints a success message
func (cli *CLIInterface) printSuccess(format string, args ...interface{}) {
	if cli.config.OutputFormat == "colored" {
		fmt.Printf("\033[32m✓ "+format+"\033[0m\n", args...)
	} else {
		fmt.Printf("✓ "+format+"\n", args...)
	}
}

// printError prints an error message
func (cli *CLIInterface) printError(format string, args ...interface{}) {
	if cli.config.OutputFormat == "colored" {
		fmt.Printf("\033[31m✗ "+format+"\033[0m\n", args...)
	} else {
		fmt.Printf("✗ "+format+"\n", args...)
	}
}

// printWarning prints a warning message
func (cli *CLIInterface) printWarning(format string, args ...interface{}) {
	if cli.config.OutputFormat == "colored" {
		fmt.Printf("\033[33m⚠ "+format+"\033[0m\n", args...)
	} else {
		fmt.Printf("⚠ "+format+"\n", args...)
	}
}

// printInfo prints an info message
func (cli *CLIInterface) printInfo(format string, args ...interface{}) {
	if cli.config.OutputFormat == "colored" {
		fmt.Printf("\033[34mℹ "+format+"\033[0m\n", args...)
	} else {
		fmt.Printf("ℹ "+format+"\n", args...)
	}
}

// printf prints formatted text
func (cli *CLIInterface) printf(format string, args ...interface{}) {
	fmt.Printf(format, args...)
}

// printSuggestionHeader prints details about a suggestion
func (cli *CLIInterface) printSuggestionHeader(suggestion *FixSuggestion) {
	fmt.Printf("File: %s\n", suggestion.FilePath)
	fmt.Printf("Category: %s\n", suggestion.Category)
	fmt.Printf("Description: %s\n", suggestion.Description)
	fmt.Printf("Impact: %s\n", suggestion.Impact)
	fmt.Printf("Confidence: %.2f\n", suggestion.Confidence)
	fmt.Printf("Safety Level: %s\n", suggestion.SafetyLevel)
}

// printValidationResults prints validation results
func (cli *CLIInterface) printValidationResults(validation *ValidationResult) {
	fmt.Println("\nValidation Results:")
	fmt.Printf("  Valid: %t\n", validation.IsValid)
	fmt.Printf("  Confidence: %.2f\n", validation.ConfidenceScore)
	fmt.Printf("  Safety: %s\n", validation.SafetyLevel)
	fmt.Printf("  Compilation: %t\n", validation.CompilationOK)
	fmt.Printf("  Static Check: %t\n", validation.StaticCheckOK)
	fmt.Printf("  Tests: %t\n", validation.TestsPassing)
	
	if len(validation.Errors) > 0 {
		fmt.Println("  Errors:")
		for _, err := range validation.Errors {
			cli.printError("    %s", err)
		}
	}
	
	if len(validation.Warnings) > 0 {
		fmt.Println("  Warnings:")
		for _, warn := range validation.Warnings {
			cli.printWarning("    %s", warn)
		}
	}
}

// showDiff shows a diff for the suggested fix
func (cli *CLIInterface) showDiff(suggestion *FixSuggestion, originalCode string) error {
	modifiedCode, err := cli.applySuggestionToCode(originalCode, suggestion)
	if err != nil {
		return err
	}

	diff := cli.generateDiff(originalCode, modifiedCode)
	fmt.Println("\nDiff:")
	fmt.Println(diff)
	
	return nil
}

// showDetailedDiff shows a detailed diff
func (cli *CLIInterface) showDetailedDiff(suggestion *FixSuggestion) {
	fmt.Println("\nDetailed diff functionality would be implemented here")
	// Implementation would show side-by-side or unified diff
}

// showDetailedInfo shows detailed information about a suggestion
func (cli *CLIInterface) showDetailedInfo(suggestion *FixSuggestion, validation *ValidationResult) {
	fmt.Println("\nDetailed Information:")
	fmt.Printf("Suggestion ID: %s\n", suggestion.ID)
	fmt.Printf("Lines affected: %v\n", suggestion.LineNumbers)
	fmt.Printf("Patterns: %v\n", suggestion.Patterns)
	if len(suggestion.Replacements) > 0 {
		fmt.Printf("Replacements: %v\n", suggestion.Replacements)
	}
	fmt.Printf("Validation duration: %v\n", validation.Duration)
}

// generateDiff generates a simple diff between two code strings
func (cli *CLIInterface) generateDiff(original, modified string) string {
	originalLines := strings.Split(original, "\n")
	modifiedLines := strings.Split(modified, "\n")
	
	var diff strings.Builder
	maxLines := len(originalLines)
	if len(modifiedLines) > maxLines {
		maxLines = len(modifiedLines)
	}
	
	for i := 0; i < maxLines; i++ {
		var origLine, modLine string
		
		if i < len(originalLines) {
			origLine = originalLines[i]
		}
		if i < len(modifiedLines) {
			modLine = modifiedLines[i]
		}
		
		if origLine != modLine {
			if origLine != "" {
				diff.WriteString(fmt.Sprintf("- %s\n", origLine))
			}
			if modLine != "" {
				diff.WriteString(fmt.Sprintf("+ %s\n", modLine))
			}
		}
	}
	
	return diff.String()
}

// printSessionSummary prints a summary of the review session
func (cli *CLIInterface) printSessionSummary(session *ReviewSession) {
	cli.printSeparator()
	cli.printHeader("Session Summary")
	
	duration := session.EndTime.Sub(session.StartTime)
	fmt.Printf("Duration: %v\n", duration.Round(time.Second))
	fmt.Printf("Total suggestions: %d\n", session.SuggestionsTotal)
	fmt.Printf("Applied: %d\n", session.SuggestionsApplied)
	fmt.Printf("Rejected: %d\n", session.SuggestionsRejected)
	fmt.Printf("Skipped: %d\n", session.SuggestionsTotal-session.SuggestionsApplied-session.SuggestionsRejected)
	
	if session.SuggestionsApplied > 0 {
		cli.printSuccess("Successfully applied %d fixes", session.SuggestionsApplied)
	}
}

// Utility functions

// findGoFiles finds all Go files in a project
func (cli *CLIInterface) findGoFiles(projectPath string) ([]string, error) {
	var goFiles []string
	
	err := filepath.Walk(projectPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		
		if strings.HasSuffix(path, ".go") && !strings.Contains(path, "vendor/") {
			goFiles = append(goFiles, path)
		}
		
		return nil
	})
	
	return goFiles, err
}

// readFile reads a file and returns its content
func (cli *CLIInterface) readFile(filePath string) (string, error) {
	content, err := ioutil.ReadFile(filePath)
	if err != nil {
		return "", err
	}
	return string(content), nil
}

// createBackup creates a backup of a file
func (cli *CLIInterface) createBackup(filePath string) error {
	content, err := ioutil.ReadFile(filePath)
	if err != nil {
		return err
	}
	
	backupPath := filePath + ".backup." + strconv.FormatInt(time.Now().Unix(), 10)
	return ioutil.WriteFile(backupPath, content, 0644)
}

// applySuggestionToCode applies a suggestion to code
func (cli *CLIInterface) applySuggestionToCode(code string, suggestion *FixSuggestion) (string, error) {
	// This would delegate to the validation system's apply logic
	return cli.validationSystem.applyFixToCode(code, suggestion)
}

// filterSuggestions filters and prioritizes suggestions
func (cli *CLIInterface) filterSuggestions(suggestions []*FixSuggestion) []*FixSuggestion {
	// Sort by confidence and impact
	// Implementation would include sophisticated filtering logic
	return suggestions
}

// SaveSession saves a review session to disk
func (cli *CLIInterface) SaveSession(session *ReviewSession, path string) error {
	data, err := json.MarshalIndent(session, "", "  ")
	if err != nil {
		return err
	}
	
	return ioutil.WriteFile(path, data, 0644)
}

// LoadSession loads a review session from disk
func (cli *CLIInterface) LoadSession(path string) (*ReviewSession, error) {
	data, err := ioutil.ReadFile(path)
	if err != nil {
		return nil, err
	}
	
	var session ReviewSession
	if err := json.Unmarshal(data, &session); err != nil {
		return nil, err
	}
	
	return &session, nil
}
