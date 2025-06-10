// development/hooks/commit-interceptor/analyzer.go
package main

import (
	"fmt"
	"path/filepath"
	"regexp"
	"strings"
)

// CommitAnalysis represents the analysis result of a commit
type CommitAnalysis struct {
	CommitData      *CommitData `json:"commit_data"`
	ChangeType      string      `json:"change_type"` // feature, fix, refactor, docs, etc.
	Impact          string      `json:"impact"`      // low, medium, high
	FileTypes       []string    `json:"file_types"`  // go, js, md, etc.
	Confidence      float64     `json:"confidence"`  // 0.0 to 1.0
	SuggestedBranch string      `json:"suggested_branch"`
	Keywords        []string    `json:"keywords"`
	Priority        string      `json:"priority"` // low, medium, high, critical
}

// CommitAnalyzer analyzes commits to determine their type and routing
type CommitAnalyzer struct {
	config *Config
}

// NewCommitAnalyzer creates a new commit analyzer
func NewCommitAnalyzer(config *Config) *CommitAnalyzer {
	return &CommitAnalyzer{
		config: config,
	}
}

// AnalyzeCommit performs comprehensive analysis of a commit
func (ca *CommitAnalyzer) AnalyzeCommit(data *CommitData) (*CommitAnalysis, error) {
	if err := ValidateCommitData(data); err != nil {
		return nil, fmt.Errorf("invalid commit data: %w", err)
	}

	analysis := &CommitAnalysis{
		CommitData: data,
	}

	// Analyze commit message
	ca.analyzeMessage(analysis)

	// Analyze file changes
	ca.analyzeFiles(analysis)

	// Determine impact level
	ca.analyzeImpact(analysis)

	// Calculate confidence score
	ca.calculateConfidence(analysis)

	// Suggest branch
	ca.suggestBranch(analysis)

	// Set priority
	ca.setPriority(analysis)

	return analysis, nil
}

// analyzeMessage analyzes the commit message to determine change type
func (ca *CommitAnalyzer) analyzeMessage(analysis *CommitAnalysis) {
	message := strings.ToLower(analysis.CommitData.Message)

	// Define patterns for different change types
	patterns := map[string][]string{
		"feature": {
			`^feat(\(.+\))?:`, `^feature(\(.+\))?:`, `^add(\(.+\))?:`,
			`implement`, `new feature`, `add feature`,
		},
		"fix": {
			`^fix(\(.+\))?:`, `^bug(\(.+\))?:`, `^hotfix(\(.+\))?:`,
			`fix bug`, `resolve`, `patch`, `correction`,
		},
		"refactor": {
			`^refactor(\(.+\))?:`, `^clean(\(.+\))?:`, `^optimize(\(.+\))?:`,
			`refactoring`, `cleanup`, `optimization`, `restructure`,
		},
		"docs": {
			`^docs(\(.+\))?:`, `^doc(\(.+\))?:`, `^documentation(\(.+\))?:`,
			`update readme`, `add documentation`, `fix typo`,
		},
		"style": {
			`^style(\(.+\))?:`, `^format(\(.+\))?:`,
			`formatting`, `code style`, `linting`,
		},
		"test": {
			`^test(\(.+\))?:`, `^tests(\(.+\))?:`,
			`add test`, `fix test`, `update test`,
		},
		"chore": {
			`^chore(\(.+\))?:`, `^maintenance(\(.+\))?:`,
			`update dependencies`, `bump version`, `config`,
		},
	}

	var keywords []string
	var matchedType string
	highestScore := 0
	var bestMatchedScore int

	for changeType, typePatterns := range patterns {
		score := 0
		currentKeywords := []string{}

		for _, pattern := range typePatterns {
			matched, _ := regexp.MatchString(pattern, message)
			if matched {
				score += 10 // Higher weight for exact pattern matches
				currentKeywords = append(currentKeywords, pattern)
				break // Stop at first exact match for this type
			} else if strings.Contains(message, strings.Trim(pattern, `^$(\(.+\))?:`)) {
				score += 3 // Lower weight for substring matches
				currentKeywords = append(currentKeywords, strings.Trim(pattern, `^$(\(.+\))?:`))
			}
		}

		if score > highestScore {
			highestScore = score
			bestMatchedScore = score
			matchedType = changeType
			keywords = currentKeywords
		}
	}

	if matchedType == "" {
		matchedType = "chore"     // Default type
		analysis.Confidence = 0.8 // Default confidence for chore
	} else {
		// Calculate confidence based on the best score
		if bestMatchedScore >= 10 {
			// Perfect match (exact pattern match)
			analysis.Confidence = 0.95
		} else if bestMatchedScore >= 6 {
			// Good match (multiple substring matches)
			analysis.Confidence = 0.85
		} else {
			// Partial match
			analysis.Confidence = 0.8
		}
	}

	analysis.ChangeType = matchedType
	analysis.Keywords = keywords
}

// analyzeFiles analyzes the changed files to get additional context
func (ca *CommitAnalyzer) analyzeFiles(analysis *CommitAnalysis) {
	files := analysis.CommitData.Files
	fileTypes := make(map[string]int)

	for _, file := range files {
		ext := strings.ToLower(filepath.Ext(file))
		if ext == "" {
			ext = "no-ext"
		}
		fileTypes[ext]++
	}

	// Convert map to slice of unique file types
	var types []string
	for fileType := range fileTypes {
		types = append(types, fileType)
	}
	analysis.FileTypes = types

	// Adjust change type based on files
	ca.adjustChangeTypeByFiles(analysis, fileTypes)
}

// adjustChangeTypeByFiles adjusts change type based on file analysis
func (ca *CommitAnalyzer) adjustChangeTypeByFiles(analysis *CommitAnalysis, fileTypes map[string]int) {
	// If only documentation files changed, it's likely a docs change
	if len(fileTypes) == 1 || (len(fileTypes) == 2 && fileTypes[""] > 0) {
		for ext := range fileTypes {
			if ext == ".md" || ext == ".txt" || ext == ".rst" {
				if analysis.ChangeType == "chore" {
					analysis.ChangeType = "docs"
				}
			}
		}
	}

	// If test files are predominant
	testExtensions := []string{".test.go", ".spec.js", ".test.js", "_test.go"}
	testFileCount := 0
	totalFiles := len(analysis.CommitData.Files)

	for _, file := range analysis.CommitData.Files {
		for _, testExt := range testExtensions {
			if strings.Contains(file, testExt) {
				testFileCount++
				break
			}
		}
	}

	if float64(testFileCount)/float64(totalFiles) > 0.7 {
		if analysis.ChangeType == "chore" {
			analysis.ChangeType = "test"
		}
	}
}

// analyzeImpact determines the impact level of the changes
func (ca *CommitAnalyzer) analyzeImpact(analysis *CommitAnalysis) {
	fileCount := len(analysis.CommitData.Files)

	// Base impact on number of files
	impact := "low"
	if fileCount >= 6 { // Lowered threshold for high impact
		impact = "high"
	} else if fileCount > 2 {
		impact = "medium"
	}

	// Adjust based on change type
	switch analysis.ChangeType {
	case "fix", "hotfix":
		if strings.Contains(strings.ToLower(analysis.CommitData.Message), "critical") ||
			strings.Contains(strings.ToLower(analysis.CommitData.Message), "urgent") {
			impact = "high"
		}
	case "feature":
		if fileCount >= 4 { // Lowered threshold
			impact = "high"
		} else if fileCount > 1 {
			impact = "medium"
		}
	case "refactor":
		if fileCount >= 5 { // Lowered threshold
			impact = "high"
		}
	case "docs", "style":
		// Keep as determined by file count, don't force to low
	}

	// Check for critical files - impact depends on change type
	hasCriticalFile := false
	for _, file := range analysis.CommitData.Files {
		if ca.isCriticalFile(file) {
			hasCriticalFile = true
			break
		}
	}

	if hasCriticalFile {
		// For critical files, impact depends on change type
		switch analysis.ChangeType {
		case "feature":
			// Features on critical files: medium to high escalation
			if impact == "low" {
				impact = "medium"
			}
			// medium stays medium for features unless other factors
		case "fix", "hotfix":
			// Fixes on critical files are always high impact
			impact = "high"
		case "refactor":
			// Refactors on critical files are always high impact
			impact = "high"
		default:
			// Other types: at least medium
			if impact == "low" {
				impact = "medium"
			}
		}
	}

	analysis.Impact = impact
}

// isCriticalFile checks if a file is considered critical
func (ca *CommitAnalyzer) isCriticalFile(filename string) bool {
	criticalPatterns := []string{
		"main.go", "main.js", "index.js", "app.js",
		"Dockerfile", "docker-compose.yml",
		"go.mod", "package.json", "requirements.txt",
		"config.yml", "config.yaml", "config.json",
		".github/workflows/", "Makefile",
	}

	filename = strings.ToLower(filename)
	for _, pattern := range criticalPatterns {
		if strings.Contains(filename, strings.ToLower(pattern)) {
			return true
		}
	}
	return false
}

// calculateConfidence calculates confidence score for the analysis
func (ca *CommitAnalyzer) calculateConfidence(analysis *CommitAnalysis) {
	confidence := 0.5 // Base confidence

	// Increase confidence for clear commit message patterns
	if len(analysis.Keywords) > 0 {
		confidence += 0.3
	}

	// Increase confidence for consistent file types with change type
	if ca.filesMatchChangeType(analysis) {
		confidence += 0.2
	}

	// Decrease confidence for very short messages
	if len(analysis.CommitData.Message) < 10 {
		confidence -= 0.2
	}

	// Ensure confidence is between 0 and 1
	if confidence > 1.0 {
		confidence = 1.0
	} else if confidence < 0.0 {
		confidence = 0.0
	}

	analysis.Confidence = confidence
}

// filesMatchChangeType checks if file types match the determined change type
func (ca *CommitAnalyzer) filesMatchChangeType(analysis *CommitAnalysis) bool {
	switch analysis.ChangeType {
	case "docs":
		for _, ext := range analysis.FileTypes {
			if ext == ".md" || ext == ".txt" || ext == ".rst" {
				return true
			}
		}
	case "test":
		for _, file := range analysis.CommitData.Files {
			if strings.Contains(file, "test") || strings.Contains(file, "spec") {
				return true
			}
		}
	}
	return false
}

// suggestBranch suggests appropriate branch based on analysis
func (ca *CommitAnalyzer) suggestBranch(analysis *CommitAnalysis) {
	switch analysis.ChangeType {
	case "feature":
		analysis.SuggestedBranch = fmt.Sprintf("feature/%s", ca.generateBranchSuffix(analysis))
	case "fix":
		if analysis.Priority == "critical" || analysis.Impact == "high" {
			analysis.SuggestedBranch = fmt.Sprintf("hotfix/%s", ca.generateBranchSuffix(analysis))
		} else {
			analysis.SuggestedBranch = fmt.Sprintf("bugfix/%s", ca.generateBranchSuffix(analysis))
		}
	case "refactor":
		analysis.SuggestedBranch = fmt.Sprintf("refactor/%s", ca.generateBranchSuffix(analysis))
	case "docs":
		analysis.SuggestedBranch = "develop"
	case "style", "chore":
		analysis.SuggestedBranch = "develop"
	default:
		analysis.SuggestedBranch = "develop"
	}
}

// generateBranchSuffix generates a branch name suffix based on commit message
func (ca *CommitAnalyzer) generateBranchSuffix(analysis *CommitAnalysis) string {
	message := analysis.CommitData.Message

	// Remove conventional commit prefixes
	re := regexp.MustCompile(`^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?:\s*`)
	message = re.ReplaceAllString(message, "")

	// Clean and truncate message
	message = strings.ToLower(message)
	message = regexp.MustCompile(`[^a-z0-9\s]`).ReplaceAllString(message, "")
	message = regexp.MustCompile(`\s+`).ReplaceAllString(message, "-")
	message = strings.Trim(message, "-")

	// Ensure we have a meaningful message
	if message == "" || len(message) < 3 {
		message = "commit-change"
	}

	if len(message) > 30 {
		message = message[:30]
	}

	// Add timestamp to ensure uniqueness
	timestamp := analysis.CommitData.Timestamp.Format("20060102-150405")

	return fmt.Sprintf("%s-%s", message, timestamp)
}

// setPriority sets the priority level for the commit
func (ca *CommitAnalyzer) setPriority(analysis *CommitAnalysis) {
	message := strings.ToLower(analysis.CommitData.Message)

	// Check for critical keywords
	criticalKeywords := []string{"critical", "urgent", "emergency", "hotfix", "security"}
	for _, keyword := range criticalKeywords {
		if strings.Contains(message, keyword) {
			analysis.Priority = "critical"
			return
		}
	}

	// Set priority based on change type and impact
	switch analysis.ChangeType {
	case "fix", "hotfix":
		if analysis.Impact == "high" {
			analysis.Priority = "high"
		} else {
			analysis.Priority = "medium"
		}
	case "feature":
		if analysis.Impact == "high" {
			analysis.Priority = "medium"
		} else {
			analysis.Priority = "low"
		}
	case "refactor":
		analysis.Priority = "medium"
	default:
		analysis.Priority = "low"
	}
}
